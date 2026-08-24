# G02 — Pesquisa OD: ler, validar, agregar

> **Pacote de trabalho de Pedro Karbage.** Prazo: **30/08/2026**.
> Leia o `G00-como-trabalhar.md` antes deste. Este guia é roteiro de execução, não relatório
> do que já foi feito — quando ele estiver errado, corrija-o no mesmo commit.

---

## 1. Objetivo

Ao fim deste pacote existe, em `app/outputs/`, uma **matriz origem-destino de viagens diárias
entre macrozonas do município de São Paulo**, expandida pelos fatores amostrais corretos,
projetada em EPSG:31983, calibrada pelo nível de 2023 e com um teste de validação que reproduz
os totais publicados pelo Metrô. É o insumo único de tudo que vem depois: sem ela o G03 não tem
o que filtrar e o G07 não tem o que otimizar.

O que se entrega não é só o dado. É o dado **com a prova de que ele está certo** — o passo 5.7
é a parte não negociável deste guia.

---

## 2. Tarefas no grafo

| Id | Título | Prazo | Depende de |
| --- | --- | --- | --- |
| `tarefa:T10` | Obter, ler e validar a Pesquisa Origem-Destino | 28/08 | — |
| `tarefa:T10.1` | Baixar `OD-2017.zip` e extrair o layout de variáveis | 25/08 | — |
| `tarefa:T10.2` | Verificar se os anexos da OD 2023 contêm microdados | 26/08 | — |
| `tarefa:T10.3` | Validar os fatores de expansão contra o relatório-síntese | 28/08 | `tarefa:T10.1` |
| `tarefa:T11` | Agregar as 517 zonas OD em macrozonas | 30/08 | `tarefa:T10.3` |

Todas realizam `meta:M1` e estão atribuídas a `pessoa:pedro`.

**Estado derivado a conferir antes de começar:** `pendencia:P03` (recorte municipal não
confirmado pelo professor) tem aresta `BLOQUEIA` para `tarefa:T11`. A T11 está, portanto,
formalmente bloqueada até o encontro de 26/08. Isso não impede preparar o código da agregação —
impede **congelar o critério** antes da resposta. Se o professor pedir a RMSP inteira, o alvo
deixa de ser ~120 macrozonas do município e passa a ser outra coisa; o código não muda, o
parâmetro muda.

`pendencia:P01` (microdados da OD 2023) bloqueia `tarefa:T12`, não este pacote. Mas quem fecha
P01 é a T10.2, que é deste pacote. Fechá-la cedo destrava o G03.

---

## 3. Pré-requisitos

- **R + `renv` inicializados** em `app/`, com `renv.lock` commitado. Se não estiverem, isso é
  G01 e vem antes.
- Pacotes: `sf`, `dplyr`, `tidyr`, `readxl`, `haven`, `foreign`, `spdep`, `units`, `targets`.
  Adicione com `renv::install()` e rode `renv::snapshot()` no mesmo commit.
- **~500 MB livres** em disco. O ZIP tem 40,46 MB, mas o `.sav` descompactado e os objetos
  intermediários em memória são bem maiores.
- Ter lido **§1 e §2 de `docs/02-fontes-de-dados.md`** — em especial §1.5, que é a origem
  factual da seção 5.6 deste guia.
- Ter lido as decisões **D1** (recorte espacial) e **D2** (base de demanda) em
  `docs/03-encontro-26-08.md`.

---

## 4. Insumos

### 4.1 Arquivos a baixar

| O quê | URL | Tamanho | Vai para |
| --- | --- | --- | --- |
| OD 2017 — banco completo | `https://transparencia.metrosp.com.br/sites/default/files/OD-2017.zip` | 40,46 MB | `app/data/raw/OD-2017.zip` |
| OD 2023 — anexos | `https://transparencia.metrosp.com.br/sites/default/files/Site_190225_PesquisaOD2023.zip` | n/d | `app/data/raw/` |
| OD 2023 — síntese (e-book) | `https://transparencia.metrosp.com.br/sites/default/files/MetroSP_OD2023_Ebook_Resultados_0.pdf` | > 30 MB | leitura humana |

Páginas de entrada, para citar no relatório em vez do link direto:
`https://transparencia.metrosp.com.br/dataset/pesquisa-origem-e-destino` e
`https://www.metro.sp.gov.br/pt_BR/pesquisa-od/`.

**`app/data/raw/*.zip` é gitignored** (convenções §6.3). O que entra no git é o *hash* do
arquivo, não o arquivo — ver passo 5.1.

### 4.2 Estrutura interna do ZIP (já verificada, §1.3 do catálogo)

79 arquivos em 4 diretórios:

| Diretório | Conteúdo | Para que serve aqui |
| --- | --- | --- |
| `Banco de Dados` | `.dbf` e `.sav` (SPSS) + **planilha com o layout das variáveis** + **planilha de correspondência entre zonas 2007 e 2017** | O banco em si e o dicionário oficial |
| `Manual` | documentação da pesquisa domiciliar | Define o que é *viagem*, o que é *motivo*, o que é *modo principal* |
| `Mapas` | MAP/MIF/TAB (MapInfo) **e shapefiles** de distritos, municípios e zonas OD 2017 | A malha das 517 zonas, com códigos que batem com o banco |
| `Tabelas` | 30 arquivos `.xlsx` tabulados | **O gabarito do teste de validação do passo 5.7** |

A planilha de layout dentro de `Banco de Dados` é a documentação canônica das variáveis. Ela é
o insumo mais importante de todo este pacote, porque nada mais no projeto pode ser programado
antes dela.

### 4.3 Atalho de terceiro: o pacote R `odbr`

`github.com/hsvab/odbr`. Três funções úteis:

```r
dic    <- odbr::read_dictionary(city = "Sao Paulo", year = 2017, language = "pt")
od     <- odbr::read_od(city = "Sao Paulo", year = 2017)
zonas  <- odbr::read_map(city = "Sao Paulo", year = 2017)
```

Cobertura: **1977–2017**. **Não cobre 2023**, e `harmonize = TRUE` não está disponível.

Use o `odbr` para **prototipar em 30 segundos** e para conferir o entendimento do dicionário.
**Não use como fonte final sem validar contra o original**: é um pacote de comunidade, e um
número que entra no relatório a partir de um empacotador de terceiro sem conferência é
exatamente o "dado não rastreável à fonte" da regra 3 do `CLAUDE.md`. Registre-o como
`fonte:odbr`, com a limitação escrita.

### 4.4 Números publicados que servem de gabarito

| Grandeza | Valor | Edição |
| --- | --- | --- |
| Viagens diárias | **42 milhões** | OD 2017 |
| Zonas OD | **517** (342 no município de SP) | OD 2017 |
| Municípios | **39** (RMSP completa) | OD 2017 |
| Domicílios válidos | 32 mil | OD 2017 |
| Divisão modal — motorizado | **67,3%** | OD 2017 |
| dentro do motorizado — coletivo | **54,1%** | OD 2017 |
| dentro do motorizado — individual | **45,9%** | OD 2017 |
| Divisão modal — não motorizado | **32,7%** | OD 2017 |
| Viagens diárias | **35,6 milhões** | OD 2023 |
| Viagens diárias no coletivo | **12,2 milhões** — menor patamar desde 1997 | OD 2023 |
| Divisão modal | individual motorizado **superou** o coletivo pela primeira vez | OD 2023 |

O número de zonas da OD 2023 **[A CONFIRMAR]**; o LabCidade fala em 38 municípios contra os 39
da OD 2017, divergência ainda aberta.

### 4.5 O que ainda não se sabe

