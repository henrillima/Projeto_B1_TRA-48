# Convenções de código e de repositório

Referência normativa. Todos os guias em `docs/guias/` assumem estas convenções. Divergir
delas é permitido, mas exige registrar uma decisão.

---

## 1. Princípio geral

Otimizamos para **auditabilidade**, não para elegância. Um trecho de código que qualquer um
dos três consegue explicar na arguição vale mais que um trecho de código curto. O critério
de excelência do enunciado diz literalmente que cada integrante deve ser capaz de defender
qualquer linha do modelo, do código e do relatório, independentemente de quem ou o que a
escreveu.

Na dúvida entre duas formas, escolha a que é mais fácil de justificar em voz alta.

---

## 2. R — a linguagem da análise

### 2.1 Estrutura

Todo código de análise vive em `app/`. Funções puras em `app/R/`, orquestração em
`_targets.R`. **Não existe script solto que se roda à mão** — se algo precisa ser executado,
é um alvo do pipeline.

```
app/
├── _targets.R              a definição do pipeline: o único lugar com orquestração
├── R/
│   ├── ler_od.R            uma responsabilidade por arquivo
│   ├── agregar_zonas.R
│   ├── filtrar_captura.R
│   ├── construir_candidatos.R
│   ├── matriz_tempos.R
│   ├── montar_modelo.R
│   ├── resolver.R
│   └── plotar_*.R
├── data/raw/               baixado, imutável, nunca editado à mão
├── data/interim/           gerado, gitignored
└── outputs/                resultados finais: rds, csv, png
```

### 2.2 Funções

Uma função faz uma coisa. Recebe dados e parâmetros, devolve dados. **Não lê arquivo, não
escreve arquivo, não imprime** — quem faz isso é o `targets`. Isso é o que torna as funções
testáveis e o pipeline rastreável.

```r
#' Filtra a matriz OD para os pares plausivelmente capturáveis por UAM.
#'
#' A fração capturável é a primeira decisão difícil do projeto e o enunciado
#' deliberadamente não sugere critérios (§3.3). Os quatro limiares abaixo são
#' a decisão do grupo, registrada em decisao:D03 — e são parâmetros, não
#' constantes, porque viram a análise de sensibilidade.
#'
#' @param od data frame no nível viagem, já expandido por FE_viagem
#' @param dist_min_km distância mínima em linha reta. Ver decisao:D03
#' @param dur_min_min duração terrestre declarada mínima, em minutos
#' @param motivos vetor de motivos aceitos
#' @param faixas_renda vetor de faixas de renda aceitas
#' @return data frame com colunas zona_o, zona_d, viagens_dia
filtrar_captura <- function(od,
                            dist_min_km  = 15,
                            dur_min_min  = 45,
                            motivos      = c("trabalho", "negocios"),
                            faixas_renda = c(4, 5)) {
  stopifnot(is.data.frame(od), dist_min_km > 0)
  ...
}
```

Regras:

- **Nomes em português**, `snake_case`. O relatório é em português; código em inglês obriga
  tradução mental na hora de explicar.
- **`stopifnot()` no topo** de toda função pública. Falhar cedo e alto é melhor que produzir
  um resultado silenciosamente errado — e num modelo de otimização, resultado errado é
  plausível e ninguém percebe.
- **Documentação em roxygen** com `@param` e `@return`. O campo mais importante não é nenhum
  dos dois: é a frase que explica **por que** a função existe e a qual decisão do grafo ela
  responde.
- **Sem efeito colateral.** Nada de `setwd()`, `rm(list=ls())`, `install.packages()` dentro de
  função, ou caminho absoluto. Caminhos vêm do `targets`.
- **`seed` explícita** em qualquer coisa estocástica, declarada no alvo.

### 2.3 Cabeçalho de proveniência

Todo arquivo em `app/R/` começa com:

```r
# @produz    outputs/od_filtrada.rds
# @consome   data/interim/od_agregada.rds
# @decisao   decisao:D03
# @tarefa    tarefa:T12
```

