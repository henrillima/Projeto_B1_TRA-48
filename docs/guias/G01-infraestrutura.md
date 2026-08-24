# G01 — Infraestrutura de governança

> Pacote de trabalho da Camada B. Leia `G00-como-trabalhar.md` e `CLAUDE.md` antes.

| | |
| --- | --- |
| **Tarefas** | `tarefa:T00`, `tarefa:T01.1` … `tarefa:T01.6` (guarda-chuva `tarefa:T01`) |
| **Responsável** | Henri (`pessoa:henri`) |
| **Prazo** | 31/08/2026 |
| **Meta** | `meta:M4` — projeto rastreável, auditável e reprodutível |

---

## 1. Objetivo

Ao fim deste pacote existe uma cadeia completa e automática que vai de um arquivo YAML escrito
à mão até um site público auditável: escrever → validar → compilar para DuckDB → consultar por
MCP → publicar. A partir daí, registrar custa um comando, e "o que não estiver no banco não
aconteceu" deixa de ser uma ameaça e vira uma consequência mecânica.

---

## 2. Tarefas no grafo

| Id | Título | Prazo | Est. | Depende de |
| --- | --- | --- | --- | --- |
| `tarefa:T00` | Definir o esquema do grafo de governança | 25/08 | 4 h | — |
| `tarefa:T01.1` | Escrever o compilador YAML → DuckDB | 27/08 | 4 h | T00 |
| `tarefa:T01.2` | Escrever o validador de schema e o checador de integridade | 27/08 | 3 h | T00 |
| `tarefa:T01.3` | Escrever a CLI `gov` de registro | 28/08 | 5 h | T01.1, T01.2 |
| `tarefa:T01.4` | Escrever o servidor MCP estritamente read-only | 30/08 | 4 h | T01.1 |
| `tarefa:T01.5` | Gerar o site: grafo navegável e uma página por registro | 31/08 | 6 h | T01.1 |
| `tarefa:T01.6` | Configurar o workflow de publicação no GitHub Pages | 31/08 | 2 h | T01.5 |

Ordem de execução real: T00 → T01.2 → T01.1 → T01.3 → (T01.4 ∥ T01.5) → T01.6. O validador
vem antes do compilador porque o compilador o importa; T01.4 e T01.5 são independentes entre
si e podem sair em qualquer ordem.

O guarda-chuva `tarefa:T01` só fecha quando as seis subtarefas estiverem em `feita`. Ele não
tem trabalho próprio — existe para dar um único ponto de agregação no kanban.

---

## 3. Pré-requisitos

1. **`tarefa:T00` fechada.** O esquema em `governanca/schema/grafo.schema.json` precisa estar
   escrito e estável antes de existir compilador, porque todo o resto o lê. Se o esquema ainda
   estiver mudando, pare aqui e feche T00 primeiro — cada mudança de enum depois de T01.5
   obriga a revisar quatro arquivos.
2. **`uv` instalado** e funcionando (`uv --version`).
3. **Repositório criado no GitHub**, sob a conta `henrillima`, com `main` já existindo.
4. **Permissão de administrador no repositório** — T01.6 exige mexer em Settings → Pages e em
   branch protection, e nenhuma das duas coisas se faz por API sem admin.

Não é pré-requisito: nenhum dado do projeto. Este pacote inteiro roda com o grafo vazio ou com
os poucos nós já escritos. É de propósito — a Camada B tem que estar de pé antes da Camada A
gerar o que registrar.

---

## 4. Insumos

| Insumo | Onde | Para quê |
| --- | --- | --- |
| `governanca/schema/grafo.schema.json` | já escrito (T00) | contrato de todos os scripts |
| `governanca/data/**.yaml` | já escrito, parcial | 50 nós de partida para testar de verdade |
| `governanca/tools/validar.py` | **já escrito** | ponto de partida de T01.2 |
| `docs/referencia/convencoes.md` | já escrito | §4.1 ids, §5 kanban, §7 YAML, §6.3 gitignore |
| `decisao:D06`, `D07`, `D08`, `D09` | já registradas | as escolhas que este guia implementa |
| Cytoscape.js, arquivo UMD `dist/cytoscape.min.js` (428 KB) | vendorizar (ver §5.5) | desenho do grafo |

**Não** são insumos: nenhum CDN, nenhum serviço externo, nenhum banco hospedado. Tudo o que o
site precisa para funcionar tem que estar dentro do repositório. Site que depende de CDN quebra
offline e quebra quando o CDN muda de política — e a arguição pode acontecer sem internet.

---

## 5. Passo a passo

### 5.0 · Antes de escrever qualquer coisa

```bash
git switch -c h/T01-infraestrutura
uv run python governanca/tools/validar.py \
    governanca/data governanca/schema/grafo.schema.json
```

O validador tem que sair com "Grafo íntegro". Se não sair, o problema é nos YAML já escritos,
não no que você vai escrever agora — conserte antes, senão você vai passar a próxima hora
depurando o compilador por um erro que já existia.

Mova `tarefa:T01.1` para `fazendo` (§3.1 do G00). Por enquanto isso é editar o YAML à mão;
depois de T01.3 vira `gov mv`.

---

### 5.1 · T01.1 — o compilador `governanca/tools/build.py`

**O que ele faz:** lê todo YAML sob `governanca/data/`, roda as verificações do validador,
recusa gravar se alguma falhar, e escreve `governanca/build/grafo.duckdb` do zero com duas
tabelas — `node` e `edge` — mais uma view derivada `nota`.

**As três decisões de projeto embutidas nele**, e que você vai ter que defender:

*Duas tabelas, não onze.* Um nó por linha em `node`, uma aresta por linha em `edge`. O
que é específico de um `kind` (`alternativas_descartadas`, `limitacoes`, `obj`/`gap`/`segundos`,
`critica_humana`) vai para a coluna `props JSON`. Uma coluna por campo daria uma tabela larga
e quase toda nula; uma tabela por kind daria onze tabelas e nenhuma consulta que atravessa
tipos — e as quatro perguntas do §5.4 do enunciado atravessam tipos todas.

*Só vira coluna o que aparece em `WHERE`, `ORDER BY` ou `JOIN`.* `id`, `kind`, `titulo`,
`status`, `criado_em`. O resto fica em `props`, acessível por `json_extract_string(props,
'$.campo')`. O critério é uso real, não elegância do modelo.

*Recriar, nunca atualizar.* O banco é apagado e reconstruído a cada build. É o que garante que
ele seja função pura do conteúdo de `governanca/data/`: um nó apagado no YAML não sobrevive no
banco, e dois builds do mesmo commit produzem o mesmo banco.

```python
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
```

**Conferência imediata.** Rodado contra o `governanca/data/` de hoje, o resultado esperado é da
ordem de 50 nós e 130 arestas. Depois, no `duckdb` interativo ou em Python:

```sql
-- as tarefas bloqueadas, derivadas de pendência aberta (nunca armazenadas)
SELECT t.id, t.titulo, p.id AS pendencia
FROM edge e
JOIN node p ON p.id = e.src AND p.kind = 'pendencia' AND p.status = 'aberta'
JOIN node t ON t.id = e.dst
WHERE e.rel = 'BLOQUEIA'
ORDER BY t.id;

-- notas achatadas pela view
SELECT node_id, n.data, n.autor, n.texto FROM nota ORDER BY n.data DESC LIMIT 10;

-- o caminho recursivo: tudo a até 2 saltos de uma tarefa, em qualquer direção
WITH RECURSIVE viz(id, salto) AS (
    SELECT 'tarefa:T01.1', 0
  UNION
    SELECT CASE WHEN e.src = v.id THEN e.dst ELSE e.src END, v.salto + 1
    FROM viz v JOIN edge e ON e.src = v.id OR e.dst = v.id
    WHERE v.salto < 2
)
SELECT n.kind, n.id, n.titulo FROM viz v JOIN node n ON n.id = v.id;
```

O `UNION` sem `ALL` é obrigatório no recursivo: com `ALL`, um grafo com ciclo — e o nosso tem
ciclos quando se ignora a direção — não termina.

---

### 5.2 · T01.2 — o validador (já existe; falta completar)

`governanca/tools/validar.py` já está escrito. **Não o reescreva.** Leia, entenda cada
verificação, e acrescente as três que faltam.

#### O que ele já faz

O arquivo separa duas camadas que costumam ser confundidas: *schema* pergunta se cada arquivo
está bem formado; *integridade* pergunta se o conjunto faz sentido como grafo. A segunda é a
que transforma uma pasta de YAML em banco de governança, e é a que nenhum validador de schema
faz por você.