⚠️ **Os nomes exatos das variáveis não foram confirmados por nenhuma fonte acessível.**
`FE_VIA`, `ZONA_O`, `ZONA_D`, `MODOPRIN`, `MOTIVO_D`, `DURACAO`, `RENDA_FA`, `H_SAIDA` circulam
na literatura, mas a documentação canônica é o layout dentro do ZIP. **Não programe contra
esses nomes.** O passo 5.3 existe para resolver isso, e o passo 5.4 mostra como escrever o
código de forma que os nomes reais entrem por um parâmetro de mapeamento em vez de espalhados
por dez arquivos.

Também não confirmado: se as **coordenadas do domicílio** estão no banco público e em qual
projeção. Se não estiverem, a menor unidade espacial do projeto é a zona OD, e a precisão de
sitação fica no centroide de zona — o que é uma limitação da metodologia e precisa aparecer na
seção de limitações do relatório.

---

## 5. Passo a passo

### 5.1 Baixar o ZIP e registrar a proveniência (T10.1)

Baixe fora do pipeline, uma vez, e registre o hash. O `targets` reexecuta quando o arquivo
muda; o hash é o que prova, em auditoria, que o arquivo de hoje é o mesmo de setembro.

```r
# rodar uma vez, no console; não é alvo do pipeline
dir.create("app/data/raw", recursive = TRUE, showWarnings = FALSE)

url_od2017 <- "https://transparencia.metrosp.com.br/sites/default/files/OD-2017.zip"
destino    <- "app/data/raw/OD-2017.zip"

utils::download.file(url_od2017, destino, mode = "wb")

# proveniência: isto vai para a nota da tarefa e para o YAML de fonte:od2017
list(
  bytes    = file.size(destino),          # esperado ~ 40,46 MB
  md5      = unname(tools::md5sum(destino)),
  baixado  = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
)
```

Inspecione o conteúdo **antes** de descompactar, para confirmar os 79 arquivos e os 4
diretórios:

```r
inventario <- utils::unzip(destino, list = TRUE)
nrow(inventario)                                          # esperado: 79
sort(unique(dirname(inventario$Name)))                    # esperado: os 4 diretórios
subset(inventario, grepl("\\.(sav|dbf|xlsx|xls|shp|prj)$", Name, ignore.case = TRUE))
```

Se a contagem não for 79, **pare e registre**: significa que o Metrô republicou o pacote e a
descrição do catálogo em `docs/02-fontes-de-dados.md` §1.3 envelheceu. Isso é uma nota na
`tarefa:T10.1` e uma correção no catálogo, no mesmo commit.

Descompacte para um diretório também gitignored:

```r
utils::unzip(destino, exdir = "app/data/raw/od2017")
```

### 5.2 Abrir o dicionário pelo atalho, para saber o que procurar

Antes de garimpar a planilha de layout, rode o `odbr` — leva menos tempo que abrir o Excel e já
diz que forma tem o banco:

```r
dic <- odbr::read_dictionary(city = "Sao Paulo", year = 2017, language = "pt")
# colunas: variable_name, description, categories, class
dplyr::filter(dic, grepl("fator|expans", description, ignore.case = TRUE))
dplyr::filter(dic, grepl("zona",         description, ignore.case = TRUE))
dplyr::filter(dic, grepl("dura|tempo",   description, ignore.case = TRUE))
dplyr::filter(dic, grepl("renda",        description, ignore.case = TRUE))
dplyr::filter(dic, grepl("motiv|modo",   description, ignore.case = TRUE))
```

Isto é uma **hipótese sobre os nomes**, não a confirmação. A confirmação é o passo seguinte.

### 5.3 Ler a planilha de layout — a documentação canônica (T10.1)

```r
arq_layout <- list.files("app/data/raw/od2017", pattern = "\\.xlsx?$",
                         recursive = TRUE, full.names = TRUE)
arq_layout <- grep("Banco de Dados", arq_layout, value = TRUE)
arq_layout   # identificar visualmente qual é o layout e qual é a correspondência de zonas

readxl::excel_sheets(arq_layout[1])
layout <- readxl::read_excel(arq_layout[1], sheet = 1)
print(layout, n = 200)
```

Preencha, a partir do que estiver escrito nessa planilha, o **mapa de variáveis** do projeto.
Ele é um único objeto, vive em um único lugar, e é o que impede que um nome de coluna errado se
espalhe pelo código:

```r
# app/R/mapa_variaveis_od.R
# @produz    (objeto de configuração, sem arquivo)
# @decisao   decisao:D02
# @tarefa    tarefa:T10.1

#' Mapa entre os nomes canônicos usados no projeto e os nomes reais das colunas da OD 2017.
#'
#' Existe porque os nomes reais das variáveis da OD não estavam confirmados em nenhuma
#' fonte acessível no levantamento de 24/08 (ver docs/02-fontes-de-dados.md §1.4). Em vez
#' de espalhar nomes possivelmente errados por todo o código, o projeto programa contra
#' nomes canônicos e resolve a tradução em um único ponto, preenchido a partir da planilha
#' de layout que vem dentro do OD-2017.zip.
#'
#' @return vetor nomeado: nomes canônicos -> nomes reais no banco
mapa_variaveis_od <- function() {
  c(
    zona_o      = "[PREENCHER a partir do layout]",
    zona_d      = "[PREENCHER]",
    municipio_o = "[PREENCHER]",
    municipio_d = "[PREENCHER]",
    modo_prin   = "[PREENCHER]",
    motivo_d    = "[PREENCHER]",
    duracao     = "[PREENCHER]",
    hora_saida  = "[PREENCHER]",
    renda_fa    = "[PREENCHER]",
    faixa_renda = "[PREENCHER]",
    fe_dom      = "[PREENCHER]",
    fe_pes      = "[PREENCHER]",
    fe_via      = "[PREENCHER]"
  )
}
```

Enquanto houver `[PREENCHER]`, o pipeline **deve falhar**. Isso é intencional: um mapeamento
incompleto que roda silenciosamente produz uma matriz OD plausível e errada, e ninguém percebe.

### 5.4 Ler o banco (T10.1)

Duas rotas. O `.sav` do SPSS é preferível porque carrega os rótulos das categorias — que são o
que traduz `motivo = 1` em "trabalho". O `.dbf` é o plano B.

```r
# app/R/ler_od.R
# @produz    data/interim/od_viagens.rds
# @consome   data/raw/od2017/
# @decisao   decisao:D02
# @tarefa    tarefa:T10.1

#' Lê o banco de viagens da OD 2017 e devolve as colunas canônicas do projeto.
#'
#' Esta é uma das poucas funções do projeto que toca disco: o caminho vem do targets, e
#' toda a transformação a jusante é pura. Ela não filtra, não agrega e não expande —
#' devolve o nível viagem inteiro, porque a expansão e o filtro são decisões registradas
#' (decisao:D03) que precisam ser reversíveis sem reler o banco.
#'
#' @param caminho_sav caminho do .sav dentro de `Banco de Dados`
#' @param mapa vetor nomeado de mapa_variaveis_od()
#' @param manter_rotulos se TRUE, converte colunas rotuladas do SPSS em factor
#' @return data frame no nível viagem, com nomes canônicos
ler_od <- function(caminho_sav, mapa = mapa_variaveis_od(), manter_rotulos = TRUE) {
  stopifnot(file.exists(caminho_sav), is.character(mapa), !any(grepl("PREENCHER", mapa)))

  bruto <- haven::read_sav(caminho_sav)

  faltantes <- setdiff(unname(mapa), names(bruto))
  if (length(faltantes) > 0) {
    stop("Colunas ausentes no banco: ", paste(faltantes, collapse = ", "),
         ". Conferir o layout dentro do OD-2017.zip.")
  }

  od <- bruto[, unname(mapa), drop = FALSE]
  names(od) <- names(mapa)

  if (manter_rotulos) {
    rotulaveis <- c("modo_prin", "motivo_d", "faixa_renda")
    for (v in intersect(rotulaveis, names(od))) {
      od[[v]] <- haven::as_factor(od[[v]], levels = "default")
    }
  }

  tibble::as_tibble(od)
}
```