Isso é redundante com o `targets` de propósito. O `targets` sabe as dependências reais de
execução; o cabeçalho diz a **intenção** e amarra ao grafo de governança. O compilador do
grafo lê esses cabeçalhos para criar os nós `arquivo` e as arestas `PRODUZ`.

### 2.4 Pipeline com `targets`

O `_targets.R` é a única fonte de orquestração. Cada alvo é um substantivo, não um verbo —
representa um **dado**, não uma ação.

```r
library(targets)
tar_option_set(packages = c("dplyr", "sf", "ompr", "ompr.roi", "ROI.plugin.highs"),
               seed = 20260824)
tar_source("R")

list(
  tar_target(od_bruta,      ler_od("data/raw/OD-2017.zip"), format = "rds"),
  tar_target(od_expandida,  expandir(od_bruta)),
  tar_target(macrozonas,    agregar_zonas(od_expandida, n_alvo = 120)),
  tar_target(od_capturavel, filtrar_captura(macrozonas)),
  ...
)
```

Por que isso importa para a nota: `tar_network()` devolve `vertices` e `edges` como data
frames — **o grafo de proveniência derivado da execução real**, não de comentários que
envelhecem. É o que responde "qual script gerou o mapa da página 12" sem ninguém precisar
manter isso à mão.

E `tar_outdated()` diz qual figura do relatório foi gerada por código que já mudou desde
então. Conclusão apoiada em resultado obsoleto é exatamente o defeito que a Camada B existe
para pegar.

### 2.5 Ambiente

`renv` sempre. `renv::snapshot()` a cada dependência nova, e o `renv.lock` é commitado. Sem
isso, "qualquer pessoa deve conseguir rodar o projeto do zero" é falso, e essa frase é
exigência textual do enunciado.

---

## 3. Python — só ferramentas de governança

Python não toca a análise. Ele existe aqui para o compilador do grafo, o validador, o servidor
MCP e o gerador do site.

- **`uv`** para tudo. `uv run python ...`, dependências no `pyproject.toml`.
- **Type hints** em toda assinatura pública.
- **Docstring em português** explicando por que a função existe.
- **Sem framework.** O compilador é ~200 linhas de Python puro lendo YAML e escrevendo DuckDB.
  Se ficar maior que isso, alguma coisa foi longe demais.

---

## 4. Nomes e identificadores

### 4.1 Ids do grafo

Formato: `<kind>:<código>`. O prefixo **tem** que bater com o `kind` — o validador falha se
não bater.

| Tipo | Padrão | Exemplo |
| --- | --- | --- |
| meta | `meta:M<n>` | `meta:M2` |
| tarefa | `tarefa:T<nn>` ou `tarefa:T<nn>.<n>` | `tarefa:T12`, `tarefa:T01.3` |
| decisão | `decisao:D<nn>` | `decisao:D07` |
| pendência | `pendencia:P<nn>` | `pendencia:P01` |
| fonte | `fonte:<slug>` | `fonte:od2017` |
| referência | `referencia:<autor><ano>` | `referencia:rath2022` |
| experimento | `experimento:E<nn>` | `experimento:E07` |
| arquivo | `arquivo:<caminho-com-hifens>` | `arquivo:app-R-montar-modelo` |
| conclusão | `conclusao:C<nn>` | `conclusao:C04` |
| interação IA | `ia:<data>-<slug>` | `ia:2026-08-24-esquema-grafo` |

**Ids nunca mudam depois de criados.** Outros nós apontam para eles. Se uma decisão fica
errada, ela não é apagada — cria-se outra que a `SUPERSEDE`.

### 4.2 Numeração das tarefas

A dezena indica a meta:

| Faixa | Meta |
| --- | --- |
| T00–T09 | M4 — governança e rastreabilidade |
| T10–T19 | M1 — demanda capturável |
| T20–T29 | M2 — modelo |
| T30–T39 | M3 — análises e recomendação |

Subtarefa é `T<pai>.<n>`, com aresta `SUBTAREFA_DE`. **Subtarefa não é um tipo diferente** —
é uma `tarefa` com um pai. Isso evita duplicar toda a lógica de kanban e atribuição.

### 4.3 Arquivos