| Verificação | Função | O que pega | Por que importa |
| --- | --- | --- | --- |
| Schema | `checar_schema` | campo faltando, enum errado, `critica_humana` curta demais | é o contrato do §7 das convenções |
| Prefixo | `checar_prefixo` | `meta:T12` — id cujo prefixo não bate com o `kind` | id é chave estrangeira; prefixo errado quebra toda consulta que filtra por `LIKE 'tarefa:%'` |
| Aresta órfã | `checar_referencias` | `dst` que não existe | defeito silencioso clássico: o grafo aceita, e a informação some |
| Ciclo | `checar_ciclos` | `DEPENDE_DE`/`SUBTAREFA_DE`/`BLOQUEIA` circulares | A depende de B que depende de A significa que nada pode começar |
| Rastreabilidade | `checar_rastreabilidade` | tarefa que não alcança meta nenhuma, direto ou pelo pai | regra 5 do `CLAUDE.md`: tarefa que não serve a meta é trabalho que ninguém pediu |
| Higiene | `checar_atribuicao` | tarefa sem `ATRIBUIDA_A` ou sem `prazo` | é métrica auditada e publicada no site |

A busca de ciclo é uma DFS de três cores (branco/cinza/preto) — encontrar cinza durante a
descida é a definição de aresta de retorno. A rastreabilidade é uma BFS subindo por `REALIZA`
e `SUBTAREFA_DE` até achar um `meta:`; ela aceita subtarefa que herda a meta do pai, que é
exatamente o caso de T01.1..T01.6.

E `bloqueadas()` não é verificação, é diagnóstico: calcula, na hora, quais tarefas estão
bloqueadas. Nunca guarde isso — regra 6.

#### O que falta acrescentar

**(a) Nota append-only.** A regra 7 do `CLAUDE.md` diz que nota nunca se edita. Nenhuma
verificação atual pega uma edição, porque a informação necessária não está no arquivo — está
no git. A checagem compara a lista `notas` do working tree com a do commit-base: a antiga tem
que ser prefixo da nova.

```python
import subprocess


def checar_notas_append_only(raiz: Path, ref: str, erros: list[str]) -> None:
    """Nota commitada nunca muda: a lista antiga tem que ser PREFIXO da nova.

    Regra 7 do CLAUDE.md. Uma nota corrigida em silêncio perde a única coisa
    que a tornava valiosa — ter sido escrita naquele dia. A verificação vive
    aqui e não no schema porque a informação não está no arquivo, está no git.

    `ref` é o commit-base: HEAD em uso local, origin/main no CI de PR. Exige
    fetch-depth: 0 no checkout, senão o histórico raso não tem o arquivo.
    """
    for caminho in sorted(raiz.rglob("*.yaml")):
        r = subprocess.run(["git", "show", f"{ref}:{caminho}"],
                           capture_output=True, text=True)
        if r.returncode != 0:
            continue                      # arquivo novo neste branch: nada a comparar
        antes = (normalizar(yaml.safe_load(r.stdout)) or {}).get("notas") or []
        agora = (normalizar(yaml.safe_load(
            caminho.read_text(encoding="utf-8"))) or {}).get("notas") or []
        if agora[:len(antes)] != antes:
            erros.append(
                f"NOTA    {caminho}: nota já commitada foi alterada ou removida "
                f"({len(antes)} antes, {len(agora)} agora)")
```

**(b) Conclusão sem experimento.** É literalmente a quarta das quatro perguntas do §5.4 do
enunciado, e a mais fácil de errar porque a resposta certa é uma ausência. Enquanto não houver
nenhuma `conclusao` no grafo, a verificação passa de graça — e é isso que a torna perigosa:
ela precisa estar escrita **antes** de a primeira conclusão aparecer, senão ninguém lembra.

```python
def checar_conclusoes(nos, es, erros: list[str]) -> None:
    """Conclusão do relatório precisa de experimento que a sustente.

    Aceita a aresta nos dois sentidos: conclusao -SUSTENTA-> experimento ou
    experimento -SUSTENTA-> conclusao. Fixar um sentido só seria mais limpo,
    mas na prática as duas leituras são naturais e a divergência silenciosa
    custaria mais que a tolerância.
    """
    sustenta = {(s, d) for s, r, d in es if r == "SUSTENTA"}
    exp = {n for n, no in nos.items() if no.get("kind") == "experimento"}
    for nid, no in nos.items():
        if no.get("kind") != "conclusao":
            continue
        if not any((nid, e) in sustenta or (e, nid) in sustenta for e in exp):
            erros.append(f"SEM EXP {nid}: conclusão sem experimento que a sustente")
```

**(c) Fonte sem `limitacoes` útil.** O schema já exige o campo. O que ele não pega é campo
preenchido com nada — `"nenhuma"`, `"n/a"`, três palavras. Reconhecer a limitação do próprio
dado vale mais na avaliação que apresentar o dado sem ressalva (§3.2 do enunciado), então o
campo vazio de conteúdo é pior que a ausência, porque simula conformidade.

```python
VAZIO = {"", "-", "n/a", "na", "nenhuma", "nenhum", "sem limitações", "a confirmar"}


def checar_fontes(nos, erros: list[str]) -> None:
    """`limitacoes` preenchido com 'nenhuma' é conformidade simulada."""
    for nid, no in nos.items():
        if no.get("kind") != "fonte":
            continue
        lim = (no.get("limitacoes") or "").strip()
        if lim.lower().rstrip(".") in VAZIO or len(lim) < 40:
            erros.append(f"FONTE   {nid}: 'limitacoes' sem conteúdo real")
```

O limiar de 40 caracteres é arbitrário e vai irritar alguém em algum momento. Registre-o como
decisão junto com a alternativa considerada (revisão humana em vez de limiar automático) — é
exatamente o tipo de escolha pequena que o G00 §3.3 manda registrar.

Ligue as três em `main()`, na ordem: schema, prefixo, referências, ciclos, rastreabilidade,
higiene, conclusões, fontes, notas. A de notas por último porque é a única que chama processo
externo e a única que pode falhar por motivo de ambiente.

---

### 5.3 · T01.3 — a CLI `gov`

**Por que ela existe.** Sem CLI, registrar é abrir o editor, lembrar o formato, inventar o
próximo id e torcer para não errar o enum. Isso tem um custo por registro, e custo por registro
vira registro que não acontece — que vira nota de processo. A CLI existe para que o custo de
registrar seja menor que o custo de não registrar.

**Typer**, não argparse: os subcomandos são muitos, cada um com opções próprias, e o Typer
deriva a interface das anotações de tipo — a assinatura da função vira o `--help` sem
duplicação. Com argparse seriam ~80 linhas de `add_argument` que envelhecem separadas da
função que as consome.

#### Numeração automática de id

O id nunca é digitado. A CLI lê o maior código existente na pasta do tipo e incrementa. É
regex sobre o nome do arquivo, não parse de YAML: nome de arquivo é o índice barato e, pelas
convenções §4.3, ele é o próprio código.

Subtarefa tem regra própria: `T01.7` é o sucessor de `T01.6` dentro da pasta `tarefas/`, então
o padrão é `^T01\.(\d+)$`, não a numeração global. E a subtarefa herda a meta do pai lendo a
aresta `REALIZA` do pai — assim `checar_rastreabilidade` passa sem ninguém pensar nisso.

Isto tem uma condição de corrida óbvia: duas pessoas criando tarefa ao mesmo tempo em branches
diferentes geram o mesmo id. O git pega — conflito no mesmo caminho de arquivo — e resolver é
renomear um arquivo. Não vale complicar o gerador para evitar um conflito que o git já detecta.

#### O esqueleto e três subcomandos completos

