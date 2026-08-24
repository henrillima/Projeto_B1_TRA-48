#!/usr/bin/env python3
"""
Compila o grafo de governança: YAML -> DuckDB.

Por que este arquivo existe: a fonte de verdade é texto versionado (decisao:D07),
mas texto não responde "quais conclusões não têm experimento". O banco é a forma
consultável da mesma informação — um artefato de build, como um .o. Ele é
descartável por construção: apagar governanca/build/ e rodar isto de novo tem
que devolver exatamente o mesmo banco.

Uso:
    uv run python governanca/tools/build.py \
        --src governanca/data \
        --schema governanca/schema/grafo.schema.json \
        --out governanca/build/grafo.duckdb
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from pathlib import Path
from typing import Any, Iterator

import duckdb
import yaml

# O script vive na mesma pasta que validar.py, e o Python põe a pasta do script
# em sys.path[0]. Importar em vez de reescrever as verificações é deliberado:
# duas implementações da mesma regra divergem, e a que diverge em silêncio é
# sempre a que o CI não roda.
import validar

# Campos promovidos a coluna própria em `node`. Todo o resto vai para props.
COLUNAS_NODE: tuple[str, ...] = ("id", "kind", "titulo", "status", "criado_em")

DDL = """
DROP VIEW  IF EXISTS nota;
DROP TABLE IF EXISTS edge;
DROP TABLE IF EXISTS node;

CREATE TABLE node (
    id        VARCHAR PRIMARY KEY,
    kind      VARCHAR NOT NULL,
    titulo    VARCHAR NOT NULL,
    status    VARCHAR,
    criado_em DATE,
    props     JSON
);

CREATE TABLE edge (
    src   VARCHAR NOT NULL,
    dst   VARCHAR NOT NULL,
    rel   VARCHAR NOT NULL,
    props JSON
);

CREATE INDEX idx_edge_src  ON edge(src);
CREATE INDEX idx_edge_dst  ON edge(dst);
CREATE INDEX idx_node_kind ON node(kind);
"""

# Notas não são nós (ninguém aponta para uma nota), mas são o registro datado da
# cadência. A view as achata sem criar uma terceira tabela — estado derivável
# não se armazena, regra 6 do CLAUDE.md.
DDL_VIEW_NOTA = """
CREATE VIEW nota AS
SELECT id AS node_id,
       UNNEST(from_json(
           json_extract(props, '$.notas'),
           '["STRUCT(data VARCHAR, autor VARCHAR, texto VARCHAR)"]')) AS n