- Guias: `docs/guias/G<nn>-<slug>.md`
- Documentos de contexto: `docs/<nn>-<slug>.md`
- Saídas: `outputs/<o-que-e>_<variante>.<ext>`, sem data no nome — a data está no git
- Figuras do relatório: `outputs/fig/<secao>_<slug>.png`

---

## 5. Kanban

Cinco estados armazenados na propriedade `status` da tarefa:

| Estado | Significa |
| --- | --- |
| `backlog` | Identificada, não começou |
| `pronta` | Dependências satisfeitas, pode começar |
| `fazendo` | Em execução agora |
| `revisao` | Feita, esperando outro integrante conferir |
| `feita` | Aceita |

**Não existe `bloqueada`.** É estado derivado: a tarefa está bloqueada se alguma pendência
aberta aponta para ela via `BLOQUEIA`. Ver regra 6 do `CLAUDE.md`.

A coluna `revisao` é deliberada e não deve ser pulada. Ela força que cada entrega passe pelos
olhos de outra pessoa, o que ataca diretamente o item "integrante que não sabe explicar o
próprio modelo" da lista do que compromete a nota.

**Só o responsável move o próprio cartão** — exceto de `revisao` para `feita`, que quem move
é o revisor.

---

## 6. Git

### 6.1 Branches

`main` protegida: o job de validação precisa passar antes do merge. Trabalho em branch
`<inicial>/<tarefa>-<slug>`:

```
h/T01.1-compilador-grafo
p/T10-ler-od
a/T20.1-helipontos-anac
```

### 6.2 Commits

Um commit é uma unidade semântica. Verbo no imperativo, o que mudou, e os ids do grafo
tocados no corpo.

```
Implementar o filtro de demanda capturável (T12)

Quatro camadas: distância, duração terrestre, motivo e renda.
Os limiares entram como parâmetros — viram a sensibilidade da S3.

Registra decisao:D03 com as três alternativas descartadas.
Fecha pendencia:P01.
```

**Commits pequenos e frequentes.** Cadência é métrica auditada, e um commit gigante na véspera
é visível no gráfico. Mas não inflem artificialmente: commit vazio ou de ruído é pior que
nenhum, porque distorce a métrica que se quer medir com honestidade.

### 6.3 O que nunca entra no git

```
governanca/build/          o banco é artefato
app/data/interim/          intermediários do pipeline
app/data/raw/*.zip         dados brutos grandes
_targets/                  o store do targets
_site/                     saída do gerador
.Rproj.user/ .Renviron
renv/library/
```

`renv.lock` **entra**. `_targets.R` **entra**. `governanca/data/**.yaml` **entra**.

---

## 7. O YAML do grafo

Um arquivo por nó, em `governanca/data/<tipo>/<código>.yaml`.

```yaml
id: tarefa:T12
kind: tarefa
titulo: "Definir e aplicar o filtro de demanda capturável"
status: backlog
prazo: 2026-09-02
prioridade: alta
estimativa_h: 8
criado_em: 2026-08-24
arestas:
  - {rel: REALIZA,     dst: "meta:M1"}
  - {rel: ATRIBUIDA_A, dst: "pessoa:pedro"}
  - {rel: DEPENDE_DE,  dst: "tarefa:T11"}
notas:
  - data: 2026-08-24
    autor: pedro
    texto: "Quatro camadas: distância, duração, motivo, renda."
```

Regras:

- **Toda aresta é declarada uma vez só, no arquivo do nó de origem** — e sempre do lado que
  muda. Por isso `ATRIBUIDA_A` vai de tarefa para pessoa, não o contrário: assim o arquivo da
  pessoa fica estável e nunca vira ponto de conflito de merge.
- **Datas podem ir sem aspas.** O carregador normaliza `datetime.date` para string. (YAML 1.1
  converte `2026-08-24` sem aspas em objeto de data, e o `jsonschema` reclamaria — a regra de
  formato pertence ao carregador, não à disciplina de quem escreve.)
- **`rel` é enum fechado.** Erro de digitação em `rel` viraria uma aresta fantasma que o grafo
  aceita e ninguém encontra. O schema barra.
- **Notas são append-only.** Ver regra 7 do `CLAUDE.md`.

---

## 8. Registro de decisão

