#!/usr/bin/env python3
"""
Valida o grafo de governança.

Duas camadas, e elas são diferentes:

  1. SCHEMA      — cada arquivo YAML está bem formado? (jsonschema)
  2. INTEGRIDADE — o grafo faz sentido como grafo?     (este arquivo)

A segunda é a que importa. É ela que transforma "uma pasta de YAML" em
"banco de governança computável": um pull request que quebra uma referência
não é mesclável.

Uso:
    uv run python tools/validar.py data/ schema/grafo.schema.json

Sai com código 1 se qualquer verificação falhar — é isso que faz o CI barrar o merge.
"""
from __future__ import annotations

import datetime as dt
import json
import sys
from collections import defaultdict, deque
from pathlib import Path

import yaml

try:
    from jsonschema import Draft202012Validator
except ImportError:
    Draft202012Validator = None


# ---------------------------------------------------------------- carga

def normalizar(v):
    """YAML 1.1 converte 2026-08-24 sem aspas em datetime.date, e aí o
    jsonschema reclama que não é string. Normalizamos na entrada em vez de
    exigir aspas em toda data — a regra do formato pertence ao carregador,
    não à disciplina de quem escreve o YAML."""
    if isinstance(v, (dt.date, dt.datetime)):
        return v.isoformat()[:10]
    if isinstance(v, dict):
        return {k: normalizar(x) for k, x in v.items()}
    if isinstance(v, list):
        return [normalizar(x) for x in v]
    return v


def carregar(raiz: Path) -> dict[str, dict]:
    """Lê todo YAML sob a raiz e indexa por id. Duplicata de id é erro fatal."""
    nos: dict[str, dict] = {}
    for caminho in sorted(raiz.rglob("*.yaml")):
        doc = normalizar(yaml.safe_load(caminho.read_text(encoding="utf-8")))
        if not isinstance(doc, dict) or "id" not in doc:
            raise SystemExit(f"FATAL {caminho}: sem campo 'id'")
        if doc["id"] in nos:
            raise SystemExit(f"FATAL {caminho}: id duplicado {doc['id']}")
        doc["_arquivo"] = str(caminho)
        nos[doc["id"]] = doc
    return nos


def arestas(nos: dict[str, dict]) -> list[tuple[str, str, str]]:
    """Achata as arestas declaradas nos nós em triplas (origem, rel, destino)."""
    return [
        (nid, a["rel"], a["dst"])
        for nid, no in nos.items()
        for a in (no.get("arestas") or [])
    ]


# ------------------------------------------------------- verificações

def checar_schema(nos, caminho_schema: Path, erros: list[str]) -> None:
    if Draft202012Validator is None:
        erros.append("AVISO: jsonschema não instalado — validação de schema pulada")
        return
    validador = Draft202012Validator(json.loads(caminho_schema.read_text(encoding="utf-8")))
    for nid, no in nos.items():
        limpo = {k: v for k, v in no.items() if not k.startswith("_")}
        for e in sorted(validador.iter_errors(limpo), key=lambda e: e.path):
            local = ".".join(str(p) for p in e.path) or "(raiz)"
            erros.append(f"SCHEMA  {nid} [{local}]: {e.message}")


def checar_referencias(nos, es, erros: list[str]) -> None:
    """Toda aresta precisa apontar para um nó que existe. Aresta órfã é o defeito
    silencioso clássico: o grafo aceita, e a informação some."""
    for src, rel, dst in es:
        if dst not in nos:
            erros.append(f"ÓRFÃ    {src} -[{rel}]-> {dst}  (destino não existe)")


def checar_prefixo(nos, erros: list[str]) -> None:
    """O prefixo do id tem que bater com o kind. Impede meta:T12."""
    for nid, no in nos.items():
        if nid.split(":", 1)[0] != no.get("kind"):
            erros.append(f"PREFIXO {nid}: kind='{no.get('kind')}' não bate com o prefixo do id")


def checar_ciclos(es, rels: set[str], erros: list[str]) -> None:
    """Ciclo em DEPENDE_DE ou BLOQUEIA é bug de governança, não de dado:
    A depende de B que depende de A significa que nada pode começar."""
    adj = defaultdict(list)
    for src, rel, dst in es:
        if rel in rels:
            adj[src].append(dst)

    BRANCO, CINZA, PRETO = 0, 1, 2
    cor = defaultdict(int)

    def visitar(u, caminho):
        cor[u] = CINZA
        for v in adj[u]:
            if cor[v] == CINZA:
                ciclo = caminho[caminho.index(v):] if v in caminho else [v]
                erros.append("CICLO   " + " -> ".join(ciclo + [v]))
            elif cor[v] == BRANCO:
                visitar(v, caminho + [v])
        cor[u] = PRETO

    for u in list(adj):
        if cor[u] == BRANCO:
            visitar(u, [u])


