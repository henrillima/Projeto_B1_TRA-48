#!/usr/bin/env python3
"""
CLI de registro no grafo de governança.

Existe porque o custo de registrar tem que ser menor que o custo de não
registrar. Custo por registro vira registro que não acontece, que vira nota de
processo perdida.

Ela NÃO escreve no banco — escreve YAML, que é a fonte de verdade (decisao:D07).
O banco se refaz sozinho no próximo build. E não chama o validador: o ciclo do
G00 tem um passo VALIDAR explícito, e esconder a validação dentro de cada
comando ensinaria a confiar que "se passou, está certo" em vez de olhar.

    uv run python governanca/tools/gov.py tarefa "Ler a OD" \
        --resp pedro --prazo 2026-08-30 --meta meta:M1
"""
from __future__ import annotations

import datetime as dt
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional

import typer
import yaml

app = typer.Typer(add_completion=False, no_args_is_help=True,
                  help="Registro no grafo de governança do Projeto B1.")

RAIZ = Path(__file__).resolve().parents[1] / "data"
PESSOAS = ("henri", "pedro", "antonio")
KANBAN = ("backlog", "pronta", "fazendo", "revisao", "feita")
HOJE = dt.date.today().isoformat()


# ------------------------------------------------------------ utilidades

def erro(msg: str) -> None:
    typer.secho(f"  {msg}", fg=typer.colors.RED, err=True)
    raise typer.Exit(1)


def ok(caminho: Path, nid: str) -> None:
    typer.secho(f"  {nid}", fg=typer.colors.GREEN, bold=True)
    typer.echo(f"  {caminho.relative_to(RAIZ.parent.parent)}")


def proximo(pasta: str, padrao: str, largura: int = 2) -> int:
    """Lê o maior código existente na pasta e devolve o sucessor.

    Regex sobre o NOME DO ARQUIVO, não parse de YAML: pelas convenções §4.3 o
    nome do arquivo é o próprio código, e isso torna a operação barata.

    Condição de corrida conhecida e aceita: duas pessoas criando ao mesmo tempo
    em branches diferentes geram o mesmo id. O git detecta — conflito no mesmo
    caminho — e resolver é renomear um arquivo. Não vale complicar o gerador
    para evitar um conflito que o git já pega.
    """
    d = RAIZ / pasta
    d.mkdir(parents=True, exist_ok=True)
    rx = re.compile(padrao)
    usados = [int(m.group(1)) for f in d.glob("*.yaml")
              if (m := rx.match(f.stem))]
    return max(usados, default=0) + 1


def ler(nid: str) -> tuple[Path, dict]:
    """Localiza o YAML de um nó pelo id e devolve (caminho, documento)."""
    for f in RAIZ.rglob("*.yaml"):
        doc = yaml.safe_load(f.read_text(encoding="utf-8"))
        if isinstance(doc, dict) and doc.get("id") == nid:
            return f, doc
    erro(f"id não encontrado: {nid}")
    raise AssertionError  # inalcançável; só para o type checker


def esc(s: str) -> str:
    """Escapa para YAML de linha única entre aspas duplas."""
    return s.replace("\\", "\\\\").replace('"', '\\"')


def bloco(texto: str, recuo: str = "  ") -> str:
    """Formata texto multilinha como bloco literal do YAML."""
    linhas = [ln.rstrip() for ln in texto.strip().splitlines()]
    return "|\n" + "\n".join(f"{recuo}{ln}" if ln else "" for ln in linhas)


def escrever(pasta: str, arquivo: str, campos: list[tuple[str, str]],
             arestas: list[tuple[str, str]]) -> Path:
    """Emite o YAML à mão em vez de yaml.dump.

    O dump do PyYAML reordena chaves, quebra strings em pontos arbitrários e
    não usa bloco literal — o arquivo gerado ficaria visivelmente diferente dos
    escritos à mão, e a fonte de verdade é para ser lida por humanos no diff.
    """
    p = RAIZ / pasta / arquivo
    p.parent.mkdir(parents=True, exist_ok=True)
    if p.exists():
        erro(f"já existe: {p.name}")
    linhas = [f"{k}: {v}" for k, v in campos if v not in ("", None)]
    if arestas:
        linhas.append("arestas:")
        linhas += [f'  - {{rel: {r}, dst: "{d}"}}' for r, d in arestas]
    p.write_text("\n".join(linhas) + "\n", encoding="utf-8")
    return p


def git(*args: str) -> str:
    try:
        return subprocess.run(["git", *args], capture_output=True, text=True,
                              check=True, cwd=RAIZ.parent.parent).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def valida_pessoa(nome: str) -> str:
    if nome not in PESSOAS:
        erro(f"pessoa desconhecida: {nome}. Use uma de {', '.join(PESSOAS)}")
    return nome


