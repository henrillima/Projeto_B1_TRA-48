# Projeto B1 — TRA-48 · Localização de vertiportos em São Paulo

Instruções de projeto. Leia isto inteiro antes de tocar em qualquer arquivo.

---

## 1. O que é este repositório

Projeto de Pesquisa Operacional da disciplina **TRA-48 — Inteligência Analítica: Dados,
Modelos e Decisões** (ITA, 8º semestre, 2026.2). Professores: **Marcelo Xavier Guterres** e
**Mayara Condé Rocha Murça**.

O problema: **onde localizar vertiportos na cidade de São Paulo**, no contexto de Mobilidade
Aérea Urbana (eVTOL). Entrega em **23/09/2026**.

O grupo tem três integrantes:

| Pessoa | id no grafo | Frente |
| --- | --- | --- |
| Henri Leonardo | `pessoa:henri` | Modelo, solver, infraestrutura de governança |
| Pedro Karbage | `pessoa:pedro` | Dados: Pesquisa OD, demanda capturável, validação |
| Antônio Garcia | `pessoa:antonio` | Candidatos, GIS, sensibilidade |

---

## 2. Duas camadas, e as duas são avaliadas

Este é o ponto que muda como se trabalha aqui. O enunciado avalia separadamente **o que**
descobrimos e **como** conduzimos o trabalho.

| Camada | O que é | Peso |
| --- | --- | --- |
| **A — substantiva** | O modelo de PO: onde ficam os vertiportos, quanta demanda capturam | 55% |
| **B — metodológica** | Como o grupo conduziu, registrou e auditou o próprio trabalho | 25% |
| Comunicação | Relatório, apresentação, site publicado, arguição | 20% |

A regra fundamental do enunciado, e ela é literal:

> **O que não estiver no banco, não aconteceu.**

A nota de processo é **lida do banco de governança**, com carimbo de data e vínculo com os
commits. Banco preenchido em bloco na semana da entrega é item explícito da lista "o que
compromete a nota". Cadência — decisões e commits por semana — é métrica auditada e publicada.

**Consequência operacional para você, Claude:** nenhuma sessão de trabalho termina sem
registro no grafo. Ver §6.

---

## 3. Layout do repositório

```
.
├── CLAUDE.md                    ← este arquivo
├── README.md                    ← porta de entrada humana
│
├── governanca/                  ← A CAMADA B
│   ├── data/                    ← FONTE DE VERDADE. Um YAML por nó do grafo.
│   │   ├── metas/               M1..M4
│   │   ├── tarefas/             T00..T36, com subtarefas T01.1 etc.
│   │   ├── decisoes/            D01..Dnn
│   │   ├── pendencias/          P01..Pnn
│   │   ├── fontes/              fontes de dados catalogadas
│   │   ├── referencias/         artigos e normas
│   │   ├── experimentos/        cada rodada do modelo
│   │   ├── arquivos/            scripts, mapas, bases derivadas
│   │   ├── conclusoes/          afirmações do relatório
│   │   ├── interacoes/          log append-only de sessões de IA
│   │   └── pessoas/             henri, pedro, antonio
│   ├── schema/grafo.schema.json ← validação
│   ├── tools/                   ← validar.py, build.py, mcp.py, site.py
│   └── build/                   ← ARTEFATO. gitignored. Nunca commitar.
│
├── app/                         ← A CAMADA A
│   ├── R/                       funções puras, uma responsabilidade cada
│   ├── _targets.R               definição do pipeline
│   ├── data/raw/                dados baixados, imutáveis, gitignored se grandes
│   ├── data/interim/            intermediários, gitignored
│   ├── outputs/                 resultados: rds, csv, png
│   └── py/                      só o que não faz sentido em R
│
├── docs/                        ← guias e material de estudo
│   ├── guias/                   G00..G09 — um por pacote de trabalho
│   └── referencia/              convenções, checklist, glossário
│
├── relatorio/                   ← LaTeX / Quarto do relatório de engenharia
└── .github/workflows/           ← CI e publicação no GitHub Pages
```

---

## 4. Stack e decisões já tomadas

Não reabra estas sem registrar uma decisão que supersede a anterior.