FROM node
WHERE json_extract(props, '$.notas') IS NOT NULL;
"""


def normalizar(valor: Any) -> Any:
    """Converte datas em string ISO, recursivamente.

    PyYAML segue YAML 1.1 e transforma `2026-08-24` sem aspas em datetime.date.
    O jsonschema então reclama que não é string, e o json.dumps quebra. A regra
    de formato pertence ao carregador, não à disciplina de quem escreve o YAML:
    normalizamos na entrada em vez de exigir aspas em toda data.
    """
    if isinstance(valor, (dt.date, dt.datetime)):
        return valor.isoformat()[:10]
    if isinstance(valor, dict):
        return {k: normalizar(v) for k, v in valor.items()}
    if isinstance(valor, list):
        return [normalizar(v) for v in valor]
    return valor


def carregar(raiz: Path) -> dict[str, dict]:
    """Lê todo YAML sob a raiz e indexa por id.

    Ordena por caminho para o build ser determinístico: dois builds do mesmo
    commit têm que produzir a mesma ordem de inserção, senão comparar dois
    bancos deixa de ser possível.
    """
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


def validar_ou_abortar(nos: dict[str, dict], esquema: Path) -> None:
    """Roda as verificações do validar.py e recusa gravar se alguma falhar.

    Compilar um grafo quebrado produziria um banco que responde errado com cara
    de que respondeu certo — pior que não responder. O CI roda o validador
    separado também, mas depender só disso deixaria o build local mentir.
    """
    es = validar.arestas(nos)
    erros: list[str] = []
    validar.checar_schema(nos, esquema, erros)
    validar.checar_prefixo(nos, erros)
    validar.checar_referencias(nos, es, erros)
    validar.checar_ciclos(es, {"DEPENDE_DE", "SUBTAREFA_DE", "BLOQUEIA"}, erros)
    validar.checar_rastreabilidade(nos, es, erros)
    validar.checar_atribuicao(nos, es, erros)
    if erros:
        for e in erros:
            print(f"    {e}", file=sys.stderr)
        raise SystemExit(f"\n  build abortado: {len(erros)} problema(s) no grafo\n")


def linhas_node(nos: dict[str, dict]) -> Iterator[tuple]:
    """Gera as tuplas de `node`, com o excedente serializado em props.

    props guarda o que é específico de um kind. JSON num campo só mantém a
    consulta genérica possível e o schema estável: acrescentar um campo novo ao
    YAML amanhã não exige ALTER TABLE nem migração.
    """
    for nid, no in sorted(nos.items()):
        props: dict[str, Any] = {
            k: v for k, v in no.items()
            if k not in COLUNAS_NODE and k != "arestas" and not k.startswith("_")
        }
        # Exceção deliberada ao filtro de underscore: o site linka o YAML de
        # origem no GitHub, e sem o caminho não há como montar a URL.
        props["_arquivo"] = no["_arquivo"]
        yield (
            nid,
            no["kind"],
            no["titulo"],
            no.get("status"),
            no.get("criado_em"),
            json.dumps(props, ensure_ascii=False, sort_keys=True),
        )


def linhas_edge(nos: dict[str, dict]) -> Iterator[tuple]:
    """Gera as tuplas de `edge` a partir das arestas declaradas em cada nó.

    Só o qualificador `nota` da aresta vai para props hoje. O campo existe para
    que acrescentar outro qualificador amanhã não mude o esquema.
    """
    for nid, no in sorted(nos.items()):
        for a in (no.get("arestas") or []):
            extra = {k: v for k, v in a.items() if k not in ("rel", "dst")}
            yield (nid, a["dst"], a["rel"],
                   json.dumps(extra, ensure_ascii=False, sort_keys=True))


def gravar(destino: Path, nos: dict[str, dict]) -> tuple[int, int]:
    """Cria o banco do zero e insere nós e arestas. Devolve (n_nos, n_arestas).

    Recriar em vez de atualizar é o que garante que o banco seja função pura do
    conteúdo de data/: nada sobrevive de um build anterior.
    """
    destino.parent.mkdir(parents=True, exist_ok=True)
    if destino.exists():
        destino.unlink()

    con = duckdb.connect(str(destino))
    try:
        con.execute(DDL)
        ns = list(linhas_node(nos))
        es = list(linhas_edge(nos))
        con.executemany("INSERT INTO node VALUES (?, ?, ?, ?, ?, ?)", ns)
        con.executemany("INSERT INTO edge VALUES (?, ?, ?, ?)", es)
        con.execute(DDL_VIEW_NOTA)
        return len(ns), len(es)
    finally:
        con.close()


def main() -> int:
    p = argparse.ArgumentParser(description="Compila o grafo YAML para DuckDB.")
    p.add_argument("--src", type=Path, default=Path("governanca/data"))
    p.add_argument("--schema", type=Path,
                   default=Path("governanca/schema/grafo.schema.json"))
    p.add_argument("--out", type=Path,
                   default=Path("governanca/build/grafo.duckdb"))
    p.add_argument("--sem-validar", action="store_true",
                   help="Pula a validação. Use só para depurar o próprio compilador.")
    args = p.parse_args()

    nos = carregar(args.src)
    if not args.sem_validar:
        validar_ou_abortar(nos, args.schema)

    n_nos, n_arestas = gravar(args.out, nos)
    print(f"  {args.out}: {n_nos} nós, {n_arestas} arestas")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