```python
#!/usr/bin/env python3
"""
CLI de registro no grafo de governança.

Existe porque o custo de registrar tem que ser menor que o custo de não
registrar. Ela não escreve no banco — escreve YAML, que é a fonte de verdade
(decisao:D07). O banco se refaz sozinho no próximo build.

    uv run python governanca/tools/gov.py tarefa "Ler a OD" \
        --resp pedro --prazo 2026-08-30 --meta meta:M1
"""
from __future__ import annotations

import datetime as dt
import re
from pathlib import Path
from typing import Any, Optional

import typer
import yaml

DATA = Path("governanca/data")

PASTA: dict[str, str] = {
    "meta": "metas", "tarefa": "tarefas", "decisao": "decisoes",
    "pendencia": "pendencias", "fonte": "fontes", "referencia": "referencias",
    "experimento": "experimentos", "arquivo": "arquivos",
    "conclusao": "conclusoes", "ia": "interacoes", "pessoa": "pessoas",
}

# Ordem canônica das chaves no YAML gerado. Sem isso, o safe_dump ordena
# alfabeticamente e `aceito` vem antes de `titulo` — diff ilegível e arquivo
# que não se parece com os escritos à mão.
ORDEM = ["id", "kind", "titulo", "status", "prazo", "prioridade", "estimativa_h",
         "criado_em", "descricao", "alternativas_descartadas", "origem", "formato",
         "cobertura", "limitacoes", "aceito", "critica_humana", "parametros",
         "obj", "gap", "segundos", "commit", "caminho", "secao", "papel",
         "github", "arestas", "notas"]

KANBAN = ["backlog", "pronta", "fazendo", "revisao", "feita"]

app = typer.Typer(add_completion=False, help="Registro no grafo de governança.")


def hoje() -> str:
    """Data de hoje em ISO. Isolada numa função para os testes poderem fixá-la."""
    return dt.date.today().isoformat()


def caminho_de(nid: str) -> Path:
    """Traduz um id do grafo no caminho do arquivo, pelas convenções §4.3."""
    kind, codigo = nid.split(":", 1)
    return DATA / PASTA[kind] / f"{codigo}.yaml"


def ler(nid: str) -> dict:
    """Carrega o YAML de um nó existente, ou falha com mensagem útil."""
    p = caminho_de(nid)
    if not p.exists():
        raise typer.BadParameter(f"{nid} não existe em {p}")
    return yaml.safe_load(p.read_text(encoding="utf-8"))


def proximo_id(kind: str, prefixo: str, largura: int = 2) -> str:
    """Maior código existente + 1. Regex sobre o nome do arquivo, não parse do
    YAML: pelas convenções §4.3 o nome do arquivo É o código, e ler 50 arquivos
    para descobrir um número seria desperdício."""
    pat = re.compile(rf"^{re.escape(prefixo)}(\d+)$")
    maior = 0
    for arq in (DATA / PASTA[kind]).glob("*.yaml"):
        m = pat.match(arq.stem)
        if m:
            maior = max(maior, int(m.group(1)))
    return f"{kind}:{prefixo}{maior + 1:0{largura}d}"


def proxima_subtarefa(pai: str) -> str:
    """T01.6 -> T01.7. Numeração local ao pai, não global."""
    codigo = pai.split(":", 1)[1]
    pat = re.compile(rf"^{re.escape(codigo)}\.(\d+)$")
    maior = 0
    for arq in (DATA / "tarefas").glob("*.yaml"):
        m = pat.match(arq.stem)
        if m:
            maior = max(maior, int(m.group(1)))
    return f"tarefa:{codigo}.{maior + 1}"


def escrever(doc: dict[str, Any], *, sobrescrever: bool = False) -> Path:
    """Grava o YAML na ordem canônica de chaves. Recusa sobrescrever por engano."""
    p = caminho_de(doc["id"])
    if p.exists() and not sobrescrever:
        raise typer.BadParameter(f"{p} já existe — ids nunca são reaproveitados")
    p.parent.mkdir(parents=True, exist_ok=True)
    ordenado = {k: doc[k] for k in ORDEM if k in doc}
    ordenado.update({k: v for k, v in doc.items() if k not in ordenado})
    p.write_text(yaml.safe_dump(ordenado, allow_unicode=True,
                                sort_keys=False, width=100), encoding="utf-8")
    typer.echo(str(p))
    return p


@app.command()
def tarefa(titulo: str,
           resp: str = typer.Option(..., help="henri | pedro | antonio"),
           prazo: str = typer.Option(..., help="AAAA-MM-DD"),
           meta: Optional[str] = typer.Option(None, help="meta:M1 … meta:M4"),
           pai: Optional[str] = typer.Option(None, help="tarefa:T01 — cria subtarefa"),
           prioridade: str = typer.Option("media"),
           horas: Optional[float] = typer.Option(None, help="estimativa_h")) -> None:
    """Cria uma tarefa (ou subtarefa, com --pai).

    Sempre nasce em `backlog` e sempre com responsável e prazo — os dois campos
    que `checar_atribuicao` exige. Deixar a CLI criar tarefa incompleta seria
    mover o erro do momento da escrita para o momento do CI.
    """
    if not meta and not pai:
        raise typer.BadParameter("informe --meta ou --pai")

    nid = proxima_subtarefa(pai) if pai else proximo_id("tarefa", "T")
    arestas: list[dict[str, str]] = []

    if pai:
        doc_pai = ler(pai)
        herdada = next((a["dst"] for a in doc_pai.get("arestas", [])
                        if a["rel"] == "REALIZA"), None)
        if not herdada and not meta:
            raise typer.BadParameter(f"{pai} não tem REALIZA; informe --meta")
        arestas.append({"rel": "SUBTAREFA_DE", "dst": pai})
        arestas.append({"rel": "REALIZA", "dst": meta or herdada})
    else:
        arestas.append({"rel": "REALIZA", "dst": meta})

    arestas.append({"rel": "ATRIBUIDA_A", "dst": f"pessoa:{resp}"})

    doc: dict[str, Any] = {
        "id": nid, "kind": "tarefa", "titulo": titulo, "status": "backlog",
        "prazo": prazo, "prioridade": prioridade, "criado_em": hoje(),
        "arestas": arestas,
    }
    if horas:
        doc["estimativa_h"] = horas
    escrever(doc)


@app.command()
def nota(nid: str,
         texto: str = typer.Option(..., help="a nota"),
         autor: str = typer.Option(..., help="henri | pedro | antonio")) -> None:
    """Acrescenta uma nota datada. Append-only: só empilha, nunca edita.

    Não existe `gov nota --editar` de propósito. Se a CLI oferecesse a operação,
    alguém a usaria, e o checador de append-only barraria o commit depois — o
    caminho de menor resistência tem que ser o caminho certo.
    """
    doc = ler(nid)
    doc.setdefault("notas", []).append(
        {"data": hoje(), "autor": autor, "texto": texto})
    escrever(doc, sobrescrever=True)


@app.command()
def mv(nid: str, status: str) -> None:
    """Move um cartão no kanban.

    Valida contra o enum aqui e não só no schema porque a mensagem de erro chega
    no momento do erro, não três comandos depois. E avisa em `feita` sem passar
    por `revisao`: a coluna de revisão é deliberada (§5 das convenções) e pular
    é o que ela existe para tornar visível.
    """
    if status not in KANBAN:
        raise typer.BadParameter(f"status inválido; use um de {KANBAN}")
    doc = ler(nid)
    antigo = doc.get("status")
    if status == "feita" and antigo != "revisao":
        typer.secho(f"aviso: {nid} foi de '{antigo}' direto para 'feita', "
                    f"sem passar por revisão", fg="yellow", err=True)
    doc["status"] = status
    escrever(doc, sobrescrever=True)
    typer.echo(f"{nid}: {antigo} -> {status}")
```

#### Os outros subcomandos — assinaturas

Mesmo padrão: monta o dict, chama `escrever`. Cada um só difere nos campos obrigatórios do seu
`kind` e nas arestas que cria.

```python
@app.command()
def meta(titulo: str, descricao: str = typer.Option("")) -> None:
    """Cria meta:M<n>. Sem arestas de saída — metas são folhas do lado de cima."""


@app.command()
def decisao(titulo: str,
            just: str = typer.Option(..., help="a justificativa; vira `descricao`"),
            alt: list[str] = typer.Option(..., help="'opção :: por que não', repetível"),
            sobre: str = typer.Option(..., help="dst de DECIDE_SOBRE"),
            por: str = typer.Option(..., help="quem assina"),
            supersede: Optional[str] = typer.Option(None)) -> None:
    """Cria decisao:D<nn>. Exige >= 1 alternativa: o §5.3 do enunciado pede
    justificativa E alternativas descartadas, e `--alt` obrigatório é a forma de
    tornar a exigência inescapável. Com --supersede, marca a antiga como
    `superada` e cria a aresta SUPERSEDE."""


@app.command()
def pendencia(titulo: str,
              bloqueia: list[str] = typer.Option(..., help="ids travados, repetível"),
              descricao: str = typer.Option("")) -> None:
    """Cria pendencia:P<nn> em `aberta` com BLOQUEIA para cada alvo. É isto que
    torna 'bloqueada' um estado derivado em vez de coluna do kanban."""


@app.command()
def fonte(slug: str, titulo: str,
          origem: str = typer.Option(..., help="órgão e URL"),
          limitacoes: str = typer.Option(..., help="o campo que mais vale nota"),
          formato: str = typer.Option(""), cobertura: str = typer.Option("")) -> None:
    """Cria fonte:<slug>. Id por slug, não numerado — fonte se cita pelo nome."""


@app.command()
def experimento(titulo: str,
                obj: float = typer.Option(...), gap: float = typer.Option(...),
                segundos: float = typer.Option(...),
                param: list[str] = typer.Option([], help="'p=12', repetível"),
                usa: list[str] = typer.Option([]), por: str = typer.Option(...)) -> None:
    """Cria experimento:E<nn>. Carimba o `commit` lendo `git rev-parse --short HEAD`
    — reconstruir isso depois é impossível, e sem ele o experimento não é
    reprodutível. Recusa se a árvore estiver suja: um experimento carimbado com
    um commit que não contém o código rodado é pior que um sem carimbo."""


@app.command()
def ia(slug: str, titulo: str,
       aceito: str = typer.Option(..., help="integral | parcial | descartado"),
       critica: str = typer.Option(..., help="mínimo 20 caracteres, no schema"),
       por: str = typer.Option(...)) -> None:
    """Cria ia:<data>-<slug>. A data entra no id automaticamente. `--critica` é
    obrigatória aqui e no schema: quem não consegue criticar a resposta não a
    entendeu, e portanto não pode assiná-la (§5.6 do enunciado)."""
```

