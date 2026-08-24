# Projeto B1 — Localização de vertiportos em São Paulo

**TRA-48 · Inteligência Analítica: Dados, Modelos e Decisões · ITA · 2026.2**
Henri Leonardo · Pedro Karbage · Antônio Garcia

Modelar e resolver um problema de programação matemática para determinar **onde localizar
vertiportos na cidade de São Paulo**, no contexto da Mobilidade Aérea Urbana. Entrega em
**23/09/2026**.

O projeto tem duas camadas, e as duas são avaliadas: **o que** descobrimos (o modelo de PO) e
**como** conduzimos o trabalho (governança computável, publicada e auditável).

---

## Por onde começar

| Você quer | Leia |
| --- | --- |
| Entender o projeto inteiro | [`docs/00-plano-5-semanas.md`](docs/00-plano-5-semanas.md) |
| Trabalhar em algum pacote | [`docs/guias/G00-como-trabalhar.md`](docs/guias/G00-como-trabalhar.md) |
| Escrever código aqui | [`CLAUDE.md`](CLAUDE.md) e [`docs/referencia/convencoes.md`](docs/referencia/convencoes.md) |
| Entender o grafo de governança | [`docs/04-arquitetura-governanca.md`](docs/04-arquitetura-governanca.md) |
| Ver o estado atual do projeto | o site publicado, ou rodar o validador |

---

## Os guias de execução

Um por pacote de trabalho. Cada um traz objetivo, insumos, passo a passo, critério de pronto,
armadilhas conhecidas e o que precisa ser registrado no grafo.

| Guia | Pacote | Tarefas | Resp. | Prazo |
| --- | --- | --- | --- | --- |
| [G01](docs/guias/G01-infraestrutura.md) | Infraestrutura de governança | T00, T01.1–T01.6 | Henri | 31/08 |
| [G02](docs/guias/G02-dados-od.md) | Pesquisa OD: ler, validar, agregar | T10–T10.3, T11 | Pedro | 30/08 |
| [G03](docs/guias/G03-demanda-capturavel.md) | O filtro de demanda capturável | T12 | Pedro | 02/09 |
| [G04](docs/guias/G04-candidatos.md) | Conjunto de candidatos a vertiporto | T20–T20.3 | Antônio | 02/09 |
| [G05](docs/guias/G05-tempos.md) | Matriz de tempos terrestres e de voo | T13–T13.2 | Antônio | 02/09 |
| [G06](docs/guias/G06-formulacao.md) | A formulação matemática | T21 | Henri | 02/09 |
| [G07](docs/guias/G07-implementacao.md) | Pré-processamento, solver, validação | T22–T25 | Henri · Pedro · Antônio | 09/09 |
| [G08](docs/guias/G08-analises.md) | As quatro análises de PL | T30–T34 | todos | 19/09 |
| [G09](docs/guias/G09-relatorio.md) | Relatório, site, apresentação, arguição | T35, T36 | todos | 23/09 |

Caminho crítico: **G02 → G03 → G06 → G07 → G08 → G09**. G04 e G05 correm em paralelo. G01
vem primeiro porque bloqueia a Camada B inteira.

---

## O modelo, em uma tela

MCLP de fluxo bilateral porta a porta. A unidade de cobertura **não é a zona, é o par
origem-destino** — e um par só é atendido se houver vertiporto na origem **e** no destino.

```
max   Z = Σ_q Σ_(j,k)∈P_q  f_q · Δ_qjk · w_qjk

s.a.  Σ_(j,k)∈P_q w_qjk  ≤  1        ∀q ∈ Q             (α_q)
      w_qjk              ≤  y_j      ∀q, (j,k) ∈ P_q    (μᵒ)
      w_qjk              ≤  y_k      ∀q, (j,k) ∈ P_q    (μᵈ)
      Σ_j y_j            ≤  p                            (π)
```

As **duas** restrições de ligação são o mecanismo de bilateralidade, e são o que distingue
este modelo de um MCLP comum. A previsão que decorre delas — e o resultado central que o
trabalho persegue — é que a curva de implantação vira um **S**: `Z*(1) = 0`, porque um
vertiporto sozinho não serve par algum, e o benefício é superaditivo até a massa crítica.
Um modelo unilateral produz curva côncava desde `p = 1` e nunca revela a primeira metade
dessa resposta.

Formulação completa, com procedência de cada parâmetro e razão de existir de cada restrição,
em [`docs/guias/G06-formulacao.md`](docs/guias/G06-formulacao.md).

---

## Estrutura

```
governanca/     A Camada B — o grafo. YAML é a fonte de verdade; o banco é artefato de build
app/            A Camada A — pipeline em R com targets, funções puras em R/
docs/           Guias de execução, material de estudo, convenções
relatorio/      O relatório de engenharia
```

---

## Rodar

```bash
# validar o grafo de governança
uv run python governanca/tools/validar.py governanca/data governanca/schema/grafo.schema.json

# compilar o grafo e gerar o site
uv run python governanca/tools/build.py --src governanca/data --out governanca/build/grafo.duckdb
uv run python governanca/tools/site.py  --db  governanca/build/grafo.duckdb --out _site/

# pipeline de análise
Rscript -e 'targets::tar_make()'
Rscript -e 'targets::tar_visnetwork()'
```

---

## A regra que organiza tudo

> **O que não estiver no banco, não aconteceu.**

A nota de processo é lida do grafo, com carimbo de data e vínculo com os commits — não se
reconstrói na véspera. Nenhuma sessão de trabalho termina sem registro: decisões com
alternativas descartadas, fontes com limitações conhecidas, experimentos com hipótese e
conclusão, e interações com IA **com crítica humana**.

O detalhe do método está em [`docs/guias/G00-como-trabalhar.md`](docs/guias/G00-como-trabalhar.md).