# ------------------------------------------------------------- comandos

@app.command()
def meta(titulo: str,
         descricao: str = typer.Option("", help="o porquê da meta")) -> None:
    """Cria meta:M<n>. Sem arestas de saída — metas são folhas do lado de cima."""
    n = proximo("metas", r"M(\d+)$")
    p = escrever("metas", f"M{n}.yaml", [
        ("id", f"meta:M{n}"), ("kind", "meta"), ("titulo", f'"{esc(titulo)}"'),
        ("status", "aberta"), ("criado_em", HOJE),
        ("descricao", bloco(descricao) if descricao else ""),
    ], [])
    ok(p, f"meta:M{n}")


@app.command()
def tarefa(titulo: str,
           resp: str = typer.Option(..., help="henri | pedro | antonio"),
           prazo: str = typer.Option(..., help="AAAA-MM-DD"),
           meta_: str = typer.Option(None, "--meta", help="ex.: meta:M1"),
           pai: str = typer.Option(None, help="tarefa mãe, ex.: tarefa:T01"),
           depende: list[str] = typer.Option([], help="repetível"),
           prioridade: str = typer.Option("media"),
           horas: float = typer.Option(None, help="estimativa")) -> None:
    """Cria tarefa:T<nn>, ou T<pai>.<n> quando há --pai.

    A subtarefa herda a meta do pai lendo a aresta REALIZA dele: assim
    `checar_rastreabilidade` passa sem ninguém precisar pensar nisso.
    """
    valida_pessoa(resp)
    arestas: list[tuple[str, str]] = []

    if pai:
        _, doc = ler(pai)
        codigo_pai = pai.split(":", 1)[1]
        n = proximo("tarefas", rf"{re.escape(codigo_pai)}\.(\d+)$")
        codigo = f"{codigo_pai}.{n}"
        herdada = next((a["dst"] for a in (doc.get("arestas") or [])
                        if a["rel"] == "REALIZA"), None)
        if not (meta_ or herdada):
            erro(f"{pai} não tem aresta REALIZA; passe --meta explicitamente")
        arestas.append(("REALIZA", meta_ or herdada))
        arestas.append(("SUBTAREFA_DE", pai))
    else:
        if not meta_:
            erro("tarefa raiz precisa de --meta")
        n = proximo("tarefas", r"T(\d+)$")
        codigo = f"T{n:02d}"
        arestas.append(("REALIZA", meta_))

    arestas.append(("ATRIBUIDA_A", f"pessoa:{resp}"))
    arestas += [("DEPENDE_DE", d) for d in depende]

    p = escrever("tarefas", f"{codigo}.yaml", [
        ("id", f"tarefa:{codigo}"), ("kind", "tarefa"),
        ("titulo", f'"{esc(titulo)}"'), ("status", "backlog"),
        ("prazo", prazo), ("prioridade", prioridade),
        ("estimativa_h", str(horas) if horas else ""), ("criado_em", HOJE),
    ], arestas)
    ok(p, f"tarefa:{codigo}")


@app.command()
def decisao(titulo: str,
            just: str = typer.Option(..., help="a justificativa; vira `descricao`"),
            alt: list[str] = typer.Option(..., help="'opção :: por que não', repetível"),
            sobre: str = typer.Option(..., help="dst de DECIDE_SOBRE"),
            por: str = typer.Option(..., help="quem assina"),
            origem: str = typer.Option(None, help="ia:<id>, se nasceu de uma sessão"),
            supersede: Optional[str] = typer.Option(None)) -> None:
    """Cria decisao:D<nn>.

    `--alt` é obrigatório porque o §5.3 do enunciado pede justificativa E
    alternativas descartadas — torná-lo obrigatório é a forma de fazer a
    exigência inescapável em vez de opcional na prática.

    Com --supersede, marca a antiga como `superada` e cria a aresta SUPERSEDE.
    """
    valida_pessoa(por)
    pares = []
    for a in alt:
        if "::" not in a:
            erro(f"--alt precisa do formato 'opção :: por que não'; recebi: {a}")
        o, pq = a.split("::", 1)
        pares.append((o.strip(), pq.strip()))

    n = proximo("decisoes", r"D(\d+)$")
    arestas = [("DECIDE_SOBRE", sobre), ("ASSINADA_POR", f"pessoa:{por}")]
    if origem:
        arestas.append(("ORIGINA_DE", origem))
    if supersede:
        arestas.append(("SUPERSEDE", supersede))

    corpo = [f"id: decisao:D{n:02d}", "kind: decisao",
             f'titulo: "{esc(titulo)}"', "status: vigente",
             f"criado_em: {HOJE}", f"descricao: {bloco(just)}",
             "alternativas_descartadas:"]
    for o, pq in pares:
        corpo.append(f'  - opcao: "{esc(o)}"')
        corpo.append(f'    por_que_nao: "{esc(pq)}"')
    corpo.append("arestas:")
    corpo += [f'  - {{rel: {r}, dst: "{d}"}}' for r, d in arestas]

    p = RAIZ / "decisoes" / f"D{n:02d}.yaml"
    p.parent.mkdir(parents=True, exist_ok=True)
    if p.exists():
        erro(f"já existe: {p.name}")
    p.write_text("\n".join(corpo) + "\n", encoding="utf-8")

    if supersede:
        fp, doc = ler(supersede)
        txt = fp.read_text(encoding="utf-8")
        fp.write_text(re.sub(r"^status:.*$", "status: superada", txt,
                             count=1, flags=re.M), encoding="utf-8")
        typer.echo(f"  {supersede} marcada como superada")
    ok(p, f"decisao:D{n:02d}")