Depois de escrever, rode o validador. A CLI **não** o chama sozinha, e isso é deliberado: o
ciclo do G00 tem um passo VALIDAR explícito, e esconder a validação dentro de cada comando
faria as pessoas pararem de saber que ela existe.

---

### 5.4 · T01.4 — o servidor MCP read-only

**A regra da tool.** Nenhuma tool expõe SQL como interface principal. Uma tool é uma pergunta
que alguém realmente faz — `bloqueios_abertos()`, `por_que(...)` —, não um canal genérico de
consulta. Três motivos: a pergunta semântica documenta o que o grafo serve para responder; o
resultado vem com forma estável, que o modelo não precisa reinterpretar a cada vez; e a
consulta certa fica escrita uma vez, revisada, em vez de ser reinventada (e errada) em cada
sessão. `consultar_sql` existe como escape hatch para o que ninguém previu — e o fato de ela
existir é justamente o que permite manter as outras estreitas.

**Defesa em três camadas** (`decisao:D08`). Nenhuma delas sozinha basta:

1. `duckdb.connect(caminho, read_only=True)` — o motor recusa `INSERT`.
2. O processo roda com usuário sem permissão de escrita em `governanca/build/`. Se um bug
   abrisse a conexão sem a flag, o sistema de arquivos ainda barra.
3. Nenhuma tool de escrita é declarada. É a camada que importa contra prompt injection: o
   grafo guarda texto de terceiros — referências, transcrições, descrições de fonte — e texto
   lido pelo modelo não pode induzir uma escrita que não existe como capacidade.

E há a razão de fundo, que é a D07: escrita no banco morreria no próximo build. Uma tool de
escrita não seria só arriscada, seria inútil.

```python
#!/usr/bin/env python3
"""
Servidor MCP de leitura sobre o grafo de governança.

Tools semânticas, não SQL cru: a pergunta que alguém faz de verdade vira uma
tool com nome e forma de resultado estáveis. `consultar_sql` fica como escape
hatch — e é a existência dela que permite manter as outras estreitas.

Read-only em três camadas (decisao:D08): read_only=True no connect, processo sem
permissão de escrita em build/, nenhuma tool de escrita declarada.

    uv run python governanca/tools/mcp.py
"""
from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import duckdb
from fastmcp import FastMCP

BANCO = Path(os.environ.get("GRAFO_DB", "governanca/build/grafo.duckdb"))

mcp = FastMCP("grafo-governanca")


def _consultar(sql: str, *params: Any) -> list[dict]:
    """Executa e devolve lista de dicts.

    Abre e fecha a conexão a cada chamada em vez de manter uma global: o banco é
    refeito a cada build, e uma conexão de vida longa continuaria servindo o
    arquivo antigo já apagado — respondendo com o grafo de ontem, sem erro.
    """
    with duckdb.connect(str(BANCO), read_only=True) as con:
        cur = con.execute(sql, list(params))
        colunas = [d[0] for d in cur.description]
        return [dict(zip(colunas, linha)) for linha in cur.fetchall()]


@mcp.tool
def estado_do_projeto() -> dict:
    """Panorama do projeto: kanban, tarefas bloqueadas, pendências abertas e as
    últimas notas. É a primeira chamada de qualquer sessão — responde "onde
    estamos" sem o modelo precisar montar quatro consultas."""
    return {
        "kanban": _consultar("""
            SELECT status, count(*) AS n FROM node
            WHERE kind = 'tarefa' GROUP BY 1 ORDER BY 1"""),
        "bloqueadas": _consultar("""
            SELECT t.id, t.titulo, p.id AS pendencia, p.titulo AS motivo
            FROM edge e
            JOIN node p ON p.id = e.src AND p.kind = 'pendencia' AND p.status = 'aberta'
            JOIN node t ON t.id = e.dst
            WHERE e.rel = 'BLOQUEIA' ORDER BY t.id"""),
        "ultimas_notas": _consultar("""
            SELECT node_id, n.data, n.autor, n.texto FROM nota
            ORDER BY n.data DESC LIMIT 10"""),
    }


@mcp.tool
def por_que(node_id: str, max_saltos: int = 4) -> list[dict]:
    """Sobe a cadeia de justificativa a partir de um nó: por que ele existe, a
    que decisão responde, a que meta serve.

    É a primeira das quatro perguntas do §5.4 do enunciado — "por que o valor do
    tempo adotado é este, e quem decidiu". O GROUP BY com min(salto) existe
    porque o mesmo nó é alcançável por caminhos de comprimentos diferentes, e
    listá-lo duas vezes daria ao leitor a impressão de dois motivos distintos.
    """
    return _consultar("""
        WITH RECURSIVE cadeia(id, salto) AS (
            SELECT ?, 0
          UNION
            SELECT e.dst, c.salto + 1
            FROM cadeia c JOIN edge e ON e.src = c.id
            WHERE c.salto < ?
              AND e.rel IN ('JUSTIFICADA_POR', 'DECIDE_SOBRE', 'REALIZA',
                            'SUBTAREFA_DE', 'ORIGINA_DE', 'SUSTENTA', 'CITA', 'USA')
        )
        SELECT min(c.salto) AS salto, n.id, n.kind, n.titulo
        FROM cadeia c JOIN node n ON n.id = c.id
        WHERE c.salto > 0
        GROUP BY n.id, n.kind, n.titulo
        ORDER BY 1, 2
    """, node_id, max_saltos)


@mcp.tool
def conclusoes_sem_experimento() -> list[dict]:
    """Conclusões do relatório que nenhum experimento sustenta.

    A quarta pergunta do §5.4, e a que se erra com mais facilidade porque a
    resposta é uma AUSÊNCIA: nada aparece na tela quando o grafo está certo, e
    nada aparece também quando ninguém registrou conclusão nenhuma. Vale rodar
    toda semana, não na véspera.
    """
    return _consultar("""
        SELECT c.id, c.titulo, json_extract_string(c.props, '$.secao') AS secao
        FROM node c
        WHERE c.kind = 'conclusao'
          AND NOT EXISTS (
              SELECT 1 FROM edge e JOIN node x ON x.id = e.dst
              WHERE e.src = c.id AND e.rel = 'SUSTENTA' AND x.kind = 'experimento')
          AND NOT EXISTS (
              SELECT 1 FROM edge e JOIN node x ON x.id = e.src
              WHERE e.dst = c.id AND e.rel = 'SUSTENTA' AND x.kind = 'experimento')
        ORDER BY c.id""")
```

As demais, mesmo padrão:

```python
@mcp.tool
def tarefas_de(pessoa: str) -> list[dict]:
    """Tarefas de uma pessoa ('henri', 'pedro', 'antonio'), com status, prazo e
    se estão bloqueadas. Aceita o nome curto e monta `pessoa:<nome>`."""


@mcp.tool
def bloqueios_abertos() -> list[dict]:
    """Pendências em `aberta` e o que cada uma trava. Estado derivado, calculado
    na consulta — nunca lido de uma coluna."""


@mcp.tool
def vizinhanca(node_id: str, saltos: int = 1) -> dict:
    """Sub-grafo a N saltos, ignorando a direção das arestas. Responde a terceira
    pergunta do §5.4: se esta fonte for substituída, o que cai junto. Devolve
    {nos: [...], arestas: [...]} — a mesma forma do graph.json do site."""


@mcp.tool
def buscar(texto: str, limite: int = 20) -> list[dict]:
    """Busca por substring em `titulo` e no JSON de `props`. LIKE, não FTS: com
    50 a 300 nós o índice de texto completo custa mais complexidade do que
    entrega. Se passar de mil nós, troque por FTS e registre a decisão."""


@mcp.tool
def consultar_sql(sql: str) -> list[dict]:
    """Escape hatch para o que as tools acima não cobrem. A conexão é read-only,
    então SELECT é tudo o que passa; qualquer outra coisa levanta erro do próprio
    DuckDB, e é assim que se quer. Quando uma consulta feita por aqui se repetir,
    ela virou uma pergunta de verdade: promova a tool nomeada."""


if __name__ == "__main__":
    mcp.run()
```

**Registro no cliente.** `.mcp.json` na raiz do repositório, commitado — assim os três têm o
mesmo servidor sem configurar nada:

```json
{
  "mcpServers": {
    "grafo": {
      "command": "uv",
      "args": ["run", "python", "governanca/tools/mcp.py"],
      "env": {
        "GRAFO_DB": "governanca/build/grafo.duckdb"
      }
    }
  }
}
```