Plano B com `.dbf`, que **não** traz rótulos e costuma vir em latin1:

```r
#' @param caminho_dbf caminho do .dbf dentro de `Banco de Dados`
ler_od_dbf <- function(caminho_dbf, mapa = mapa_variaveis_od()) {
  stopifnot(file.exists(caminho_dbf))
  bruto <- foreign::read.dbf(caminho_dbf, as.is = TRUE)
  # DBF do Metrô não declara codificação; acentos vêm quebrados se não converter
  chr <- vapply(bruto, is.character, logical(1))
  bruto[chr] <- lapply(bruto[chr], function(x) iconv(x, from = "latin1", to = "UTF-8"))
  od <- bruto[, unname(mapa), drop = FALSE]
  names(od) <- names(mapa)
  tibble::as_tibble(od)
}
```

**A tabela distribuída costuma vir achatada no nível viagem**, repetindo os atributos de
domicílio e de pessoa em cada linha de viagem. Confirme isso logo: conte linhas por domicílio e
veja se os atributos socioeconômicos se repetem. Essa constatação é o que torna o passo 5.6
delicado — os três fatores de expansão convivem na mesma tabela, e nada impede somar o errado.

### 5.5 Verificar se a OD 2023 tem microdados (T10.2, fecha `pendencia:P01`)

```r
url_anexos <- "https://transparencia.metrosp.com.br/sites/default/files/Site_190225_PesquisaOD2023.zip"
utils::download.file(url_anexos, "app/data/raw/OD-2023-anexos.zip", mode = "wb")

inv23 <- utils::unzip("app/data/raw/OD-2023-anexos.zip", list = TRUE)
inv23[order(-inv23$Length), ]

# indício de microdados: .sav, .dbf, .csv grande, .sas7bdat, .por
subset(inv23, grepl("\\.(sav|dbf|csv|sas7bdat|por|txt)$", Name, ignore.case = TRUE))
```

**Decisão binária, e ela precisa virar registro no mesmo dia:**

- **Há microdados** → `decisao:D02` muda inteiramente. Registre uma decisão nova que a
  `SUPERSEDE` (regra: id nunca muda, decisão errada não se apaga). Todo este guia passa a valer
  para o banco 2023, e a calibração do passo 5.8 deixa de existir.
- **Não há microdados** → `decisao:D02` se confirma, e **abra o pedido e-SIC ao Metrô-SP
  imediatamente**, pedindo (a) o banco desagregado da OD 2023 e (b) a tabela de correspondência
  de zonas 2017↔2023. Registre o número de protocolo na nota da `tarefa:T10.2`.

⚠️ **O prazo da LAI só cabe no cronograma se o pedido for feito nesta semana.** Um pedido aberto
em 10/09 chega depois do congelamento do modelo em 16/09 e não serve para nada. Se o pedido
voltar a tempo, ele vira uma calibração melhor; se voltar tarde, o próprio pedido — protocolado
e registrado — é evidência de diligência metodológica no relatório. Nos dois casos vale ter
feito. Em nenhum caso vale ter feito tarde.

A correspondência de zonas 2007→2017 **existe dentro do ZIP de 2017**; a de 2017→2023 **não
existe** em nenhuma fonte identificada. Se o zoneamento mudou, e o número de zonas da OD 2023 é
justamente um `[A CONFIRMAR]`, qualquer comparação zona a zona entre as duas edições fica
impossível sem essa tabela. Por isso o pedido e-SIC pede as duas coisas.

### 5.6 Fatores de expansão — a seção que decide se o resto presta

Esta é a parte deste guia que mais compensa ler duas vezes.

**O que a OD é:** uma amostra domiciliar de ~32 mil domicílios, **estratificada por cinco faixas
de renda**, expandida para representar a RMSP inteira. Cada registro carrega um peso amostral.

**A consequência:** **nenhum total pode ser lido da contagem de linhas.** Todo total é soma
ponderada, e toda média é média ponderada. `nrow(od)` não é o número de viagens; é o número de
entrevistas.

#### Os três níveis, e por que existem três fatores

A pesquisa tem três níveis encadeados, e **cada um tem seu próprio fator de expansão**:

```
Domicílio  ──(1:N)──>  Pessoa  ──(1:N)──>  Viagem
   FE_dom               FE_pes              FE_via
```

A tabela que se distribui é achatada no nível viagem. Ou seja: os três fatores aparecem lado a
lado, na mesma linha, e o R aceita somar qualquer um deles sem reclamar. O erro clássico é
exatamente esse — **misturar níveis** — e ele é silencioso.

Um exemplo de como ele acontece: você quer a renda média da zona, agrupa a tabela achatada por
zona, e pondera pela renda usando `FE_via`. O resultado não é a renda média da zona; é a renda
média **ponderada pelo número de viagens que cada pessoa faz**, o que sobrepesa quem viaja mais.
O número sai plausível. Ninguém percebe. Ele entra no filtro de renda do G03 e enviesa a
demanda capturável inteira.

#### As fórmulas

```
Viagens diárias totais              = Σ FE_via
Matriz OD por par de zonas          = Σ FE_via   GROUP BY zona_o, zona_d
Matriz por modo/motivo/hora         = Σ FE_via   GROUP BY zona_o, zona_d, modo, motivo, faixa
Duração média (ponderada)           = Σ (duracao × FE_via) / Σ FE_via
Renda média por zona (nível pessoa) = Σ (renda × FE_pes) / Σ FE_pes
Índice de mobilidade                = Σ FE_via / Σ FE_pes
População                           = Σ FE_pes         (nunca Σ FE_via)
Domicílios / frota                  = Σ FE_dom
```

O índice de mobilidade é a razão entre dois níveis diferentes, e por isso é o melhor teste de
que os dois fatores foram entendidos: ele só faz sentido se o numerador for de viagem e o
denominador de pessoa, e o valor resultante — viagens por pessoa por dia — tem ordem de
grandeza conhecida, o que permite detectar erro na hora.

#### As regras de ouro

1. **Use o fator do nível correto.** FE de viagem para contar viagens; de pessoa para população;
   de domicílio para domicílios e frota.
2. **Nunca some FE de viagem para estimar população.** Quem faz três viagens no dia entra três
   vezes. O resultado é a população superestimada por um fator que é o próprio índice de
   mobilidade — e, por ser um número redondo e grande, parece certo.
3. **Médias e proporções são sempre ponderadas.** `mean()` sem peso, num banco amostral
   estratificado, é a média da amostra, não da população. E como a estratificação é por renda,
   a média não ponderada é enviesada exatamente na variável que o G03 usa para filtrar.
4. **Ao subir de nível, desduplique antes de somar.** Para somar `FE_pes` numa tabela achatada
   no nível viagem, primeiro reduza a uma linha por pessoa. Somar `FE_pes` direto na tabela
   achatada conta cada pessoa uma vez por viagem — que é o erro 2 vestido de outra roupa.

#### O código