@app.command()
def pendencia(titulo: str,
              bloqueia: list[str] = typer.Option(..., help="ids travados, repetível"),
              descricao: str = typer.Option("")) -> None:
    """Cria pendencia:P<nn> em `aberta`, com BLOQUEIA para cada alvo.

    É isto que torna `bloqueada` um estado derivado em vez de coluna do kanban.
    """
    n = proximo("pendencias", r"P(\d+)$")
    p = escrever("pendencias", f"P{n:02d}.yaml", [
        ("id", f"pendencia:P{n:02d}"), ("kind", "pendencia"),
        ("titulo", f'"{esc(titulo)}"'), ("status", "aberta"),
        ("criado_em", HOJE),
        ("descricao", bloco(descricao) if descricao else ""),
    ], [("BLOQUEIA", b) for b in bloqueia])
    ok(p, f"pendencia:P{n:02d}")


@app.command()
def fonte(slug: str, titulo: str,
          origem: str = typer.Option(..., help="órgão e URL"),
          limitacoes: str = typer.Option(..., help="o campo que mais vale nota"),
          formato: str = typer.Option(""), cobertura: str = typer.Option("")) -> None:
    """Cria fonte:<slug>. Id por slug, não numerado — fonte se cita pelo nome.

    `--limitacoes` é obrigatório: reconhecer a limitação do próprio dado vale
    mais, na avaliação, do que apresentar o dado sem ressalvas (§3.2).
    """
    p = escrever("fontes", f"{slug}.yaml", [
        ("id", f"fonte:{slug}"), ("kind", "fonte"),
        ("titulo", f'"{esc(titulo)}"'), ("criado_em", HOJE),
        ("origem", f'"{esc(origem)}"'), ("formato", f'"{esc(formato)}"'),
        ("cobertura", f'"{esc(cobertura)}"'),
        ("limitacoes", f'"{esc(limitacoes)}"'),
    ], [])
    ok(p, f"fonte:{slug}")


@app.command()
def experimento(titulo: str,
                obj: float = typer.Option(..., help="valor da função objetivo"),
                gap: float = typer.Option(...), segundos: float = typer.Option(...),
                param: list[str] = typer.Option([], help="'p=12', repetível"),
                usa: list[str] = typer.Option([], help="fonte ou arquivo, repetível"),
                por: str = typer.Option(...),
                conclusao: str = typer.Option("", help="hipótese e o que se aprendeu"),
                permitir_sujo: bool = typer.Option(False, "--permitir-sujo")) -> None:
    """Cria experimento:E<nn>, carimbando o commit corrente.

    Recusa se a árvore de trabalho estiver suja: um experimento carimbado com um
    commit que não contém o código que rodou é pior que um sem carimbo, porque
    parece reprodutível e não é.
    """
    valida_pessoa(por)
    sha = git("rev-parse", "--short", "HEAD")
    if not sha:
        erro("não consegui ler o commit corrente")
    if git("status", "--porcelain") and not permitir_sujo:
        erro("árvore suja: commite antes de registrar o experimento "
             "(ou use --permitir-sujo e explique na conclusão)")

    ps = []
    for kv in param:
        if "=" not in kv:
            erro(f"--param precisa do formato chave=valor; recebi: {kv}")
        k, v = kv.split("=", 1)
        ps.append(f'{k.strip()}: {v.strip()}')

    n = proximo("experimentos", r"E(\d+)$")
    p = escrever("experimentos", f"E{n:02d}.yaml", [
        ("id", f"experimento:E{n:02d}"), ("kind", "experimento"),
        ("titulo", f'"{esc(titulo)}"'), ("criado_em", HOJE),
        ("commit", sha), ("parametros", "{" + ", ".join(ps) + "}" if ps else ""),
        ("obj", str(obj)), ("gap", str(gap)), ("segundos", str(segundos)),
        ("descricao", bloco(conclusao) if conclusao else ""),
    ], [("USA", u) for u in usa] + [("ASSINADA_POR", f"pessoa:{por}")])
    ok(p, f"experimento:E{n:02d}")