O enunciado exige justificativa **e alternativas descartadas**. O validador torna
`alternativas_descartadas` obrigatório em `decisao`.

Uma decisão boa responde três coisas: **o que foi decidido**, **por que**, e **o que foi
considerado e rejeitado, com o motivo específico da rejeição**. "Não usamos X porque Y é
melhor" não é motivo. "Não usamos X porque o repositório foi arquivado em out/2025" é.

```yaml
id: decisao:D06
kind: decisao
titulo: "Emular o grafo sobre tabelas relacionais em DuckDB"
status: vigente
criado_em: 2026-08-24
descricao: |
  Duas tabelas, node e edge, consultadas com SQL e WITH RECURSIVE. [...]
alternativas_descartadas:
  - opcao: "Kùzu (property graph embarcado)"
    por_que_nao: "Repositório arquivado em 10/10/2025; empresa adquirida pela Apple."
  - opcao: "Neo4j Community"
    por_que_nao: "Modelo servidor, incompatível com fonte de verdade em git."
arestas:
  - {rel: DECIDE_SOBRE, dst: "meta:M4"}
  - {rel: ASSINADA_POR, dst: "pessoa:henri"}
```

---

## 9. Registro de experimento

Cada rodada do modelo é um nó. Sem isto, "o desempenho computacional: valor da função
objetivo, tamanho da instância e tempo de solução" — indicador comum exigido a todos os
grupos — vira reconstrução de memória na véspera.

```yaml
id: experimento:E07
kind: experimento
titulo: "P1 bilateral, p=12, t̄=20min, θ=15min"
criado_em: 2026-09-08
commit: a3f9c21
parametros: {p: 12, t_barra_min: 20, theta_min: 15, vot_brl_h: 90}
obj: 184320.5
gap: 0.0
segundos: 41.2
descricao: |
  Hipótese: com t̄ folgado a solução migra para a periferia.
  Conclusão: não migrou — o gargalo é θ, não o acesso.
arestas:
  - {rel: USA,          dst: "fonte:od2017"}
  - {rel: EXECUTA,      dst: "arquivo:app-R-resolver"}
  - {rel: ASSINADA_POR, dst: "pessoa:henri"}
```

O campo `descricao` tem que trazer **hipótese e conclusão**, não só números. Um experimento
sem hipótese é uma rodada; um experimento com hipótese é ciência.

---

## 10. Registro de interação com IA

```yaml
id: ia:2026-08-24-esquema-grafo
kind: ia
titulo: "Desenho do esquema do grafo de governança"
criado_em: 2026-08-24
aceito: parcial
critica_humana: |
  O esquema proposto tem 11 tipos de nó, mas a própria regra do documento diz
  que nó sem consulta é decoração — e `referencia` e `conclusao` não tinham
  consulta escrita. Cortamos nenhum, mas escrevemos as consultas.
  As estimativas de tamanho da instância foram apresentadas como se fossem
  medições; são chute de ordem de grandeza. Vamos medir na S2.
arestas:
  - {rel: ASSINADA_POR, dst: "pessoa:henri"}
```

`critica_humana` tem mínimo de 20 caracteres no schema, mas o mínimo real é ter conteúdo.
"Boa resposta" não é crítica. A crítica útil aponta **uma coisa específica** que estava
errada, incompleta ou discutível.

Distribuição saudável ao longo do bimestre: alguns `integral`, muitos `parcial`, alguns
`descartado`. Tudo `integral` será examinado na arguição, e a leitura será a óbvia.

---

## 11. Antes de abrir um pull request

```bash
uv run python governanca/tools/validar.py governanca/data governanca/schema/grafo.schema.json
Rscript -e 'targets::tar_make()'
Rscript -e 'targets::tar_outdated()'    # tem que sair vazio
```

E confira, no diff:

- [ ] Nenhum arquivo de `build/`, `_targets/` ou `data/interim/`
- [ ] Todo número novo no texto tem fonte rastreável
- [ ] Toda decisão nova tem alternativas descartadas
- [ ] A tarefa correspondente mudou de estado no kanban
- [ ] Se houve sessão de IA, existe registro com crítica não-vazia