```r
# app/R/expandir.R
# @produz    data/interim/od_expandida.rds
# @consome   data/interim/od_viagens.rds
# @decisao   decisao:D02
# @tarefa    tarefa:T10.3

#' Constrói a matriz OD de viagens diárias por par de zonas, expandida pelo fator de viagem.
#'
#' Existe como função separada da leitura porque a expansão é o ponto onde o erro clássico
#' da OD acontece (misturar níveis de fator) e onde o teste de validação da tarefa:T10.3
#' se aplica. Isolá-la torna o erro testável em vez de difuso.
#'
#' @param od data frame no nível viagem, saída de ler_od()
#' @param por vetor de colunas de agrupamento além de zona_o e zona_d
#' @return data frame com zona_o, zona_d, as colunas de `por`, e viagens_dia
expandir_viagens <- function(od, por = character(0)) {
  stopifnot(is.data.frame(od),
            all(c("zona_o", "zona_d", "fe_via") %in% names(od)),
            all(por %in% names(od)))

  od |>
    dplyr::filter(!is.na(zona_o), !is.na(zona_d), !is.na(fe_via)) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c("zona_o", "zona_d", por)))) |>
    dplyr::summarise(viagens_dia = sum(fe_via), .groups = "drop")
}

#' População expandida por zona, no nível pessoa.
#'
#' Separada de propósito: é a função que NÃO pode usar fe_via. A desduplicação por
#' id de pessoa é obrigatória porque a tabela distribuída vem achatada no nível viagem.
#'
#' @param od data frame no nível viagem, com id de pessoa e fe_pes
#' @param col_id_pessoa nome da coluna que identifica a pessoa (ver layout)
#' @return data frame com zona (do domicílio) e pessoas
expandir_pessoas <- function(od, col_id_pessoa) {
  stopifnot(is.data.frame(od), col_id_pessoa %in% names(od), "fe_pes" %in% names(od))

  od |>
    dplyr::distinct(.data[[col_id_pessoa]], .keep_all = TRUE) |>
    dplyr::group_by(zona_dom = .data$zona_dom) |>
    dplyr::summarise(pessoas = sum(.data$fe_pes), .groups = "drop")
}

#' Média ponderada segura: falha se o peso vier de outro nível por engano.
#'
#' @param x vetor numérico
#' @param w vetor de pesos, do mesmo nível de x
media_ponderada <- function(x, w) {
  stopifnot(length(x) == length(w), all(w >= 0, na.rm = TRUE))
  ok <- !is.na(x) & !is.na(w)
  sum(x[ok] * w[ok]) / sum(w[ok])
}
```

Note o nome do argumento `col_id_pessoa`: o identificador de pessoa é mais um item cujo nome
real sai do layout. **Não chute.**

#### A limitação da calibração oficial, que precisa ir para o relatório

Os fatores de expansão da OD foram aferidos contra os totais de passageiros transportados por
**Metrô, CPTM, EMTU e SPTrans**. Ou seja: **os totais de transporte coletivo têm âncora externa;
os demais modos não.**

Isso importa diretamente para este projeto, porque a demanda que a UAM disputa é justamente a
do **individual motorizado** — a metade da matriz que não tem âncora. Não é motivo para
desqualificar o dado; é motivo para dizer, na seção de limitações, que a incerteza sobre o
volume de automóvel é maior que a sobre o volume de ônibus, e que isso se propaga para a demanda
capturável do G03.

### 5.7 O teste de validação obrigatório (T10.3)

**Alvo: reproduzir 42 milhões de viagens/dia somando `FE_via`.** Se não bater, pare. Não
continue "por enquanto". Um erro de nível de fator aqui contamina absolutamente tudo a jusante,
e é muito mais barato descobri-lo agora do que em 16/09 quando o modelo já rodou.

```r
# app/R/validar_expansao.R
# @produz    outputs/validacao_expansao.rds
# @consome   data/interim/od_viagens.rds
# @tarefa    tarefa:T10.3

#' Confronta os totais expandidos com os números publicados pelo Metrô para a OD 2017.
#'
#' Este é o teste que a nota da tarefa:T10.3 descreve: se o total de viagens não
#' reproduzir os 42 milhões publicados, o erro provável é de nível de fator de expansão.
#' Os valores de referência são parâmetros e não constantes, porque a mesma função
#' precisa servir para validar a OD 2023 se os microdados aparecerem (pendencia:P01).
#'
#' @param od data frame no nível viagem, saída de ler_od()
#' @param alvo_viagens_dia total publicado de viagens diárias
#' @param tolerancia desvio relativo aceito
#' @return data frame com indicador, valor obtido, valor de referência e desvio relativo
validar_expansao <- function(od,
                             alvo_viagens_dia = 42e6,
                             tolerancia       = 0.02) {
  stopifnot(is.data.frame(od), "fe_via" %in% names(od), tolerancia > 0)

  total <- sum(od$fe_via, na.rm = TRUE)

  data.frame(
    indicador  = "viagens_dia_total",
    obtido     = total,
    referencia = alvo_viagens_dia,
    desvio_rel = (total - alvo_viagens_dia) / alvo_viagens_dia,
    passou     = abs(total - alvo_viagens_dia) / alvo_viagens_dia <= tolerancia
  )
}
```

**Se não bater, o diagnóstico segue esta ordem:**

| Sintoma | Causa provável |
| --- | --- |
| Total muito **menor** que 42 mi (ordem de 10 mi) | Somou `FE_pes` ou `FE_dom` em vez de `FE_via` |
| Total muito **maior** | A tabela tem mais de uma linha por viagem (registro por etapa/modo declarado, não por viagem) e você somou todas |
| Total próximo mas ~5–15% abaixo | `NA` em `zona_o`/`zona_d` sendo descartado antes da soma, ou filtro implícito de município |
| Total exato mas matriz estranha | Trocou origem com destino, ou usou zona do domicílio como origem |

A terceira linha merece atenção: o `dplyr::filter(!is.na(...))` dentro de `expandir_viagens()`
descarta viagens sem zona. **Meça quanto isso descarta** e registre — se for material, é uma
limitação, não um detalhe.

#### O segundo teste: divisão modal

O total certo com a composição errada ainda é errado. Confira a divisão modal de 2017:

```r
#' @param od data frame no nível viagem
#' @param col_modo coluna de modo principal já classificada em coletivo/individual/nao_motorizado
#' @return data frame com participação de cada grupo modal, ponderada por fe_via
validar_divisao_modal <- function(od, col_modo = "grupo_modal") {
  stopifnot(col_modo %in% names(od))

  od |>
    dplyr::group_by(grupo = .data[[col_modo]]) |>
    dplyr::summarise(viagens = sum(fe_via, na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(participacao = viagens / sum(viagens))
}
```

Referências publicadas para 2017:

| Recorte | Referência |
| --- | --- |
| Motorizado (sobre o total) | **67,3%** |
| Não motorizado (sobre o total) | **32,7%** |
| Coletivo (**dentro** do motorizado) | **54,1%** |
| Individual (**dentro** do motorizado) | **45,9%** |

⚠️ **Atenção à base de cada percentual.** Os 54,1% e 45,9% são **dentro do motorizado**, não
sobre o total. Sobre o total, o coletivo fica em torno de 36% e o individual em torno de 31% —
mas esses dois números são **derivados por multiplicação, não publicados**. Se forem ao
relatório, apresente-os como cálculo próprio a partir dos publicados, não como dado do Metrô.

A classificação `grupo_modal` depende de como o modo principal está codificado no banco — o que
sai do layout e do `Manual`. O `Manual` é quem define a **hierarquia de modo principal sobre até
4 modos declarados**; não invente a regra, leia a dele.

#### O terceiro teste, e o mais barato: as 30 planilhas do ZIP

O diretório `Tabelas` traz 30 `.xlsx` já tabulados pelo Metrô. **São o gabarito oficial.**
Escolha duas ou três tabulações que você consiga reproduzir a partir do banco — viagens por
motivo, viagens por modo, viagens por município de origem — e reproduza-as número a número.
Bater com a tabulação oficial é uma prova muito mais forte que bater com o total agregado,
porque o total agregado pode bater por compensação de dois erros.

### 5.8 Calibração pelo nível de 2023 (`decisao:D02`)