| Camada | Escolha | Decisão registrada |
| --- | --- | --- |
| Linguagem da análise | **R** (padrão da disciplina) | — |
| Solver | **HiGHS** via `ompr` + `ompr.roi` + `ROI.plugin.highs` | — |
| Geoprocessamento | **`sf`**, EPSG:31983 (SIRGAS 2000 / UTM 23S) | — |
| Pipeline | **`targets`** — o grafo de proveniência sai de graça | — |
| Ambiente R | **`renv`** | — |
| Ferramentas de governança | **Python** com **`uv`** | — |
| Banco do grafo | **DuckDB**, grafo emulado em `node` + `edge` | `decisao:D06` |
| Fonte de verdade | **YAML por entidade**, banco é artefato de build | `decisao:D07` |
| Acesso da IA | **MCP read-only**; escrita só por CLI e commit | `decisao:D08` |
| Recuperação | SQL recursivo + FTS. **GraphRAG descartado** | `decisao:D09` |

**Formulação escolhida:** MCLP de fluxo bilateral porta-a-porta. A unidade de cobertura é o
**par origem-destino**, atendido apenas se houver vertiporto na origem **e** no destino.
Detalhes em `docs/guias/G06-formulacao.md`.

---

## 5. Regras invioláveis

Estas não são preferências de estilo. Cada uma corresponde a um item da lista "o que
compromete a nota" ou a uma decisão registrada.

1. **Nunca commite `governanca/build/` nem `app/data/interim/`.** O banco é artefato de
   build, como um `.o`. A única fonte de verdade é o texto em `governanca/data/`.

2. **Nunca escreva direto no `.duckdb`.** Escrever no grafo é editar YAML e commitar. Se você
   escrevesse no banco, a escrita morreria no próximo build — e mudança sem commit é mudança
   sem proveniência, que é exatamente o que o banco existe para impedir.

3. **Nunca invente um dado.** Se um número não tem fonte rastreável, ele não entra. "Dados
   inventados ou não rastreáveis à fonte" é o primeiro item da lista do que compromete a nota.
   Quando não souber, escreva `[A CONFIRMAR]` e abra uma pendência.

4. **Nunca invente uma referência.** Autor, ano, periódico e DOI precisam ter sido vistos. Se
   só o metadado foi confirmado e o texto integral não foi lido, isso precisa estar dito — não
   se cita a formulação matemática de um artigo que ninguém abriu.

5. **Toda tarefa se vincula a uma meta.** O validador falha se alguma não vincular. Tarefa que
   não serve a meta nenhuma é trabalho que ninguém pediu.

6. **Estado derivável nunca se armazena.** "Bloqueada" não é coluna do kanban — é dedutível de
   uma pendência aberta apontando para a tarefa. Duas fontes de verdade divergem, sempre.

7. **Notas são append-only.** Nunca edite nem apague uma nota antiga em um YAML; acrescente
   outra. Uma nota corrigida em silêncio perde a única coisa que a tornava valiosa: ter sido
   escrita naquele dia.

8. **Parâmetros de modelagem entram como parâmetros, nunca como constantes literais.** Os
   limiares `t̄` e `θ` viram a análise de sensibilidade. Número mágico no meio do código é um
   experimento que não vai poder ser rodado.

---

## 6. O ciclo de trabalho

Toda sessão, sem exceção, segue este ciclo. O detalhe está em `docs/guias/G00-como-trabalhar.md`.

```
1. ABRIR      Ler o guia do pacote de trabalho em docs/guias/
              Consultar o grafo: o que está fazendo, o que está bloqueado
2. TRABALHAR  Executar. Mover a tarefa para `fazendo` ao começar.
3. REGISTRAR  Decisões tomadas, fontes usadas, experimentos rodados,
              esta interação de IA COM CRÍTICA, notas nas tarefas tocadas
4. VALIDAR    uv run python governanca/tools/validar.py \
                governanca/data governanca/schema/grafo.schema.json
5. COMMITAR   git add -A && git commit -m "..."   ← mensagem cita o que mudou no grafo
```

### O registro de IA é obrigatório e precisa de crítica

O enunciado é explícito: *"não se registra uma interação sem crítica. Quem não consegue
criticar a resposta não a entendeu, e portanto não pode assiná-la."* E: *"a taxa de aceite
integral das sugestões é uma métrica exibida no site. Uma taxa próxima de 100% não é sinal de
eficiência; é sinal de ausência de revisão, e será examinada na arguição."*