@app.command()
def ia(slug: str, titulo: str,
       aceito: str = typer.Option(..., help="integral | parcial | descartado"),
       critica: str = typer.Option(..., help="mínimo 20 caracteres, no schema"),
       por: str = typer.Option(...)) -> None:
    """Cria ia:<data>-<slug>. A data entra no id automaticamente.

    `--critica` é obrigatória aqui e no schema: quem não consegue criticar a
    resposta não a entendeu, e portanto não pode assiná-la (§5.6).
    """
    valida_pessoa(por)
    if aceito not in ("integral", "parcial", "descartado"):
        erro("--aceito precisa ser integral, parcial ou descartado")
    if len(critica.strip()) < 20:
        erro("a crítica tem menos de 20 caracteres. 'Boa resposta' não é crítica: "
             "aponte uma coisa específica que estava errada, incompleta ou discutível")

    nid = f"ia:{HOJE}-{slug}"
    p = escrever("interacoes", f"{HOJE}-{slug}.yaml", [
        ("id", nid), ("kind", "ia"), ("titulo", f'"{esc(titulo)}"'),
        ("criado_em", HOJE), ("aceito", aceito),
        ("critica_humana", bloco(critica)),
    ], [("ASSINADA_POR", f"pessoa:{por}")])
    ok(p, nid)


@app.command()
def nota(nid: str, texto: str, por: str = typer.Option(...)) -> None:
    """Acrescenta uma observação datada a um nó.

    Append-only por construção: nunca edita nem apaga nota antiga. Uma nota
    corrigida em silêncio perde a única coisa que a tornava valiosa, que é ter
    sido escrita naquele dia.
    """
    valida_pessoa(por)
    fp, _ = ler(nid)
    txt = fp.read_text(encoding="utf-8").rstrip("\n")
    if "\nnotas:" not in txt and not txt.startswith("notas:"):
        txt += "\nnotas:"
    txt += (f"\n  - data: {HOJE}\n    autor: {por}\n"
            f'    texto: "{esc(texto)}"')
    fp.write_text(txt + "\n", encoding="utf-8")
    ok(fp, f"{nid} + nota")


@app.command()
def mv(nid: str, status: str) -> None:
    """Move uma tarefa de coluna no kanban.

    Não existe `bloqueada`: bloqueio é derivado de pendência aberta. Se a tarefa
    está travada, o registro certo é uma pendência, não um estado.
    """
    if status not in KANBAN:
        erro(f"status inválido: {status}. Use um de {', '.join(KANBAN)}. "
             f"(Não existe 'bloqueada' — abra uma pendência.)")
    fp, doc = ler(nid)
    if doc.get("kind") != "tarefa":
        erro(f"{nid} não é tarefa")
    txt = fp.read_text(encoding="utf-8")
    if not re.search(r"^status:", txt, flags=re.M):
        erro(f"{nid} não tem campo status")
    fp.write_text(re.sub(r"^status:.*$", f"status: {status}", txt,
                         count=1, flags=re.M), encoding="utf-8")
    ok(fp, f"{nid} -> {status}")


@app.command()
def estado() -> None:
    """Resumo rápido do grafo, sem precisar compilar o banco."""
    kinds: dict[str, int] = {}
    kanban: dict[str, int] = {}
    for f in RAIZ.rglob("*.yaml"):
        d = yaml.safe_load(f.read_text(encoding="utf-8"))
        if not isinstance(d, dict):
            continue
        kinds[d.get("kind", "?")] = kinds.get(d.get("kind", "?"), 0) + 1
        if d.get("kind") == "tarefa":
            kanban[d.get("status", "?")] = kanban.get(d.get("status", "?"), 0) + 1
    typer.echo("\n  " + "  ".join(f"{k}:{v}" for k, v in sorted(kinds.items())))
    typer.echo("  " + "  ".join(f"{c}:{kanban.get(c, 0)}" for c in KANBAN) + "\n")


if __name__ == "__main__":
    app()