A OD 2023 registra **35,6 milhões de viagens/dia** contra os **42 milhões** de 2017. É queda
real, não ruído amostral: efeito pós-pandemia sobre trabalho presencial e sobre o transporte
coletivo, cujas **12,2 milhões de viagens/dia são o menor patamar desde 1997**. E houve
**inversão da divisão modal**: o individual motorizado superou o coletivo pela primeira vez.

**Usar a OD 2017 sem correção superestimaria a demanda** — e superestimar demanda num modelo de
localização é o defeito específico que o enunciado chama de "exercício de aritmética". Um modelo
que localiza vertiportos para atender uma demanda que não existe mais localiza bem uma cidade
que não existe mais.

O fator global é direto:

```r
# app/R/calibrar_nivel.R
# @produz    data/interim/od_calibrada.rds
# @consome   data/interim/od_expandida.rds
# @decisao   decisao:D02
# @tarefa    tarefa:T10.3

#' Aplica o fator de correção de nível de 2017 para 2023 sobre a matriz OD expandida.
#'
#' A OD 2023 publicou agregados mas não microdados identificáveis (pendencia:P01), então
#' a única correção defensável é de nível, não de estrutura: reescala o volume total sem
#' alterar a distribuição espacial entre pares. A hipótese embutida — que a queda foi
#' aproximadamente homogênea no espaço — é falsa e precisa estar dita no relatório.
#'
#' @param od_matriz saída de expandir_viagens()
#' @param viagens_2017 total publicado da OD 2017
#' @param viagens_2023 total publicado da OD 2023
#' @param por_grupo se fornecido, nome da coluna de grupo modal para calibração diferenciada
#' @param fatores_grupo vetor nomeado de fatores por grupo modal, se por_grupo for usado
#' @return od_matriz com a coluna viagens_dia reescalada e o fator aplicado registrado
calibrar_nivel <- function(od_matriz,
                           viagens_2017  = 42.0e6,
                           viagens_2023  = 35.6e6,
                           por_grupo     = NULL,
                           fatores_grupo = NULL) {
  stopifnot(is.data.frame(od_matriz), "viagens_dia" %in% names(od_matriz),
            viagens_2017 > 0, viagens_2023 > 0)

  if (is.null(por_grupo)) {
    fator <- viagens_2023 / viagens_2017          # ~ 0,8476
    return(dplyr::mutate(od_matriz,
                         viagens_dia   = viagens_dia * fator,
                         fator_nivel   = fator))
  }

  stopifnot(por_grupo %in% names(od_matriz), !is.null(fatores_grupo),
            all(unique(od_matriz[[por_grupo]]) %in% names(fatores_grupo)))

  dplyr::mutate(od_matriz,
                fator_nivel = unname(fatores_grupo[as.character(.data[[por_grupo]])]),
                viagens_dia = viagens_dia * fator_nivel)
}
```

**Duas variantes, e a escolha entre elas é uma decisão a registrar:**

- **Fator global** — 35,6/42,0 ≈ **0,8476** aplicado a toda a matriz. Simples, transparente,
  fácil de defender. Assume que a queda foi homogênea no espaço e entre modos, o que a própria
  inversão da divisão modal contradiz.
- **Fator por grupo modal** — usa a queda específica do coletivo (para 12,2 mi/dia) e a variação
  do individual, calibrando cada grupo separadamente. Mais fiel ao que aconteceu, e importa
  aqui, porque a UAM disputa o individual motorizado, que **caiu menos** (ou cresceu em
  participação). Um fator global aplicado uniformemente **subestima** o segmento que interessa.

**Recomendação:** faça o fator global como base e o por grupo modal como cenário de
sensibilidade. Os dois entram como parâmetro, nunca como constante literal (regra 8 do
`CLAUDE.md`), e a diferença entre eles vira uma linha da análise da S3.

⚠️ **O que a calibração não conserta:** ela corrige o **nível**, não a **estrutura espacial**.
Se o trabalho remoto esvaziou especificamente os pares periferia→centro expandido, a matriz
2017 reescalada continua com o desenho de 2017. Isso é uma limitação estrutural desta decisão e
precisa estar escrita — não como ressalva de rodapé, mas na seção de limitações, porque afeta
justamente a região onde a demanda capturável do G03 vai se concentrar.

### 5.9 O shapefile das zonas e a decisão de CRS

**Use o shapefile de dentro do próprio ZIP** (pasta `Mapas`). O motivo é único e decisivo: os
códigos de zona batem exatamente com os do banco. As alternativas cobram um preço:

| Opção | Problema |
| --- | --- |
| **A — dentro do `OD-2017.zip`** ⭐ | CRS a confirmar no `.prj`. Nenhum outro problema |
| B — GeoSampa, camada "Zona Origem e Destino (OD)" | EPSG:31983 confirmado, mas **cobre só a capital**; atualizada em 30/04/2025, possivelmente já no zoneamento 2023 |
| C — `odbr::read_map()` | Rápido para prototipar; terceiro, exige validação |
| D — IBGE | **Não publica zonas OD**. Só setores/municípios/distritos |

⚠️ **Confira o `.prj` antes de qualquer cálculo métrico.** Um shapefile em coordenadas
geográficas onde o código assume metros produz distâncias em graus. Em São Paulo, um grau de
longitude são ~96 km, e uma distância de 0,14 (graus) parece um número pequeno e inofensivo até
alguém comparar com o limiar de 15 km do G03.

```r
# app/R/ler_zonas_od.R
# @produz    data/interim/zonas_od.rds
# @consome   data/raw/od2017/Mapas/
# @decisao   decisao:D01
# @tarefa    tarefa:T10.1

#' Lê a malha das zonas OD 2017 e reprojeta para o CRS métrico do projeto.
#'
#' A reprojeção é obrigatória e explícita porque toda a distância, área e buffer do
#' projeto — inclusive o limiar de 15 km da decisao:D03 — pressupõe metros. O CRS entra
#' como parâmetro para que a escolha fique visível no _targets.R em vez de escondida
#' dentro da função.
#'
#' @param caminho_shp caminho do .shp das zonas OD dentro da pasta Mapas
#' @param crs_alvo código EPSG de destino. EPSG:31983 = SIRGAS 2000 / UTM 23S
#' @return objeto sf com as zonas, validado e reprojetado
ler_zonas_od <- function(caminho_shp, crs_alvo = 31983) {
  stopifnot(file.exists(caminho_shp))

  zonas <- sf::read_sf(caminho_shp)

  crs_origem <- sf::st_crs(zonas)
  if (is.na(crs_origem)) {
    stop("O shapefile nao declara CRS (.prj ausente ou vazio). ",
         "Descobrir a projecao na documentacao do ZIP antes de prosseguir. ",
         "Atribuir um CRS a esmo produz distancias erradas que parecem certas.")
  }

  zonas <- sf::st_transform(zonas, crs_alvo)

  if (!all(sf::st_is_valid(zonas))) {
    zonas <- sf::st_make_valid(zonas)
  }

  zonas
}
```

Inspeção manual, antes de programar contra a malha:

```r
shp <- list.files("app/data/raw/od2017", pattern = "\\.shp$",
                  recursive = TRUE, full.names = TRUE)
shp   # distritos, municipios, zonas — identificar qual é qual

z <- sf::read_sf(grep("[Zz]ona", shp, value = TRUE)[1])
sf::st_crs(z)                    # o que o .prj diz
nrow(z)                          # esperado: 517
names(z)                         # o nome do campo de código de zona sai daqui
readLines(sub("\\.shp$", ".prj", grep("[Zz]ona", shp, value = TRUE)[1]))
```

E o teste que realmente importa — **a chave tem que casar**:

```r
codigos_banco <- sort(unique(od$zona_o))
codigos_mapa  <- sort(unique(z[["[CAMPO DE CODIGO]"]]))
setdiff(codigos_banco, codigos_mapa)   # tem que ser vazio
setdiff(codigos_mapa, codigos_banco)   # idem
```

Se não casar, o suspeito quase sempre é tipo: código lido como `character` com zero à esquerda
de um lado e como `integer` do outro. Normalize antes de concluir que a malha é a errada.

**A decisão de CRS, para o relatório:**

| EPSG | O que é | Papel no projeto |
| --- | --- | --- |
| **31983** | SIRGAS 2000 / UTM 23S, métrico | **Padrão do projeto.** Área, buffer, distância e toda a otimização |
| 4674 | SIRGAS 2000 geográficas | É o que o IBGE entrega. Reprojetar na entrada |
| 4326 | WGS 84 | É o que sai de OSM e das APIs de rota. Reprojetar na entrada |

A diferença entre 4674 e 4326 é sub-métrica e irrelevante nesta escala. **Mas a decisão precisa
estar declarada no relatório**, porque a alternativa — não declarar — é indistinguível de não
ter pensado no assunto.

### 5.10 Agregar as 517 zonas em ~120 macrozonas (T11)

#### Por que agregar

Duas pressões opostas, e o valor de `n_alvo` é onde elas se encontram:

- **Tratabilidade.** A formulação D5 é MCLP de fluxo bilateral: a unidade de cobertura é o
  **par** OD, com variável de cobertura indexada por par. Com 517 zonas há 517² ≈ 267 mil pares
  ordenados; com 120, cerca de 14,4 mil. É uma redução de ~18× no número de variáveis de
  cobertura, e é a diferença entre um MILP que resolve em segundos e um que não fecha o gap.
- **Resolução espacial.** Cada agregação joga fora informação sobre *onde* a demanda está — e
  "onde" é literalmente a variável de decisão do problema. Uma macrozona de 15 km² não sabe
  dizer se o vertiporto vai na Faria Lima ou na Vila Olímpia.

Há ainda um terceiro efeito, menos óbvio e mais perigoso: **agregar internaliza pares.** Uma
viagem entre duas zonas vizinhas que caem na mesma macrozona vira viagem intrazonal e **some da
matriz de pares**. Como o filtro do G03 só olha para pares interzonais longos, essas viagens
saem da conta — o que, aliás, não é ruim aqui, já que viagens curtas nunca seriam capturáveis.
Mas o efeito precisa ser **medido**, não assumido.

#### Os quatro critérios possíveis

| Critério | Como funciona | A favor | Contra |
| --- | --- | --- | --- |
| **Contiguidade espacial pura** | Agrupa zonas vizinhas até atingir `n_alvo` | Simples, macrozonas sempre conexas, fácil de explicar | Ignora o fenômeno; pode juntar Itaim com Vila Mariana só porque encostam |
| **Similaridade de fluxo OD** | Agrupa zonas com perfis de origem/destino parecidos | Preserva a estrutura da matriz, que é o dado que importa | Pode gerar macrozonas **descontínuas**, o que quebra a noção de "um vertiporto atende a macrozona" |
| **Distrito / subprefeitura** | Usa a geografia administrativa existente | Zero arbitrariedade; comunicável; o leitor sabe onde é "Pinheiros" | Os 96 distritos de SP não têm relação com fluxo; e a D1 já registrou que subprefeitura **não bate** com a geografia das zonas OD |
| **Clusterização com restrição de contiguidade** (SKATER, REDCAP) | Agrupa por similaridade **sujeito a** conexidade no grafo de vizinhança | Junta o melhor dos dois primeiros: macrozonas conexas *e* homogêneas | Mais parâmetros a justificar; resultado depende das variáveis de similaridade escolhidas |

**Recomendação: SKATER com contiguidade, usando como atributos de similaridade as variáveis que
o modelo efetivamente usa** — perfil de motivo, faixa de renda dominante e volume de viagens
geradas/atraídas. E use o **distrito como camada de rotulagem**, não de agregação: depois de
formar as macrozonas, nomeie cada uma pelo distrito predominante, para que o mapa do relatório
seja legível por quem conhece a cidade.

Um detalhe que evita retrabalho: **agregue apenas as zonas do município** (342 das 517), e trate
as 175 zonas restantes da RMSP como **um cinturão externo** — ou algumas poucas macrozonas de
borda, ou uma zona "resto da RMSP". Descartá-las inteiramente apagaria fluxos metropolitanos
reais; tratá-las com a mesma resolução da capital gastaria orçamento de instância em território
que a D1 já decidiu não modelar. Isto é uma sub-decisão e precisa ser registrada.

#### O código

```r
# app/R/agregar_zonas.R
# @produz    data/interim/macrozonas.rds
# @consome   data/interim/zonas_od.rds, data/interim/od_expandida.rds
# @decisao   decisao:D01
# @tarefa    tarefa:T11

#' Agrega as zonas OD em macrozonas contíguas e homogêneas via SKATER.
#'
#' A agregação é exigência de tratabilidade da formulação bilateral (decisao:D05): o
#' número de variáveis de cobertura cresce com o quadrado do número de zonas. O critério
#' é sub-decisao da decisao:D01 e foi escolhido entre quatro alternativas registradas.
#' n_alvo e as variaveis de similaridade sao parametros porque a escolha do nivel de
#' agregacao vira analise de sensibilidade (o efeito da resolucao espacial sobre a
#' solucao otima e um resultado, nao um detalhe de implementacao).
#'
#' @param zonas objeto sf das zonas OD, ja em EPSG:31983
#' @param atributos data frame com uma linha por zona e as variaveis de similaridade
#' @param col_zona nome da coluna de codigo de zona, comum a zonas e atributos
#' @param n_alvo numero de macrozonas desejado
#' @param vars_similaridade colunas de `atributos` usadas na distancia entre zonas
#' @return objeto sf das macrozonas, com a coluna macrozona e a lista de zonas de origem
agregar_zonas <- function(zonas,
                          atributos,
                          col_zona          = "zona",
                          n_alvo            = 120,
                          vars_similaridade = c("geradas", "atraidas",
                                                "prop_trabalho", "renda_media")) {
  stopifnot(inherits(zonas, "sf"), is.data.frame(atributos),
            n_alvo > 1, n_alvo < nrow(zonas),
            col_zona %in% names(zonas), col_zona %in% names(atributos),
            all(vars_similaridade %in% names(atributos)))

  z <- merge(zonas, atributos, by = col_zona, all.x = FALSE)
  stopifnot(nrow(z) == nrow(zonas))   # nenhuma zona pode se perder no merge

  # grafo de vizinhanca por contiguidade de fronteira
  viz <- spdep::poly2nb(z, queen = TRUE)
  if (any(spdep::card(viz) == 0)) {
    stop("Ha zonas sem vizinho (ilhas no grafo de contiguidade). ",
         "SKATER exige grafo conexo: unir manualmente ou tratar como macrozona propria.")
  }

  # variaveis padronizadas: sem isso, 'geradas' (na casa dos milhares) domina
  # 'prop_trabalho' (entre 0 e 1) e a clusterizacao vira agrupamento por volume
  x <- scale(as.data.frame(sf::st_drop_geometry(z))[, vars_similaridade, drop = FALSE])

  custos <- spdep::nbcosts(viz, data = x)
  pesos  <- spdep::nb2listw(viz, custos, style = "B")
  arvore <- spdep::mstree(pesos)

  corte  <- spdep::skater(arvore[, 1:2], x, ncuts = n_alvo - 1)

  z$macrozona <- corte$groups

  macro <- z |>
    dplyr::group_by(macrozona) |>
    dplyr::summarise(
      n_zonas = dplyr::n(),
      zonas   = paste(sort(.data[[col_zona]]), collapse = ";"),
      .groups = "drop"
    )

  sf::st_make_valid(macro)
}

#' Reagrega a matriz OD do nivel zona para o nivel macrozona.
#'
#' @param od_matriz saida de expandir_viagens(), no nivel zona
#' @param de_para data frame com colunas zona e macrozona
#' @param manter_intrazonal se FALSE, remove os pares em que origem e destino caem na
#'   mesma macrozona (viagens internalizadas pela agregacao)
#' @return matriz OD no nivel macrozona
reagregar_matriz <- function(od_matriz, de_para, manter_intrazonal = TRUE) {
  stopifnot(is.data.frame(od_matriz), is.data.frame(de_para),
            all(c("zona", "macrozona") %in% names(de_para)))

  m <- od_matriz |>
    dplyr::inner_join(dplyr::rename(de_para, zona_o = zona, macro_o = macrozona),
                      by = "zona_o") |>
    dplyr::inner_join(dplyr::rename(de_para, zona_d = zona, macro_d = macrozona),
                      by = "zona_d") |>
    dplyr::group_by(macro_o, macro_d) |>
    dplyr::summarise(viagens_dia = sum(viagens_dia), .groups = "drop")

  if (!manter_intrazonal) m <- dplyr::filter(m, macro_o != macro_d)
  m
}
```