def checar_rastreabilidade(nos, es, erros: list[str]) -> None:
    """Toda tarefa precisa alcançar uma meta — direto por REALIZA, ou através
    da tarefa-pai por SUBTAREFA_DE. Tarefa que não serve a meta nenhuma é
    trabalho que ninguém pediu."""
    sobe = defaultdict(list)
    for src, rel, dst in es:
        if rel in {"REALIZA", "SUBTAREFA_DE"}:
            sobe[src].append(dst)

    for nid, no in nos.items():
        if no.get("kind") != "tarefa":
            continue
        vistos, fila, achou = {nid}, deque([nid]), False
        while fila and not achou:
            for prox in sobe[fila.popleft()]:
                if prox.startswith("meta:"):
                    achou = True
                    break
                if prox not in vistos:
                    vistos.add(prox)
                    fila.append(prox)
        if not achou:
            erros.append(f"SEM META {nid}: nenhuma tarefa pode existir sem servir a uma meta")


def checar_atribuicao(nos, es, erros: list[str]) -> None:
    """Tarefa sem responsável ou sem prazo é higiene ruim — e é métrica auditada."""
    com_resp = {src for src, rel, _ in es if rel == "ATRIBUIDA_A"}
    for nid, no in nos.items():
        if no.get("kind") != "tarefa":
            continue
        if nid not in com_resp:
            erros.append(f"SEM RESP {nid}: tarefa sem responsável")
        if not no.get("prazo"):
            erros.append(f"SEM PRAZO {nid}")


# --------------------------------------------------------- diagnóstico

def bloqueadas(nos, es) -> set[str]:
    """Estado DERIVADO, não armazenado: uma tarefa está bloqueada se alguma
    pendência aberta aponta para ela. Guardar isso como coluna do kanban
    criaria uma segunda fonte de verdade que envelhece e mente."""
    return {
        dst for src, rel, dst in es
        if rel == "BLOQUEIA" and nos.get(src, {}).get("status") == "aberta"
    }


def resumo(nos, es) -> None:
    porkind = defaultdict(int)
    for no in nos.values():
        porkind[no.get("kind")] += 1
    porrel = defaultdict(int)
    for _, rel, _ in es:
        porrel[rel] += 1

    print(f"\n  {len(nos)} nós, {len(es)} arestas\n")
    print("  NÓS      " + "  ".join(f"{k}:{v}" for k, v in sorted(porkind.items())))
    print("  ARESTAS  " + "  ".join(f"{k}:{v}" for k, v in sorted(porrel.items())))

    kanban = defaultdict(list)
    for nid, no in nos.items():
        if no.get("kind") == "tarefa":
            kanban[no.get("status")].append(nid)
    print("\n  KANBAN   " + "  ".join(
        f"{c}:{len(kanban.get(c, []))}"
        for c in ("backlog", "pronta", "fazendo", "revisao", "feita")))

    bl = bloqueadas(nos, es)
    if bl:
        print(f"\n  BLOQUEADAS (derivado de pendência aberta): {', '.join(sorted(bl))}")


# ---------------------------------------------------------------- main

def main() -> int:
    raiz = Path(sys.argv[1] if len(sys.argv) > 1 else "data")
    esquema = Path(sys.argv[2] if len(sys.argv) > 2 else "schema/grafo.schema.json")

    nos = carregar(raiz)
    es = arestas(nos)
    erros: list[str] = []

    checar_schema(nos, esquema, erros)
    checar_prefixo(nos, erros)
    checar_referencias(nos, es, erros)
    checar_ciclos(es, {"DEPENDE_DE", "SUBTAREFA_DE", "BLOQUEIA"}, erros)
    checar_rastreabilidade(nos, es, erros)
    checar_atribuicao(nos, es, erros)

    resumo(nos, es)

    if erros:
        print(f"\n  {len(erros)} PROBLEMA(S):\n")
        for e in erros:
            print(f"    {e}")
        return 1

    print("\n  Grafo íntegro.\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