O transporte é stdio, que é o padrão do `FastMCP.run()` — sem porta, sem rede, sem servidor
para esquecer ligado. Se o banco não existir, o servidor sobe e toda tool falha na primeira
chamada; rode `make build` antes. Vale um passo de sanidade fora do MCP:

```bash
uv run python -c "
import duckdb; con = duckdb.connect('governanca/build/grafo.duckdb', read_only=True)
con.execute(\"INSERT INTO node VALUES ('x','x','x',NULL,NULL,'{}')\")"
# tem que falhar. Se inserir, a camada 1 não está de pé.
```

---

### 5.5 · T01.5 — o gerador de site

**O que sai:**

```
_site/
├── index.html          grafo navegável, autocontido
├── graph.json          os mesmos elementos, separados, para depurar e reusar
├── kanban.html         cinco colunas, bloqueio marcado
├── auditoria.html      as métricas de processo
└── registros/<id>.html uma página por nó
```

`_site/` é gitignored (§6.3 das convenções). Ele existe só entre o build e o upload do
artefato.

#### Por que NetworkX

Duas coisas que SQL não dá bem:

*Métricas.* Grau, intermediação, componentes conexos, nós órfãos. "Quem é o gargalo do grafo"
é betweenness centrality; escrever isso em SQL recursivo seria possível e ilegível.

*Layout pré-calculado.* `spring_layout` com `seed` fixa devolve as mesmas coordenadas a cada
execução. Se o layout rodasse no navegador, o mesmo grafo apareceria diferente a cada visita —
e comparar o site de hoje com a captura de tela da semana passada, que é o que um avaliador
faz, deixaria de significar alguma coisa. A posição vira dado do build, e o Cytoscape recebe
`layout: {name: 'preset'}`.

Use a mesma seed do `_targets.R` (`20260824`) e registre a escolha. Verificado: duas chamadas
com a mesma seed devolvem coordenadas idênticas até a última casa.

#### O formato do `graph.json`

É o formato de elementos do Cytoscape, sem invenção nossa: dois arrays, `nodes` e `edges`, e
cada elemento com um objeto `data` (o que o seletor CSS enxerga) e, nos nós, um `position` em
pixels.

```json
{
  "nodes": [
    {
      "data": {
        "id": "decisao:D06",
        "kind": "decisao",
        "label": "Emular o grafo sobre tabelas relacionais em DuckDB",
        "status": "vigente",
        "grau": 0.0408,
        "url": "registros/decisao_D06.html"
      },
      "position": { "x": -485.7, "y": 231.3 }
    }
  ],
  "edges": [
    {
      "data": {
        "id": "decisao:D06|ASSINADA_POR|pessoa:henri",
        "source": "decisao:D06",
        "target": "pessoa:henri",
        "rel": "ASSINADA_POR"
      }
    }
  ]
}
```

Três detalhes que evitam bug: o `id` da aresta é `src|rel|dst`, porque duas arestas diferentes
entre o mesmo par existem (`REALIZA` e `DEPENDE_DE`) e o Cytoscape exige id único. O `kind` e o
`rel` viram atributo de `data` para o estilo poder selecionar por `node[kind = "decisao"]`. E o
nome do arquivo da página do nó troca `:` por `_`, porque `:` em nome de arquivo quebra em
Windows e em algumas rotas estáticas.

#### O esqueleto

```python
#!/usr/bin/env python3
"""
Gera o site estático do grafo de governança a partir do DuckDB.

O site é o entregável da Camada B: é por ele que o professor lê o processo, e é
o ponto de partida dos encontros de acompanhamento (tarefa:T03). Tudo
autocontido — nenhum CDN, nenhuma fonte remota, nenhum XHR: precisa abrir de um
pen drive, offline, na arguição.

    uv run python governanca/tools/site.py \
        --db governanca/build/grafo.duckdb --out _site/
"""
from __future__ import annotations

import argparse
import html
import json
import subprocess
from collections import Counter
from pathlib import Path
from typing import Any

import duckdb
import networkx as nx

SEED = 20260824          # a mesma do _targets.R; layout determinístico entre builds
VENDOR = Path(__file__).parent / "vendor" / "cytoscape.min.js"

CORES = {"meta": "#7c3aed", "tarefa": "#2563eb", "decisao": "#059669",
         "pendencia": "#dc2626", "fonte": "#d97706", "referencia": "#a16207",
         "experimento": "#0891b2", "arquivo": "#64748b", "conclusao": "#be185d",
         "ia": "#7c2d12", "pessoa": "#334155"}


def carregar_grafo(db: Path) -> tuple[list[tuple], list[tuple], dict[str, dict]]:
    """Lê node e edge do banco. ORDER BY em tudo: build determinístico."""
    with duckdb.connect(str(db), read_only=True) as con:
        nos = con.execute(
            "SELECT id, kind, titulo, status, criado_em, props "
            "FROM node ORDER BY id").fetchall()
        arestas = con.execute(
            "SELECT src, dst, rel FROM edge ORDER BY src, rel, dst").fetchall()
        props = {r[0]: json.loads(r[1]) for r in
                 con.execute("SELECT id, props FROM node").fetchall()}
    return nos, arestas, props


def montar_nx(nos: list[tuple], arestas: list[tuple]) -> nx.DiGraph:
    """Constrói o DiGraph. As arestas já foram validadas contra órfã no build."""
    g = nx.DiGraph()
    for nid, kind, titulo, status, *_ in nos:
        g.add_node(nid, kind=kind, titulo=titulo, status=status)
    for src, dst, rel in arestas:
        g.add_edge(src, dst, rel=rel)
    return g


def metricas(g: nx.DiGraph) -> dict[str, Any]:
    """Métricas estruturais. betweenness no grafo não-dirigido: a pergunta é
    'quem é ponte entre partes do projeto', e a ponte não tem direção."""
    ug = g.to_undirected()
    return {
        "grau": nx.degree_centrality(g),
        "intermediacao": nx.betweenness_centrality(ug),
        "componentes": nx.number_weakly_connected_components(g),
        "orfaos": sorted(n for n in g if g.degree(n) == 0),
    }


def posicoes(g: nx.DiGraph) -> dict[str, tuple[float, float]]:
    """Layout pré-calculado com seed fixa.

    Determinismo é requisito, não conveniência: se o layout rodasse no
    navegador, o mesmo grafo apareceria diferente a cada visita, e comparar o
    site de hoje com a captura da semana passada deixaria de significar algo.
    """
    pos = nx.spring_layout(g, seed=SEED, iterations=200, scale=1200)
    return {n: (round(float(p[0]), 1), round(float(p[1]), 1)) for n, p in pos.items()}


def elementos(nos, met, pos) -> dict:
    """Monta o graph.json no formato de elementos do Cytoscape."""
    return {
        "nodes": [{
            "data": {"id": nid, "kind": kind, "label": titulo, "status": status,
                     "grau": round(met["grau"].get(nid, 0.0), 4),
                     "url": f"registros/{nid.replace(':', '_')}.html"},
            "position": {"x": pos[nid][0], "y": pos[nid][1]},
        } for nid, kind, titulo, status, *_ in nos],
        "edges": [],   # preenchido em main(), onde a lista de arestas está viva
    }


def cadencia_git(repo: Path) -> Counter:
    """Commits por semana ISO, lidos do git.

    Precisa de fetch-depth: 0 no checkout — com histórico raso o gráfico de
    cadência sai truncado e a métrica publicada mente para menos.
    """
    saida = subprocess.run(
        ["git", "-C", str(repo), "log", "--date=format:%G-W%V", "--pretty=%ad"],
        capture_output=True, text=True, check=True).stdout
    return Counter(saida.split())


def escrever_index(saida: Path, els: dict) -> None: ...
def escrever_registros(saida: Path, nos, arestas, props) -> None: ...
def escrever_kanban(saida: Path, nos, arestas) -> None: ...
def escrever_auditoria(saida: Path, db: Path, met: dict, cad: Counter) -> None: ...


def main() -> int:
    p = argparse.ArgumentParser(description="Gera o site do grafo.")
    p.add_argument("--db", type=Path, default=Path("governanca/build/grafo.duckdb"))
    p.add_argument("--out", type=Path, default=Path("_site"))
    p.add_argument("--repo", type=Path, default=Path("."))
    args = p.parse_args()

    nos, arestas, props = carregar_grafo(args.db)
    g = montar_nx(nos, arestas)
    met, pos = metricas(g), posicoes(g)
    els = elementos(nos, met, pos)
    els["edges"] = [{"data": {"id": f"{s}|{r}|{d}", "source": s,
                              "target": d, "rel": r}} for s, d, r in arestas]

    (args.out / "registros").mkdir(parents=True, exist_ok=True)
    (args.out / "graph.json").write_text(
        json.dumps(els, ensure_ascii=False, indent=1), encoding="utf-8")
    escrever_index(args.out, els)
    escrever_registros(args.out, nos, arestas, props)
    escrever_kanban(args.out, nos, arestas)
    escrever_auditoria(args.out, args.db, met, cadencia_git(args.repo))

    print(f"  {args.out}: {len(nos)} páginas de registro, "
          f"{met['componentes']} componente(s), {len(met['orfaos'])} órfão(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

#### Vendorizar o Cytoscape.js

O `index.html` embute o Cytoscape inteiro, não o carrega de CDN. Motivo: o site tem que abrir
offline, e uma dependência de rede é uma dependência que falha na hora da apresentação. Baixe o
pacote `cytoscape` do npm uma vez, copie `dist/cytoscape.min.js` para
`governanca/tools/vendor/cytoscape.min.js` e **commite o arquivo** — ele é dependência, não
artefato de build, e a distinção é o critério do `.gitignore`. Registre um nó `arquivo:` para
ele, com o `sha256`, e a licença (MIT) no `README`.

#### O essencial do `index.html`

Os elementos são embutidos como literal JS, não buscados por `fetch`: `file://` bloqueia XHR, e
o site precisa abrir com duplo clique.