#### Como validar a agregação

Três testes. Nenhum é opcional.

**1. Conservação do total.** A matriz agregada tem que preservar exatamente o total de viagens
da matriz desagregada. Se não preservar, houve zona perdida no `merge` ou par descartado no
`join`.

```r
#' @param od_zona matriz OD no nivel zona
#' @param od_macro matriz OD no nivel macrozona
#' @param tolerancia desvio relativo aceito (deve ser essencialmente zero)
validar_agregacao <- function(od_zona, od_macro, tolerancia = 1e-9) {
  t_zona  <- sum(od_zona$viagens_dia)
  t_macro <- sum(od_macro$viagens_dia)
  desvio  <- abs(t_macro - t_zona) / t_zona
  stopifnot(desvio <= tolerancia)
  data.frame(total_zona = t_zona, total_macro = t_macro, desvio_rel = desvio)
}
```

**2. Perda de variância intrazona.** Quanto da variabilidade original a agregação destruiu.
Para cada variável de similaridade, decomponha a variância total em *entre* macrozonas e
*dentro* de macrozonas. A fração **entre** é o que sobrou de poder discriminante:

```r
#' @param atributos data frame por zona, com macrozona e as variaveis
#' @param vars colunas a avaliar
#' @return data frame com a fracao da variancia preservada entre macrozonas
perda_variancia <- function(atributos, vars) {
  do.call(rbind, lapply(vars, function(v) {
    x  <- atributos[[v]]
    g  <- atributos$macrozona
    vt <- stats::var(x)
    md <- tapply(x, g, mean)
    nk <- table(g)
    ve <- sum(nk * (md - mean(x))^2) / (length(x) - 1)   # variancia entre
    data.frame(variavel = v, var_total = vt, var_entre = ve,
               fracao_preservada = ve / vt)
  }))
}
```

Uma `fracao_preservada` alta significa que as macrozonas são internamente homogêneas — que é
exatamente o que o SKATER busca. Se ela cair muito para a variável de renda, atenção: o filtro
de renda do G03 vai operar sobre uma média que esconde heterogeneidade interna, e isso precisa
estar dito.

**3. Fração de viagens internalizadas.** Quantas viagens deixaram de ser pares por caírem na
mesma macrozona:

```r
intra <- sum(dplyr::filter(od_macro, macro_o == macro_d)$viagens_dia)
intra / sum(od_macro$viagens_dia)
```

Compare esse número com o mesmo cálculo no nível zona. A diferença é o custo da agregação,
medido na moeda certa. Rode-o para `n_alvo` em `c(80, 100, 120, 150, 200)` e ponha a curva no
relatório: ela transforma "escolhemos 120" de arbitrariedade em decisão com evidência.

#### O alvo no `_targets.R`

```r
list(
  tar_target(od_bruta,     ler_od("data/raw/od2017/[caminho do .sav]"), format = "rds"),
  tar_target(zonas_od,     ler_zonas_od("data/raw/od2017/Mapas/[zonas].shp", crs_alvo = 31983)),
  tar_target(validacao,    validar_expansao(od_bruta, alvo_viagens_dia = 42e6)),
  tar_target(od_expandida, expandir_viagens(od_bruta, por = c("motivo_d", "faixa_renda"))),
  tar_target(od_calibrada, calibrar_nivel(od_expandida, 42.0e6, 35.6e6)),
  tar_target(atributos_zona, resumir_por_zona(od_expandida)),
  tar_target(macrozonas,   agregar_zonas(zonas_od, atributos_zona, n_alvo = 120)),
  tar_target(od_macro,     reagregar_matriz(od_calibrada, de_para_macrozonas(macrozonas)))
)
```

Note que `validacao` é um alvo, não um teste rodado à mão. Isso faz o `tar_make()` falhar quando
a validação falhar, e é o que impede que o erro de nível de fator sobreviva a um `git pull`
distraído.

---

## 6. Critério de pronto

- [ ] `OD-2017.zip` baixado, com **tamanho e md5 registrados** na nota da `tarefa:T10.1`
- [ ] Inventário do ZIP confere com o catálogo: **79 arquivos, 4 diretórios**
- [ ] `mapa_variaveis_od()` **sem nenhum `[PREENCHER]`**, cada nome confirmado contra a planilha
      de layout de dentro do ZIP
- [ ] `fonte:od2017` registrada no grafo com origem, formato, cobertura e **limitações**
- [ ] `fonte:odbr` registrada, com a limitação "não cobre 2023; terceiro, validar contra o
      original"
- [ ] `Site_190225_PesquisaOD2023.zip` inspecionado, e **`pendencia:P01` fechada ou atualizada
      com o protocolo do e-SIC**
- [ ] `validar_expansao()` reproduz **42 milhões de viagens/dia** dentro da tolerância declarada
- [ ] `validar_divisao_modal()` reproduz **67,3% / 32,7%** e, dentro do motorizado,
      **54,1% / 45,9%**
- [ ] Pelo menos **duas tabulações** do diretório `Tabelas` reproduzidas a partir do banco
- [ ] `.prj` do shapefile de zonas **lido e registrado**; malha reprojetada para **EPSG:31983**
- [ ] Códigos de zona do mapa e do banco **casam integralmente** nos dois sentidos
- [ ] Fator de calibração 2017→2023 aplicado **como parâmetro**, com a variante por grupo modal
      disponível como cenário
- [ ] Macrozonas geradas, **todas conexas**, com `n_alvo` como parâmetro
- [ ] `validar_agregacao()` passa com desvio essencialmente nulo
- [ ] `perda_variancia()` e a fração de viagens internalizadas calculadas para pelo menos
      **cinco valores de `n_alvo`**
- [ ] `tar_make()` completo e `tar_outdated()` vazio
- [ ] Validador do grafo passa
- [ ] `renv::snapshot()` rodado e `renv.lock` no commit

---

## 7. Armadilhas conhecidas

**Somar linhas em vez de somar fatores.** `nrow(od)` é o número de entrevistas, não de viagens.
Aparece disfarçado em `dplyr::count()`, `n()` e `tally()` — todos contam linhas. Num banco
amostral estratificado, contagem de linha nunca é resposta.

**Misturar níveis de fator.** O erro clássico, descrito por extenso em 5.6. Sintoma: o total de
viagens dá certo mas a renda média da zona sai alta demais. Causa: ponderação por `FE_via` numa
grandeza de nível pessoa.