**Claude: ao fim de cada sessão substantiva, escreva você mesmo o rascunho do registro de
interação — incluindo a autocrítica.** Aponte o que na sua própria resposta foi estimativa e
não medição, o que foi confirmado só em metadado, e onde uma escolha diferente seria
defensável. Um humano revisa, corrige e commita. Registro com `aceito: integral` e crítica
vazia não passa no validador.

### Mensagens de commit

Formato: um verbo no imperativo, o que mudou, e os ids do grafo tocados.

```
Implementar o compilador YAML->DuckDB (T01.1)

Registra decisao:D10 sobre o formato da tabela edge.
Fecha pendencia:P04.
```

---

## 7. Comandos

```bash
# validar o grafo (roda sempre antes de commitar)
uv run python governanca/tools/validar.py governanca/data governanca/schema/grafo.schema.json

# compilar o grafo para DuckDB
uv run python governanca/tools/build.py --src governanca/data --out governanca/build/grafo.duckdb

# gerar o site
uv run python governanca/tools/site.py --db governanca/build/grafo.duckdb --out _site/

# pipeline de análise (R)
Rscript -e 'targets::tar_make()'
Rscript -e 'targets::tar_visnetwork()'    # ver o grafo de dependências
Rscript -e 'targets::tar_outdated()'      # o que está desatualizado
```

---

## 8. Convenções de código

Detalhe completo em `docs/referencia/convencoes.md`. O essencial:

- **R:** funções puras em `app/R/`, uma responsabilidade por arquivo, `snake_case`, nomes em
  português. Nada de `setwd()`, nada de caminho absoluto. Todo script começa com o cabeçalho
  de proveniência (`@produz` / `@consome`).
- **Python:** só ferramentas de governança. `uv` para dependências, type hints, docstring em
  português explicando *por que*, não *o que*.
- **Nunca** commitar dados brutos grandes. `app/data/raw/` tem `.gitignore` com exceções
  explícitas para arquivos pequenos e citáveis.
- **Seed fixa** em qualquer coisa estocástica, declarada no `_targets.R`.

---

## 9. Onde encontrar o quê

| Preciso de | Está em |
| --- | --- |
| O plano das cinco semanas | `docs/00-plano-5-semanas.md` |
| Modelos de localização, referências com DOI | `docs/01-revisao-literatura.md` |
| URLs e limitações das fontes de dados | `docs/02-fontes-de-dados.md` |
| O que levar ao encontro com o professor | `docs/03-encontro-26-08.md` |
| Como funciona o grafo de governança | `docs/04-arquitetura-governanca.md` |
| Como conduzir uma sessão de trabalho | `docs/guias/G00-como-trabalhar.md` |
| O passo a passo de um pacote de trabalho | `docs/guias/G01..G09` |
| Convenções de código | `docs/referencia/convencoes.md` |
| O que conferir antes de entregar | `docs/referencia/checklist-entrega.md` |
| O estado atual do projeto | o grafo: `governanca/data/`, ou o site publicado |

---

## 10. Marcos

| Data | Marco | Registro esperado |
| --- | --- | --- |
| 19/08 | Grupos formados, repositório no ar | metas e primeiras tarefas — **venceu** |
| 26/08 | 1º encontro: problema, recorte, literatura | decisão do recorte; fontes registradas |
| 02/09 | Demanda capturável, candidatos, formulação escrita | decisões das hipóteses |
| 09/09 | 2º encontro: modelo rodando, primeiro resultado | experimentos registrados |
| 16/09 | **Prova B1**; modelo congelado; sensibilidade e dual | experimentos e conclusões validadas |
| 23/09 | Apresentação, relatório, repositório | trilha completa e auditoria limpa |

---

## 11. Coisas que este projeto não vai fazer

Registradas como descartadas, com justificativa, porque escrever *por que não* vale mais nota
que uma implementação malfeita:

- **GraphRAG** — resolve a etapa de construir o grafo a partir de texto, que nós já resolvemos
  por curadoria. `decisao:D09`.
- **Banco de grafo nativo** (Neo4j, LadybugDB) — incompatível com fonte de verdade em git, ou
  imaturo demais. `decisao:D06`.
- **Code Property Graph / Joern / SCIP / CodeQL** — sem suporte a R, e resolvem "como o código
  está organizado", que com 30 arquivos ninguém precisa. O que precisamos é proveniência de
  artefatos, e `targets` entrega isso.
- **Logit calibrado de escolha modal** como entrega principal — não existe logit calibrado para
  UAM no Brasil. Fica como extensão opcional e como cenário de sensibilidade.