```python
INDEX = """<!doctype html>
<meta charset="utf-8"><title>Grafo de governança — TRA-48 B1</title>
<style>
  :root {{ --fundo:#0f172a; --painel:#1e293b; --texto:#e2e8f0; }}
  * {{ box-sizing:border-box; }}
  body {{ margin:0; background:var(--fundo); color:var(--texto);
         font:14px/1.5 system-ui, sans-serif; display:flex; height:100vh; }}
  #lateral {{ width:300px; padding:16px; background:var(--painel);
              overflow-y:auto; flex:none; }}
  #cy {{ flex:1; }}
  label {{ display:block; margin:4px 0; cursor:pointer; }}
  #detalhe {{ margin-top:16px; border-top:1px solid #334155; padding-top:12px; }}
  a {{ color:#93c5fd; }}
</style>
<div id="lateral">
  <h1 style="font-size:16px">Grafo de governança</h1>
  <div id="filtros"></div>
  <div id="detalhe"><em>clique num nó</em></div>
  <p><a href="kanban.html">kanban</a> · <a href="auditoria.html">auditoria</a></p>
</div>
<div id="cy"></div>
<script>{cytoscape}</script>
<script>
const ELEMENTOS = {elementos};
const CORES = {cores};

const cy = cytoscape({{
  container: document.getElementById('cy'),
  elements: ELEMENTOS,
  // 'preset' usa as posições vindas do NetworkX. Trocar por 'cose' aqui
  // devolveria o não-determinismo que o pré-cálculo existe para eliminar.
  layout: {{ name: 'preset' }},
  style: [
    {{ selector: 'node', style: {{
        'background-color': ele => CORES[ele.data('kind')] || '#64748b',
        'label': 'data(id)', 'color': '#e2e8f0', 'font-size': 9,
        'text-valign': 'bottom', 'text-margin-y': 3,
        // o grau entra no tamanho: o nó central do grafo tem que parecer central
        'width':  ele => 14 + 90 * ele.data('grau'),
        'height': ele => 14 + 90 * ele.data('grau') }} }},
    {{ selector: 'edge', style: {{
        'width': 1, 'line-color': '#475569', 'target-arrow-color': '#475569',
        'target-arrow-shape': 'triangle', 'curve-style': 'bezier',
        'arrow-scale': 0.7 }} }},
    {{ selector: 'edge[rel = "BLOQUEIA"]', style: {{
        'line-color': '#dc2626', 'target-arrow-color': '#dc2626', 'width': 2 }} }},
    {{ selector: '.apagado', style: {{ 'opacity': 0.08 }} }},
    {{ selector: '.foco', style: {{ 'border-width': 3, 'border-color': '#facc15' }} }}
  ]
}});

// filtros por kind
const kinds = [...new Set(ELEMENTOS.nodes.map(n => n.data.kind))].sort();
document.getElementById('filtros').innerHTML = kinds.map(k =>
  `<label><input type="checkbox" checked data-kind="${{k}}">` +
  `<span style="color:${{CORES[k]}}">&#9679;</span> ${{k}}</label>`).join('');
document.getElementById('filtros').addEventListener('change', () => {{
  const ativos = new Set([...document.querySelectorAll('#filtros input:checked')]
                         .map(i => i.dataset.kind));
  cy.nodes().forEach(n => n.style('display',
    ativos.has(n.data('kind')) ? 'element' : 'none'));
}});