**Média não ponderada.** `mean(duracao)` numa amostra estratificada por renda é enviesado
justamente na dimensão que o G03 usa para filtrar. Use `media_ponderada()`.

**Percentual sobre a base errada.** Os 54,1% do coletivo são **dentro do motorizado**. Ler como
percentual do total dá um erro de ~18 pontos e um número que ainda parece plausível.

**Confundir o filtro geométrico com adoção.** A matriz que sai deste pacote é de viagens
*existentes*, não de viagens que migrariam para o ar. A conversão de uma na outra é o G03, e a
literatura mostra que ela é brutal. Não escreva "demanda UAM" em nenhum objeto deste pacote.

**Shapefile em graus.** Se o `.prj` disser geográficas e o código assumir metros, o limiar de
15 km do G03 vira 15 graus — 1.600 km — e o filtro devolve zero pares. O sintoma é bom (dá zero,
alguém percebe). O sintoma ruim é o inverso: distância em graus comparada com limiar em graus
por acidente, e todo par passa.

**Reprojetar depois de calcular.** `sf` calcula em qualquer CRS sem avisar. Reprojete na leitura,
dentro de `ler_zonas_od()`, e nunca depois.

**Código de zona como texto vs. número.** `"001"` e `1` não casam em `join`, e o `dplyr` devolve
zero linhas sem erro. Normalize o tipo antes de qualquer junção e confira `nrow()` depois.

**Zonas sem vizinho no grafo de contiguidade.** `spdep::poly2nb()` devolve cardinalidade zero
para polígonos isolados por geometria inválida. `spdep::skater()` exige grafo conexo. Rode
`sf::st_make_valid()` antes, e trate o que sobrar explicitamente.

**Variáveis não padronizadas no SKATER.** Sem `scale()`, a variável de maior escala domina a
distância, e o "agrupamento por similaridade de fluxo" vira agrupamento por volume.

**Agregar antes de validar.** Se a expansão estiver errada, a agregação vai preservar
lindamente um total errado. `validar_expansao()` vem antes de `agregar_zonas()` no grafo do
`targets`, e não por acaso.

**Descartar `NA` sem contar.** O `filter(!is.na(zona_o))` do `expandir_viagens()` pode estar
jogando fora 1% ou 10% das viagens. Meça, registre, e se for material vire uma limitação
declarada.

**Deixar a T11 avançar com `pendencia:P03` aberta.** Se o professor pedir a RMSP inteira, o
`n_alvo` e o recorte mudam. Prepare o código; não congele o critério antes de 26/08.

---

## 8. O que registrar

### Fontes

| Id sugerido | O que registrar como limitação |
| --- | --- |
| `fonte:od2017` | Base mais recente **com microdados**. Defasada frente ao pós-pandemia (42 → 35,6 mi). Nomes de variáveis exigem leitura do layout interno. Fatores calibrados **só** contra os operadores de transporte coletivo — automóvel sem âncora externa |
| `fonte:od2023-sintese` | Só agregados. Licença "não especificada" no CKAN. Nº de zonas e cobertura municipal a confirmar |
| `fonte:od2023-anexos` | O que a T10.2 descobriu. Se não houver microdados, dizer isso explicitamente e apontar o protocolo e-SIC |
| `fonte:odbr` | Cobre 1977–2017, **não cobre 2023**. `harmonize=TRUE` indisponível. Pacote de terceiro — validado contra o original em [data] |
| `fonte:zonas-od-2017` | Shapefile de dentro do ZIP. CRS original conforme `.prj` lido em [data]. Códigos batem com o banco |

### Decisões

- **Critério de agregação das zonas** — sub-decisão da `decisao:D01`, explicitamente antecipada
  como "vai ser perguntado". Precisa das quatro alternativas da seção 5.10 com o motivo
  específico de rejeição de cada uma, e do valor de `n_alvo` com a evidência da curva de
  internalização.
- **Tratamento das 175 zonas fora do município** — cinturão externo, macrozonas de borda, ou
  descarte. Com o motivo.
- **Forma da calibração 2017→2023** — fator global vs. por grupo modal. Registre a hipótese
  embutida (queda espacialmente homogênea) como o que ela é: falsa e aceita conscientemente.
- **CRS do projeto** — EPSG:31983, com 4674 e 4326 mencionados como CRS de entrada de outras
  fontes.
- **Renda vinda da OD e não do Censo** — pode ficar aqui ou no G03; o importante é que exista
  uma vez, com a alternativa descartada e o motivo (compatibilização areal vs. defasagem).

### Pendências

- **`pendencia:P01`** — fechar se houver decisão definitiva sobre os microdados de 2023, ou
  atualizar com o protocolo do e-SIC e a data-limite da resposta.
- **Abrir nova pendência** se a contagem de arquivos do ZIP divergir do catálogo, se os códigos
  de zona não casarem, ou se a validação de 42 milhões não fechar depois de esgotado o
  diagnóstico da seção 5.7.

### Notas nas tarefas

Cada uma das cinco tarefas ganha nota datada e assinada por `pedro`. As que mais valem:

- Em `T10.1`: **os nomes reais das variáveis**, agora confirmados. Esta nota fecha o
  `[A CONFIRMAR]` mais citado de todo o projeto e vai ser consultada por todo mundo.
- Em `T10.3`: **o número exato** que a soma de `FE_via` devolveu, e o desvio contra os 42
  milhões. Se bateu de primeira, diga; se precisou de três tentativas, diga qual era o erro —
  isso é material direto da seção de método do relatório.
- Em `T11`: a curva de internalização por `n_alvo`, e por que 120.

### Registro de IA

Se houve sessão com o Claude neste pacote, `ia:<data>-<slug>` com `critica_humana` não vazia.
Neste pacote específico, os candidatos naturais a crítica são: os nomes de variável que a IA
sugerir antes de alguém abrir o layout são **hipótese, não dado**; o valor `n_alvo = 120` é um
alvo herdado da decisão D1 e não uma otimização; e a escolha de SKATER sobre REDCAP é
defensável nos dois sentidos, o que torna a decisão do grupo — e não a sugestão da IA — o que
precisa estar registrado.

---

## 9. Como isso vira relatório

| Seção do relatório | O que este pacote entrega |
| --- | --- |
| **Dados e fontes** | A tabela de fontes com origem, formato, cobertura e limitações, direto dos nós `fonte`. A frase sobre a calibração assimétrica dos fatores de expansão vale mais que um parágrafo elogiando a qualidade da OD |
| **Método — tratamento da demanda** | Os três níveis de expansão, as fórmulas, e por que médias são ponderadas. É onde se demonstra domínio do dado em vez de uso do dado |
| **Método — validação** | O teste dos 42 milhões e a divisão modal reproduzida. Este é o parágrafo que separa um trabalho que leu a OD de um trabalho que a usou |
| **Método — recorte espacial** | O critério de agregação, as quatro alternativas, e a curva de internalização por `n_alvo` |
| **Limitações** | Cinco itens vêm daqui: defasagem 2017 corrigida só em nível e não em estrutura; fatores sem âncora externa para o modo individual; menor unidade espacial é a zona (ou o centroide de macrozona); microdados 2023 indisponíveis; perda de resolução pela agregação |
| **Figuras** | Mapa das 517 zonas → mapa das ~120 macrozonas, lado a lado, em EPSG:31983 · curva de fração internalizada por `n_alvo` · desvio da validação por tabulação reproduzida |
| **Reprodutibilidade** | `tar_network()` gera o grafo de proveniência a partir da execução real. O md5 do ZIP prova que o arquivo não mudou |

E a ponte para o próximo pacote: a matriz de macrozonas calibrada é o **único** insumo do G03.
Se ela estiver errada, o filtro de demanda capturável vai filtrar corretamente um dado errado —
e ninguém vai conseguir dizer isso olhando o resultado.