// clique: destaca a vizinhança imediata e mostra o registro
cy.on('tap', 'node', e => {{
  const n = e.target;
  cy.elements().addClass('apagado');
  n.closedNeighborhood().removeClass('apagado');
  cy.elements().removeClass('foco'); n.addClass('foco');
  document.getElementById('detalhe').innerHTML =
    `<strong>${{n.data('id')}}</strong><p>${{n.data('label')}}</p>` +
    `<p><a href="${{n.data('url')}}">ver registro completo &rarr;</a></p>`;
}});
cy.on('tap', e => {{ if (e.target === cy) cy.elements().removeClass('apagado foco'); }});
</script>
"""


def escrever_index(saida: Path, els: dict) -> None:
    """Embute o Cytoscape e os elementos no HTML.

    Literal JS em vez de fetch('graph.json') porque file:// bloqueia XHR e o
    site tem que abrir com duplo clique, sem servidor. As chaves do template
    estão duplicadas ({{ }}) por causa do str.format — CSS e JS são cheios de
    chaves, e escapar é mais simples que trocar de motor de template.
    """
    (saida / "index.html").write_text(INDEX.format(
        cytoscape=VENDOR.read_text(encoding="utf-8"),
        elementos=json.dumps(els, ensure_ascii=False),
        cores=json.dumps(CORES)), encoding="utf-8")
```

#### `registros/<id>.html`

Uma página por nó, gerada com `html.escape` em todo texto vindo do YAML. É a página que os
links do relatório apontam, então precisa ter: título, kind, status, datas, o corpo específico
do tipo (justificativa e alternativas para `decisao`; limitações para `fonte`; parâmetros, FO,
gap e segundos para `experimento`; `aceito` e crítica para `ia`), as arestas de entrada e de
saída como links, as notas em ordem cronológica, e o link para o YAML de origem no GitHub —
montado a partir de `props._arquivo`. Esse último link é o que fecha o ciclo: da afirmação
publicada até a linha de texto que a originou e o commit que a introduziu.

#### `auditoria.html`

As métricas de processo. Cada uma existe porque o enunciado a examina:

| Métrica | Consulta | Por que |
| --- | --- | --- |
| Rastreabilidade | % de tarefas que alcançam meta; % de conclusões com experimento; % de decisões com ≥ 1 alternativa; nós órfãos | as quatro perguntas do §5.4 |
| Cadência | nós criados por semana ISO × commits por semana | banco preenchido em bloco na véspera é item explícito do que compromete a nota |
| Higiene | tarefas com prazo vencido e status ≠ `feita`; tarefas em `fazendo` há mais de 7 dias sem nota nova; `revisao` pulada | mostra o kanban que mente |
| Aceite de IA | contagem por `integral`/`parcial`/`descartado` | o enunciado avisa que ~100% integral será examinado na arguição |
| Autoria | registros e commits por pessoa | contribuição individual é considerada |

```sql
-- cadência de registros por semana ISO
SELECT strftime(criado_em, '%G-W%V') AS semana, kind, count(*) AS n
FROM node WHERE criado_em IS NOT NULL
GROUP BY 1, 2 ORDER BY 1, 2;

-- distribuição de aceite de IA
SELECT json_extract_string(props, '$.aceito') AS aceito, count(*) AS n
FROM node WHERE kind = 'ia' GROUP BY 1 ORDER BY 2 DESC;

-- prazo vencido
SELECT id, titulo, json_extract_string(props, '$.prazo') AS prazo, status
FROM node
WHERE kind = 'tarefa' AND status <> 'feita'
  AND CAST(json_extract_string(props, '$.prazo') AS DATE) < current_date
ORDER BY 3;
```

Publique os números como estão, inclusive os ruins. Uma auditoria que só mostra verde não é
auditoria — e o critério de excelência do enunciado inclui literalmente "mostra o que não
funcionou, e por quê".

---

### 5.6 · T01.6 — GitHub Actions

#### Deploy por artefato, não por branch `gh-pages`

O jeito antigo faz o CI commitar o site numa branch. Isso significa **um commit de máquina por
push**, e nós publicamos a cadência de commits como métrica de processo auditada. Metade dos
commits do repositório passariam a ser "deploy: update site" gerados por robô, e o gráfico que
deveria medir o trabalho humano mediria o robô. Corrigir depois exigiria filtrar por autor no
próprio gráfico que se quer honesto — remendo sobre um problema autoinfligido.

Há duas razões menores no mesmo sentido: o site é artefato de build, e `decisao:D07` diz que
artefato de build não entra no git; e o histórico de `gh-pages` seria uma pilha de diffs de
HTML gerado, sem nenhum valor de leitura.

O deploy por artefato não commita nada. O job de build empacota `_site/`, e o job de deploy o
publica. O `id-token: write` existe porque o `deploy-pages` troca um token OIDC do próprio
workflow pelo direito de publicar — nenhum PAT, nenhum segredo guardado.

**Passo manual, uma vez só:** Settings → Pages → Source = **"GitHub Actions"**. Sem isso o
`deploy-pages` falha com erro de configuração, e a mensagem não é óbvia. É a única coisa deste
guia que não dá para automatizar.

`.github/workflows/publicar.yml`:

```yaml
name: publicar

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read        # o mínimo: nada neste workflow escreve no repositório
  pages: write          # publicar no Pages
  id-token: write       # OIDC para o deploy-pages; substitui o PAT

# Um deploy por vez. cancel-in-progress: false de propósito — cancelar um deploy
# no meio pode deixar o Pages num estado intermediário, e o custo de esperar dois
# minutos é menor que o de investigar por que o site sumiu.
concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0        # a métrica de cadência lê `git log`; raso mentiria

      - uses: astral-sh/setup-uv@v9
        with:
          enable-cache: true

      - name: Validar o grafo
        run: |
          uv run python governanca/tools/validar.py \
            governanca/data governanca/schema/grafo.schema.json

      - name: Compilar para DuckDB
        run: |
          uv run python governanca/tools/build.py \
            --src governanca/data \
            --schema governanca/schema/grafo.schema.json \
            --out governanca/build/grafo.duckdb

      - name: Gerar o site
        run: |
          uv run python governanca/tools/site.py \
            --db governanca/build/grafo.duckdb --out _site/

      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v5
        with:
          path: _site/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deploy.outputs.page_url }}
    steps:
      - id: deploy
        uses: actions/deploy-pages@v5
```

#### O workflow de PR: valida e não publica

Separado do de publicação, e required check em `main`. É o que torna a regra executável em vez
de combinada: um PR que quebra uma referência do grafo não é mesclável.

`.github/workflows/validar.yml`:

```yaml
name: validar

on:
  pull_request:
    branches: [main]

permissions:
  contents: read        # só leitura: este workflow não publica nada

concurrency:
  group: validar-${{ github.head_ref }}
  cancel-in-progress: true    # aqui cancelar é certo: só interessa o último push

jobs:
  grafo:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0      # checar_notas_append_only compara com origin/main

      - uses: astral-sh/setup-uv@v9
        with:
          enable-cache: true

      - name: Validar o grafo
        run: |
          uv run python governanca/tools/validar.py \
            governanca/data governanca/schema/grafo.schema.json

      - name: Compilar (o build tem que passar antes do merge)
        run: |
          uv run python governanca/tools/build.py \
            --src governanca/data \
            --schema governanca/schema/grafo.schema.json \
            --out governanca/build/grafo.duckdb

      - name: Recusar artefato commitado
        run: |
          if git ls-files --error-unmatch governanca/build 2>/dev/null; then
            echo "governanca/build/ está no índice do git — regra 1 do CLAUDE.md"
            exit 1
          fi
```

Depois de o workflow rodar uma vez: Settings → Branches → regra em `main` → **Require status
checks to pass** → marque `grafo`. Antes da primeira execução o check nem aparece na lista.

> **Majors conferidas em 24/08/2026**, na página de releases de cada action:
> `checkout@v6`, `setup-uv@v9`, `configure-pages@v5`, `upload-pages-artifact@v5`,
> `deploy-pages@v5`. São essas que estão nos workflows commitados. Reconfira antes de
> qualquer alteração no CI — action desatualizada falha com aviso de depreciação que ninguém
> lê até o dia da entrega.

---

### 5.7 · Os três arquivos de apoio

#### `.gitignore` (raiz)

O critério de cada linha: entra no git o que é fonte, fica de fora o que é derivável.

```gitignore
# --- artefatos de build: deriváveis, nunca commitados (regra 1 do CLAUDE.md)
governanca/build/
_site/
_targets/

# --- pipeline R
app/data/interim/
app/data/raw/*.zip
app/data/raw/*.7z
app/data/raw/*.gpkg
!app/data/raw/README.md
app/outputs/**/*.rds
!app/outputs/.gitkeep

# --- R
.Rproj.user/
.Rhistory
.RData
.Ruserdata
.Renviron
renv/library/
renv/local/
renv/staging/
# renv.lock ENTRA: sem ele "rodar do zero" é falso

# --- Python
__pycache__/
*.py[cod]
.venv/
.uv-cache/
.pytest_cache/
.ruff_cache/
# uv.lock ENTRA: é ele que pina as versões

# --- LaTeX / Quarto do relatório
relatorio/*.aux
relatorio/*.log
relatorio/*.out
relatorio/*.toc
relatorio/*.bbl
relatorio/*.blg
relatorio/*.synctex.gz
relatorio/.quarto/
relatorio/_book/

# --- sistema e editor
.DS_Store
Thumbs.db
.vscode/
.idea/
```

`app/data/raw/` tem exceção explícita para arquivos pequenos e citáveis (§8 do `CLAUDE.md`);
mantenha a lista de exceções curta e um `README.md` na pasta dizendo de onde veio cada base.

#### `pyproject.toml` (raiz)

```toml
[project]
name = "governanca-tra48"
version = "0.1.0"
description = "Ferramentas do grafo de governança do Projeto B1 de TRA-48"
requires-python = ">=3.11"
dependencies = [
    "pyyaml",      # carga dos YAML
    "jsonschema",  # validação contra grafo.schema.json
    "duckdb",      # o banco do grafo
    "networkx",    # métricas e layout pré-calculado
    "numpy",       # networkx NÃO declara numpy, e spring_layout precisa dele
    "fastmcp",     # servidor MCP
    "typer",       # a CLI gov
]

[dependency-groups]
dev = ["pytest", "ruff"]
```

Sem versão fixada aqui de propósito: quem pina é o `uv.lock`, que é commitado. Duas listas de
versões divergem, e a que diverge em silêncio é a que ninguém lê.

`numpy` está explícito porque `networkx` não o declara como dependência e `spring_layout` o
importa em tempo de execução — sem ele o `site.py` morre com `ModuleNotFoundError: numpy` num
ponto que não parece ter nada a ver com numpy. Se o grafo passar de algumas centenas de nós,
acrescente `scipy`, que o NetworkX usa no caminho esparso do layout.

#### `Makefile` (raiz)

```makefile
DATA   := governanca/data
SCHEMA := governanca/schema/grafo.schema.json
DB     := governanca/build/grafo.duckdb
SITE   := _site

.PHONY: validar build site serve limpar tudo
.DEFAULT_GOAL := validar

validar:                       ## checa schema e integridade do grafo
	uv run python governanca/tools/validar.py $(DATA) $(SCHEMA)

build: validar                 ## compila os YAML para DuckDB
	uv run python governanca/tools/build.py --src $(DATA) --schema $(SCHEMA) --out $(DB)

site: build                    ## gera o site estático em _site/
	uv run python governanca/tools/site.py --db $(DB) --out $(SITE)

serve: site                    ## serve o site local em http://localhost:8000
	uv run python -m http.server 8000 --directory $(SITE)

limpar:                        ## apaga os artefatos; nada de valor se perde
	rm -rf governanca/build $(SITE)

tudo: limpar site
```

As dependências entre alvos não são decoração: `site` depender de `build`, e `build` de
`validar`, é o que impede publicar um site gerado de um grafo quebrado. `limpar` existe para
provar a afirmação central da D07 — apagar tudo e rodar `make site` tem que devolver o mesmo
site.

---

## 6. Critério de pronto

Cada item é verificável por comando. Não é "achei que ficou bom".

- [ ] `make limpar && make site` roda do zero, sem erro, num clone novo.
- [ ] `make validar` sai com "Grafo íntegro" e código 0.
- [ ] `build.py` recusa gravar com o grafo quebrado: introduza uma aresta órfã de propósito,
      confirme que o build aborta e que `governanca/build/` continua vazio, desfaça.
- [ ] Dois builds seguidos do mesmo commit produzem o mesmo `graph.json`, byte a byte
      (`make site && cp _site/graph.json /tmp/a && make limpar && make site && diff /tmp/a _site/graph.json`).
- [ ] O validador tem as três verificações novas ligadas em `main()`, e cada uma foi testada
      contra um caso que ela deve pegar: nota editada, conclusão sem experimento, `limitacoes`
      escrito como "n/a".
- [ ] `gov tarefa`, `gov nota` e `gov mv` criam ou alteram YAML que passa no validador.
- [ ] `gov tarefa --pai tarefa:T01` gera `T01.7` e herda `REALIZA meta:M4` do pai.
- [ ] O servidor MCP responde `estado_do_projeto` no cliente configurado por `.mcp.json`.
- [ ] Tentar `INSERT` pela conexão do MCP falha.
- [ ] `_site/index.html` abre por duplo clique, offline, com o grafo desenhado — teste com a
      rede desligada, não "deve funcionar".
- [ ] Existe uma página em `_site/registros/` por nó do grafo, e cada uma linka o YAML de
      origem no GitHub.
- [ ] `_site/auditoria.html` mostra as cinco métricas, inclusive as ruins.
- [ ] O site está publicado no GitHub Pages e a URL está no `README.md`.
- [ ] Um PR que quebra uma referência do grafo tem o merge barrado pelo check `grafo` —
      teste de verdade, com um PR descartável.
- [ ] `git ls-files governanca/build _site` não devolve nada.
- [ ] As seis subtarefas estão em `feita` e `tarefa:T01` também.

---

## 7. Armadilhas conhecidas

**PyYAML converte data sem aspas em `datetime.date`.** YAML 1.1: `criado_em: 2026-08-24` vira
um objeto de data, o `jsonschema` reclama que não é string e o `json.dumps` levanta
`TypeError`. Sintoma: erro de serialização num arquivo que "está claramente certo". A solução
está no `normalizar()`, e ela tem que ser aplicada em `build.py`, em `validar.py` **e** em
qualquer script novo que leia YAML. É a duplicação mais provável de aparecer neste pacote.

**`networkx` não instala `numpy`.** `spring_layout` falha com `ModuleNotFoundError: numpy` num
stack trace que passa por três arquivos de decorator do NetworkX e não menciona layout. Declare
`numpy` no `pyproject.toml`.

**`UNION ALL` em CTE recursiva não termina.** O grafo tem ciclos quando se ignora a direção
(`vizinhanca`, `por_que` com relações mistas). Use `UNION`, sempre, e mantenha o limite de
saltos como guarda.

**O mesmo nó aparece duas vezes com saltos diferentes.** O `UNION` deduplica linhas inteiras,
e `(meta:M4, 1)` é diferente de `(meta:M4, 2)`. Sem `GROUP BY` com `min(salto)`, `por_que`
mostra o mesmo motivo duas vezes e o leitor entende dois motivos.

**A CLI reformata o YAML inteiro na primeira escrita.** `yaml.safe_dump` normaliza tudo:
`{rel: X, dst: Y}` inline vira bloco, aspas somem, blocos `|` mudam de indentação. O primeiro
`gov nota` num arquivo escrito à mão produz um diff enorme que esconde a mudança real. Ou você
aceita um commit único de reformatação de tudo antes de começar a usar a CLI — recomendado —
ou convive com o ruído. Escolha antes, não no meio de um PR.

**Todo `props` é JSON, e `NULL` de JSON não é `NULL` de SQL.** `json_extract` devolve `'null'`
como texto para chave ausente em alguns caminhos. Use `json_extract_string` e compare com
`IS NULL` **e** com `''`, ou você filtra errado sem erro nenhum.

**Deploy do Pages falha até alguém clicar em Settings.** `Source = GitHub Actions` é manual e
uma vez só. A mensagem de erro do `deploy-pages` não diz isso claramente.

**`fetch-depth: 0` importa em dois lugares.** Sem ele, `cadencia_git` mostra menos commits do
que existem — a métrica publicada mente para menos — e `checar_notas_append_only` não acha o
arquivo no commit-base e passa de graça, o que é pior que falhar.

**Required check só aparece depois de rodar uma vez.** A lista de checks em branch protection
é montada do histórico. Rode o workflow num PR descartável antes de tentar exigi-lo.

**Cytoscape exige id único de aresta.** Duas arestas entre o mesmo par existem (`REALIZA` e
`DEPENDE_DE` de uma tarefa para outra). Sem `src|rel|dst`, uma some silenciosamente do desenho
e ninguém percebe, porque o grafo continua bonito.

**`file://` bloqueia `fetch`.** Se o `index.html` buscasse `graph.json`, ele funcionaria em
`make serve` e ficaria em branco no pen drive. Embuta como literal JS.

**`str.format` com CSS e JS.** Chaves de CSS e de template literal precisam ser duplicadas no
template Python. Sintoma: `KeyError: ' box-sizing'`. Se ficar insuportável, troque por
`string.Template`, mas não acrescente um motor de template inteiro por causa disso.

---

## 8. O que registrar

Este pacote é o único do projeto que constrói a própria ferramenta de registro, e por isso é o
mais fácil de terminar sem registro nenhum. Ao fim de cada sessão:

**Decisões** (`decisao:D10`+, com alternativas descartadas):

- Formato da tabela `edge` — aresta como linha com `props JSON`, contra tabela por tipo de
  relação e contra coluna por qualificador.
- Layout pré-calculado com seed fixa contra layout no navegador. A alternativa descartada tem
  motivo específico: não-determinismo entre builds inviabiliza comparar o site com uma captura
  anterior.
- `LIKE` em vez de FTS na busca do MCP, com o limiar em que a decisão se reabre.
- Vendorizar o Cytoscape contra CDN — funcionar offline e não depender de terceiro.
- Deploy por artefato contra branch `gh-pages`, com o argumento da métrica de cadência.
- O limiar de 40 caracteres em `checar_fontes`, contra revisão humana.

**Pendências** (`pendencia:P04`+):

- Confirmar as majors das actions do GitHub. Aponta `BLOQUEIA` para `tarefa:T01.6`.
- Confirmar a licença e a versão do Cytoscape vendorizado, e registrar o `sha256` no nó
  `arquivo:`.

**Arquivos** (`arquivo:`): um nó por ferramenta criada —
`arquivo:governanca-tools-build`, `-validar`, `-gov`, `-mcp`, `-site` — cada um com aresta
`PRODUZ` a partir da subtarefa correspondente e `CITA` para a decisão que o justifica. Sem
isso, a pergunta "qual script gerou o quê" não tem resposta para as próprias ferramentas de
governança, o que seria um constrangimento específico.

**Notas** nas seis subtarefas, no dia em que cada uma foi feita. Uma linha basta, mas tem que
ser no dia — é a data que a métrica de cadência lê.

**Registro de IA** (`ia:2026-08-__-<slug>`): este guia foi escrito com assistência, então
existe um registro a fazer, com `aceito` honesto e crítica específica. Coisas verificáveis que
merecem entrar na crítica: as majors das actions não foram confirmadas contra o marketplace na
data; o limiar de 40 caracteres é arbitrário e não foi calibrado contra nenhuma fonte real; a
escolha de Typer sobre argparse é defensável mas não é a única defensável, e argparse
eliminaria uma dependência.

**Kanban:** mover cada subtarefa para `revisao` ao terminar, nunca direto para `feita`. Quem
move para `feita` é Pedro ou Antônio, depois de conseguir rodar `make site` do zero num clone
limpo. Isso não é formalidade: se um dos dois não consegue rodar, a ferramenta não está pronta,
e a coluna `revisao` existe exatamente para descobrir isso agora e não em 23/09.

---

## 9. Como isso vira relatório

Este pacote não gera nenhum resultado da Camada A — nenhum número, nenhum mapa, nenhuma
conclusão sobre vertiportos. Ele alimenta três coisas.

**A seção de metodologia de processo do relatório de engenharia.** É a seção que descreve como
o grupo conduziu, registrou e auditou o próprio trabalho, e ela é escrita quase inteira a
partir daqui: o modelo de dados do grafo, a razão de a fonte de verdade ser texto versionado, o
mecanismo de validação que barra merge, e as três camadas do acesso read-only da IA. As
decisões `D06`–`D09` mais as registradas neste pacote são as citações dessa seção — nenhuma
frase sobre método precisa ser inventada na véspera, porque cada uma tem um nó com data.

**O apêndice de auditoria, e o link do site.** As métricas de `auditoria.html` entram como
figura e como URL viva. Cadência semanal, distribuição de aceite de IA, rastreabilidade,
higiene do kanban, contribuição por pessoa. O valor delas depende inteiramente de este pacote
ter ficado pronto em 31/08: uma série temporal de cinco semanas é evidência, e a mesma métrica
calculada sobre três dias não é nada.

**As quatro perguntas do §5.4, respondidas ao vivo.** Na arguição, "qual script gerou o mapa da
página 12" e "quais conclusões não têm experimento" se respondem com um clique no grafo e uma
chamada de tool — não com "deixa eu procurar aqui". Isso é o teste real de que a infraestrutura
funcionou, e é a única forma de demonstração que o enunciado aceita como prova de processo.

Vale dizer o que **não** é entregável: o banco não vai no repositório, o `_site/` não vai no
repositório, e nada disso aparece como anexo. O que se entrega é a URL do site publicado, o
código das cinco ferramentas, e os YAML — que são a única coisa que a auditoria realmente lê.
