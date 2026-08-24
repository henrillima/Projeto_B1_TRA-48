# G04 — Conjunto de candidatos a vertiporto

> Pacote de trabalho de **Antônio Garcia**. Prazo do pacote: **02/09/2026**.
> Leia `docs/guias/G00-como-trabalhar.md` e `CLAUDE.md` antes deste.

---

## Objetivo

Ao fim deste pacote existe um objeto `sf` versionado, em EPSG:31983, com o conjunto `J` de
candidatos a vertiporto no município de São Paulo — cada linha com identificador estável,
coordenada validada, procedência (ANAC, ROTAER, GIS) e o motivo pelo qual sobreviveu ao
funil de filtragem — dimensionado em **40 a 60 sítios**, com a contagem própria de helipontos
e a data de extração registradas no grafo.

---

## Tarefas no grafo

| Id | Título | Prazo | Est. |
| --- | --- | --- | --- |
| `tarefa:T20` | Construir o conjunto de candidatos a vertiporto | 02/09 | — |
| `tarefa:T20.1` | Extrair helipontos da lista ANAC filtrada por município | 27/08 | 3 h |
| `tarefa:T20.2` | Cruzar o cadastro ANAC com o ROTAER do DECEA | 30/08 | 4 h |
| `tarefa:T20.3` | Filtrar candidatos por viabilidade urbanística | 02/09 | 5 h |

Todas `REALIZA meta:M2` e `ATRIBUIDA_A pessoa:antonio`. A cadeia interna é
`T20.1 → T20.2 → T20.3`. A decisão de recorte que governa o pacote é **D4** (§ Parte 2 de
`docs/03-encontro-26-08.md`) — ela já existe em `governanca/data/decisoes/D04.yaml`, com quatro
alternativas descartadas. Leia antes de começar: o filtro que você vai implementar aqui é a
operacionalização dela, e divergir dela exige uma decisão nova que a supersede.

---

## Pré-requisitos

**T20 não depende de nenhuma outra tarefa.** Isso é deliberado e é a razão de G04 poder correr
em paralelo com G02/G03: o conjunto de candidatos não precisa da demanda para existir. Comece
por ele se o pipeline de dados estiver travado.

O que precisa estar de pé antes:

- [ ] `renv` inicializado, com `sf`, `dplyr`, `readr`, `ggplot2` no lock (G01/T01).
- [ ] GDAL/PROJ funcionando: `sf::sf_extSoftVersion()` responde sem erro.
- [ ] `decisao:D04` escrita em YAML, com as três alternativas descartadas que já estão redigidas
      em `03-encontro-26-08.md` (grade regular, k-means/fuzzy c-means, só os aeroportos).
- [ ] Camada de contorno do município de São Paulo — do GeoSampa ou do shapefile de
      distritos dentro do `OD-2017.zip`. Ela serve de envelope de sanidade das coordenadas.

Para **T20.3** especificamente: as camadas do GeoSampa já baixadas em `app/data/raw/geosampa/`.
Elas não podem ser buscadas por script (CAPTCHA), então o download é manual e antecede a sessão.

---

## Insumos

### Fontes primárias

| Fonte | URL | Formato | Usa em |
| --- | --- | --- | --- |
| ANAC — Lista de Aeródromos Privados V2 (cobre "aeródromos privados, helidecks e helipontos") | `https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-privados-v2` | CSV / JSON, pub. 06/09/2023 | T20.1 |
| DECEA — AISWEB (portal) | `https://aisweb.decea.mil.br/?i=home&lingua=pt-br` | HTML | T20.2 |
| DECEA — ROTAER completo | `https://aisweb.decea.mil.br/download/?p=ROTAER_Completo&public=da1cd33d-ef8d-4320-9da05980326e1775.pdf` | PDF não estruturado | T20.2 |
| DECEA — ROTAER Cap. 1 e 2 (legenda / como ler) | `https://aisweb.decea.mil.br/download/?p=ROTAER_Cap__1_e_2&public=5707bb57-a5a8-400a-ba165571fbae90b4.pdf` | PDF | T20.2 |
| DECEA — GeoAISWEB | `https://geoaisweb.decea.gov.br/` | visualizador de camadas | T20.2 |
| DECEA — API AISWEB | `https://aisweb.decea.mil.br/?i=publicacoes&p=api` (chave: `https://ajuda.decea.mil.br/base-de-conhecimento/como-solicitar-a-chave-da-api-aisweb/`) | XML/JSON, requer `apiKey`+`apiPass` | T20.2 |
| GeoSampa (portal, 500+ camadas) | `https://geosampa.prefeitura.sp.gov.br` | SHP/GPKG/GeoJSON/KML, EPSG:31983 | T20.3 |
| GeoSampa — WFS | `http://wfs.geosampa.prefeitura.sp.gov.br/geoserver/geoportal/wfs` | WFS | T20.3 |
| PMSP — licenciamento de helipontos | `https://prefeitura.sp.gov.br/web/licenciamento/w/noticias/326378` | HTML | T20.3 |
| ANAC — release histórico (214 helipontos, 09/02/2009) | `https://www2.anac.gov.br/IMPRENSA/anacConvocaProprietariosDeHelipontos_SP.asp` | HTML | referência histórica apenas |
| ANAC/INDE — camada geoespacial "Helipontos ANAC" | `https://metadados.inde.gov.br/geonetwork/srv/api/records/5BBB2266-DD04-4610-A0DD-2E09F68E95FB` | geoespacial, **[A CONFIRMAR — robots.txt]** | alternativa a T20.1 |

### Camadas do GeoSampa a baixar (T20.3)

Zoneamento (LPUOS) · uso do solo · edificações/gabarito · distritos · estações de metrô e CPTM ·
terminais de ônibus · Eixos de Estruturação da Transformação Urbana (EETU).

**Limitação estrutural do GeoSampa: cobre só o município.** Como D1 já recortou o problema no
município, isso deixa de ser perda — mas precisa estar escrito, porque é a mesma limitação que
justifica D1.

### Referências

- **Ribeiro, J.K., Borille, G.M.R., Caetano, M. & Silva, E.J. (2023).** *Repurposing urban air
  mobility infrastructure for sustainable transportation in metropolitan cities: A case study of
  vertiports in São Paulo, Brazil.* **Sustainable Cities and Society** 98, 104797.
  DOI `10.1016/j.scs.2023.104797`. Borille e Caetano são do ITA. É a base de D4.
  ⚠️ Confirmado **apenas em metadado bibliográfico** — o texto integral está em paywall
  (ScienceDirect bloqueia acesso automatizado). **Pegue o PDF pela biblioteca do ITA antes de
  citar qualquer método ou número deste artigo.**
- **Carvalho et al. (2026)**, *CSTP* 25, 101848 — framework do próprio departamento sobre UAM na
  Grande São Paulo. Mesma ressalva de acesso.

### Parâmetros de entrada

| Parâmetro | Valor de partida | Onde vira sensibilidade |
| --- | --- | --- |
| `n_alvo_candidatos` | 50 (faixa aceita: 40–60) | tamanho da instância, S3 |
| `raio_conflito_m` | **[A CONFIRMAR]** — separação mínima entre dois candidatos | fusão de sítios colados |
| `dist_max_transporte_m` | **[A CONFIRMAR]** — proximidade a estação/terminal para sítios GIS | geração de candidatos adicionais |

Nenhum deles entra como literal no código. Regra 8 do `CLAUDE.md`.

---

## Passo a passo

### 0. Por que helipontos existentes, e não candidatos sintéticos

Esta seção é argumento, não procedimento — mas é o que se defende na arguição, então vem antes
do código.

São Paulo opera a maior frota urbana de helicópteros do mundo. A consequência para este projeto
é que **o conjunto `J` já existe fisicamente**: há infraestrutura construída, licenciada e em
operação, com heliponto elevado em laje de edifício comercial como tipologia dominante. Não
precisamos inventar onde um vertiporto *poderia* caber.

Isso importa porque a alternativa usual na literatura é gerar candidatos por clusterização da
demanda — k-means em Lim & Hwang (2019), fuzzy c-means em Rimjha et al. (2021, AIAA). O defeito
é **circular**: candidatos colocados nos centroides dos clusters de demanda garantem, por
construção, que exista um candidato perto de onde há viagem. O modelo de localização passa a
escolher entre alternativas todas boas, a cobertura ótima fica artificialmente alta, e a
pergunta "onde localizar" é respondida antes de ser feita — pelo algoritmo de clusterização, não
pelo modelo de otimização. Os trabalhos de Chicago, Munique e Pequim convivem com isso porque
não têm outra opção; nós temos.

O caminho de usar a infraestrutura existente é o de **Ribeiro et al. (2023)**, que trata
explicitamente do reaproveitamento de helipontos de São Paulo como vertiportos. Ele também
abre, se o grupo for para a versão de custo fixo endógeno, a possibilidade de `f_j` diferenciado
por tipo de sítio — retrofit de heliponto existente custa menos que greenfield — o que é uma
distinção que só faz sentido justamente porque os candidatos não são sintéticos.

**O que isso não resolve:** o cadastro de helipontos reflete a aviação de asas rotativas de hoje,
que é predominantemente corporativa e concentrada no vetor sudoeste. Herdar esse conjunto é
herdar esse viés. Não é um defeito a esconder — é um resultado a comentar quando o modelo
devolver uma solução concentrada, e é exatamente a tensão "UAM como infraestrutura de elite" que
D1 se recusou a pré-decidir pelo recorte espacial. **Registre isso como nota em `tarefa:T20`
antes de rodar o modelo**, para que a observação esteja datada antes do resultado, e não depois.

### 1. T20.1 — extrair os helipontos da ANAC

#### 1.1 Baixar à mão, e versionar

O portal `gov.br` tem CAPTCHA. Download automatizado via `download.file()` ou `httr2` vai falhar
de forma intermitente e silenciosa — às vezes devolve o HTML da página de desafio com status 200,
que o `readr` engole e transforma em um data frame de uma coluna. **Baixe pelo navegador.**

O arquivo é pequeno e citável, então ele **entra no git** — é uma das exceções explícitas
previstas em `app/data/raw/.gitignore` (§8 do `CLAUDE.md`). Nome com data de extração:

```
app/data/raw/anac/aerodromos_privados_v2_2026-08-25.csv
```

A data no nome é obrigatória aqui, e é a única exceção à regra de "sem data no nome" da §4.3 das
convenções: aquela regra vale para **saídas**, cuja data está no git; esta é uma **entrada
imutável** cuja data de extração é um metadado da fonte, não do commit.

#### 1.2 Validar o cabeçalho antes de escrever o parser

Não presuma nomes de coluna. Rode isto primeiro, olhe a saída com os olhos, e só então escreva a
leitura:

```r
readr::read_lines("app/data/raw/anac/aerodromos_privados_v2_2026-08-25.csv", n_max = 5)
```

Três coisas a decidir olhando:

1. **Separador** — `;` e vírgula decimal são o padrão de dado público brasileiro. Se for esse o
   caso, use `readr::read_csv2()`, não `read_csv()`.
2. **Encoding** — `latin1`/`ISO-8859-1` é frequente. Se "São Paulo" aparecer corrompido, o filtro
   por município falha silenciosamente e devolve zero linhas.
3. **Formato das coordenadas** — o cadastro da ANAC historicamente traz latitude e longitude em
   grau-minuto-segundo no formato `DDMMSSX` (e `DDDMMSSX` na longitude), com o hemisfério como
   letra final. Mas a V2 pode já vir em decimal. **A função abaixo detecta e não presume.**

#### 1.3 A conversão DMS → decimal

```r
# app/R/converter_dms.R
# @produz    (função utilitária, sem alvo próprio)
# @consome   —
# @decisao   decisao:D04
# @tarefa    tarefa:T20.1

#' Converte coordenada em grau-minuto-segundo compactado para grau decimal.
#'
#' O cadastro de aeródromos da ANAC traz historicamente lat/long no formato
#' `DDMMSSX` / `DDDMMSSX`, em que X é o hemisfério. Um parser que presuma
#' largura fixa quebra na longitude (três dígitos de grau) e em variantes com
#' segundo fracionário. Por isso a leitura é por expressão regular ancorada:
#' segundos e minutos têm dois dígitos cada, o grau é o que sobra à esquerda.
#'
#' Devolve NA — nunca um número errado — para tudo que não casar com o padrão.
#' Silêncio aqui viraria um vertiporto no oceano, e um candidato no oceano é
#' plausível o bastante para passar despercebido no mapa.
#'
#' @param x vetor de caracteres com as coordenadas cruas
#' @return vetor numérico de graus decimais; negativo em S, W e O
converter_dms <- function(x) {
  stopifnot(is.character(x) || is.factor(x))

  txt <- toupper(trimws(as.character(x)))
  txt <- gsub(",", ".", txt, fixed = TRUE)
  txt <- gsub("[^0-9NSEWLO.]", "", txt)

  padrao <- "^([0-9]+)([0-9]{2})([0-9]{2}(?:\\.[0-9]+)?)([NSEWLO])$"
  casou  <- grepl(padrao, txt)

  graus    <- suppressWarnings(as.numeric(sub(padrao, "\\1", txt)))
  minutos  <- suppressWarnings(as.numeric(sub(padrao, "\\2", txt)))
  segundos <- suppressWarnings(as.numeric(sub(padrao, "\\3", txt)))
  hemisf   <- sub(padrao, "\\4", txt)

  sinal <- ifelse(hemisf %in% c("S", "W", "O"), -1, 1)
  fora  <- minutos >= 60 | segundos >= 60

  out <- sinal * (graus + minutos / 60 + segundos / 3600)
  out[!casou | fora] <- NA_real_
  out
}

#' Decide se a coluna já está em decimal ou precisa de conversão.
#'
#' Existe para que a escolha do parser seja um dado observado, e não uma
#' premissa do programador: a V2 do cadastro pode ter mudado de formato em
#' relação às versões anteriores, e a diferença é invisível a olho nu numa
#' célula isolada.
#'
#' @param x vetor de caracteres da coluna de coordenada
#' @return "decimal", "dms" ou "desconhecido"
detectar_formato_coordenada <- function(x) {
  stopifnot(is.character(x) || is.factor(x))
  txt <- toupper(trimws(as.character(x)))
  txt <- txt[!is.na(txt) & nzchar(txt)]
  if (length(txt) == 0L) return("desconhecido")

  eh_dms     <- mean(grepl("^[0-9]+[NSEWLO]?$|^[0-9]+\\.[0-9]+[NSEWLO]$", txt)) > 0.9 &&
                mean(grepl("[NSEWLO]$", txt)) > 0.9
  eh_decimal <- mean(grepl("^-?[0-9]{1,3}[.,][0-9]+$", txt)) > 0.9

  if (eh_decimal) "decimal" else if (eh_dms) "dms" else "desconhecido"
}
```

#### 1.4 Ler, filtrar e contar

```r
# app/R/ler_helipontos_anac.R
# @produz    data/interim/helipontos_anac.rds
# @consome   data/raw/anac/aerodromos_privados_v2_<data>.csv
# @decisao   decisao:D04
# @tarefa    tarefa:T20.1

#' Lê o cadastro de aeródromos privados da ANAC e devolve os sítios do município.
#'
#' O filtro por município é o passo em que a contagem própria nasce: o número de
#' helipontos de São Paulo que vai para o relatório é `nrow()` do que sai daqui,
#' com a data de extração do arquivo de entrada — e não um dos números
#' jornalísticos que circulam (200, 214, ~400), que são mutuamente
#' inconsistentes e sem rastro.
#'
#' @param caminho_csv caminho do CSV baixado à mão do portal da ANAC
#' @param municipio nome do município como aparece no cadastro
#' @param uf sigla da unidade da federação
#' @param cols mapeamento nome-no-cadastro -> nome-interno, validado à mão
#' @return data frame com id_anac, nome, municipio, uf, tipo, lat, lon
ler_helipontos_anac <- function(caminho_csv,
                                municipio = "SÃO PAULO",
                                uf        = "SP",
                                cols      = c(id_anac   = "CÓDIGO OACI",
                                              nome      = "NOME",
                                              municipio = "MUNICÍPIO",
                                              uf        = "UF",
                                              tipo      = "TIPO",
                                              lat       = "LATITUDE",
                                              lon       = "LONGITUDE")) {
  stopifnot(file.exists(caminho_csv), is.character(cols), !is.null(names(cols)))

  bruto <- readr::read_csv2(caminho_csv,
                            locale = readr::locale(encoding = "latin1"),
                            col_types = readr::cols(.default = readr::col_character()),
                            show_col_types = FALSE)

  faltando <- setdiff(unname(cols), names(bruto))
  if (length(faltando) > 0) {
    stop("Colunas ausentes no CSV da ANAC: ", paste(faltando, collapse = ", "),
         ". Reveja o mapeamento `cols` contra o cabeçalho real do arquivo.")
  }

  d <- bruto[, unname(cols)]
  names(d) <- names(cols)

  d <- dplyr::filter(d,
                     toupper(trimws(municipio)) == toupper(municipio),
                     toupper(trimws(uf))        == toupper(uf))

  fmt_lat <- detectar_formato_coordenada(d$lat)
  fmt_lon <- detectar_formato_coordenada(d$lon)
  if (fmt_lat == "desconhecido" || fmt_lon == "desconhecido") {
    stop("Formato de coordenada não reconhecido. Inspecione: ",
         paste(utils::head(d$lat, 3), collapse = " | "))
  }

  d$lat <- if (fmt_lat == "dms") converter_dms(d$lat) else as.numeric(sub(",", ".", d$lat, fixed = TRUE))
  d$lon <- if (fmt_lon == "dms") converter_dms(d$lon) else as.numeric(sub(",", ".", d$lon, fixed = TRUE))

  attr(d, "formato_coordenada") <- c(lat = fmt_lat, lon = fmt_lon)
  d
}
```

O `stop()` no lugar de um `warning()` é deliberado: coluna renomeada pela ANAC entre versões é
o modo de falha mais provável desta função, e ele precisa ser barulhento.

#### 1.5 A contagem é de vocês

Os números que circulam:

| Número | Fonte | Data | Por que não serve |
| --- | --- | --- | --- |
| **214** helipontos abertos ao tráfego | release oficial da ANAC | **09/02/2009** | oficial, mas **17 anos defasado** |
| **~200** | Flight Consultoria, citando "dados da Prefeitura" | sem data | atribuição indireta, sem rastro à fonte primária |
| **~400** helicópteros em atividade | Prefeitura de SP / SMUL | 18/03/2022 | é **frota**, não infraestrutura — mede aeronave, não sítio |

Os três são mutuamente inconsistentes, e o terceiro nem mede a mesma coisa. **Nenhum entra no
relatório como afirmação sobre o tamanho da infraestrutura.** O 214 pode aparecer, e só, como
referência histórica datada, para dizer "em 2009 a ANAC registrava 214; nossa extração de
[data] devolve N".

A contagem própria sai daqui:

```r
n_helipontos <- nrow(helipontos_anac)
```

E vira um nó `fonte:` no grafo com `N` e a data de extração no campo de descrição. Isso responde
diretamente ao primeiro item da lista do que compromete a nota — dado não rastreável à fonte.

#### 1.6 Sanidade geográfica sem número inventado

A tentação é escrever uma caixa envolvente literal para São Paulo. Não faça isso: derive-a do
próprio contorno do município, que já é um insumo do pacote.

```r
# app/R/validar_coordenadas.R
# @produz    data/interim/helipontos_validados.rds
# @consome   data/interim/helipontos_anac.rds
# @decisao   decisao:D04
# @tarefa    tarefa:T20.1

#' Marca coordenadas implausíveis usando o contorno do município como envelope.
#'
#' A caixa envolvente vem do dado, não de constantes digitadas: latitude e
#' longitude trocadas, sinal invertido e falha do parser DMS produzem pontos
#' fora do envelope, e todos os três são erros que passam despercebidos numa
#' inspeção de planilha.
#'
#' @param helipontos data frame com colunas lat e lon em graus decimais
#' @param municipio_sf polígono do município (qualquer CRS)
#' @param folga_graus margem somada ao envelope, para não descartar sítio de borda
#' @return o mesmo data frame com a coluna lógica `coord_plausivel`
validar_coordenadas <- function(helipontos, municipio_sf, folga_graus = 0.05) {
  stopifnot(is.data.frame(helipontos), inherits(municipio_sf, "sf"), folga_graus >= 0)

  env <- sf::st_bbox(sf::st_transform(sf::st_union(municipio_sf), 4326))

  helipontos$coord_plausivel <-
    !is.na(helipontos$lat) & !is.na(helipontos$lon) &
    helipontos$lon >= env[["xmin"]] - folga_graus &
    helipontos$lon <= env[["xmax"]] + folga_graus &
    helipontos$lat >= env[["ymin"]] - folga_graus &
    helipontos$lat <= env[["ymax"]] + folga_graus

  helipontos
}
```

Registre quantos caíram e por quê. Um sítio com coordenada implausível **não é excluído em
silêncio** — ele vai para uma tabela de descartados que entra no anexo do relatório.

### 2. T20.2 — cruzar com o ROTAER/DECEA

#### 2.1 Por que este passo existe

A ANAC responde "este sítio está cadastrado como aeródromo". O DECEA responde "é possível voar
até ele". São perguntas diferentes, e a segunda é a que decide viabilidade.

A TMA-SP é uma das áreas terminais mais congestionadas do mundo, e o tráfego de asas rotativas
na região metropolitana é gerido pelo **HELICONTROL**, com rotas e altitudes específicas.
Nenhum campo do cadastro da ANAC captura isso. E "limitações operacionais da infraestrutura" é
exigência textual do **§4.3 do enunciado** — ou seja, este cruzamento não é refinamento, é item
avaliado.

#### 2.2 Como extrair

Três caminhos, em ordem de esforço:

1. **API AISWEB** — requer `apiKey` + `apiPass`, cadastro gratuito. É o caminho limpo se a chave
   sair a tempo. **Solicite a chave hoje**, porque o prazo de emissão é desconhecido
   **[A CONFIRMAR]** e ele está no caminho crítico de T20.2.
2. **GeoAISWEB** — visualizador de camadas; serve para conferência visual e, dependendo do que
   expuser, para exportação **[A CONFIRMAR quais camadas são exportáveis]**.
3. **ROTAER completo em PDF** — sempre disponível, sempre trabalhoso. É PDF não estruturado; a
   extração exige parsing. Leia antes o Cap. 1 e 2, que traz a legenda e a convenção de
   apresentação dos dados — parsear sem ele é adivinhar o significado das colunas.

**O ROTAER segue ciclo AIRAC: muda a cada 28 dias.** Duas consequências práticas: registre a
data e o ciclo da extração no nome do arquivo e no nó `fonte:`; e não se surpreenda se o
resultado mudar entre a extração de agosto e uma reconferência de setembro. Se mudar, isso é uma
nota datada, não uma correção silenciosa (regra 7).

O parsing em si é um caso legítimo de `app/py/` — `pdfplumber` extrai tabela de PDF melhor do
que qualquer coisa em R. É a exceção prevista em §3 do `CLAUDE.md`: "só o que não faz sentido em
R". Registre a escolha como decisão, com uma linha de justificativa.

#### 2.3 O que produzir

A junção ANAC × ROTAER é por identificador OACI quando ele existe, e por proximidade geográfica
quando não existe — helipontos frequentemente não têm indicativo de localidade. O resultado é
uma coluna de procedência por sítio:

| Situação | Leitura |
| --- | --- |
| consta na ANAC **e** no ROTAER | candidato forte: cadastrado e conhecido do controle aéreo |
| só na ANAC | cadastro sem contrapartida no espaço aéreo — investigar, não descartar |
| só no ROTAER | infraestrutura conhecida do DECEA fora do cadastro civil consultado — **candidato adicional** |

A terceira linha é a que justifica o cruzamento pagar por si mesmo. Registre a contagem das três
situações; ela é um resultado do trabalho, não um passo intermediário.

Se algo do ROTAER indicar restrição operacional explícita — uso restrito, condição de operação
limitada —, isso vira uma coluna `restricao_operacional` que **entra no filtro de T20.3**, não
uma anotação em texto livre que ninguém consegue consultar depois.

### 3. T20.3 — filtrar por viabilidade urbanística

#### 3.1 A tripla conformidade como critério

Um vertiporto em São Paulo depende de três autorizações independentes:

| Esfera | O que autoriza | Instrumento |
| --- | --- | --- |
| **ANAC** | o sítio como aeródromo | registro/cadastro de aeródromo |
| **DECEA** | o voo até o sítio | espaço aéreo, rotas, procedimentos |
| **Prefeitura** | a obra e a operação no lote | **Alvará de Instalação** + **Auto de Licença de Funcionamento**, renovável a cada 5 anos (ou antes, se a autorização da ANAC vencer primeiro) |

Marco legal municipal: **Lei nº 15.723/2013**, **Decreto nº 58.094/2018**, Portaria
20/2020-SEL/GAB. Órgão: **CONTRU / SMUL**.

A cadeia é conjuntiva: falhar em qualquer uma inviabiliza o sítio. Isso é o que a torna um
critério de filtro de `J`, e não apenas contexto regulatório do relatório.

**Limitação estrutural a registrar, declarada pela própria fonte:** helipontos aprovados **antes
de 23/10/2009** só entram no registro municipal na renovação da licença. Ou seja, **os sítios
mais antigos e consolidados são justamente os que podem faltar no cadastro da Prefeitura.** A
consequência operacional é direta e contraintuitiva: **ausência no cadastro municipal não é
critério de exclusão.** Se fosse, o filtro removeria preferencialmente a infraestrutura mais
estabelecida — exatamente o oposto do que se quer. Ela entra como coluna informativa
`consta_cadastro_municipal`, com a ressalva escrita ao lado.

#### 3.2 O código do cruzamento espacial

```r
# app/R/construir_candidatos.R
# @produz    outputs/candidatos.rds
# @consome   data/interim/helipontos_validados.rds
# @consome   data/raw/geosampa/zoneamento.gpkg
# @consome   data/raw/geosampa/estacoes_transporte.gpkg
# @decisao   decisao:D04
# @tarefa    tarefa:T20.3

#' Constrói o conjunto J de candidatos a vertiporto como objeto sf.
#'
#' Existe para transformar uma tabela de helipontos em um conjunto de decisão
#' georreferenciado e auditável: cada linha carrega a procedência e o motivo de
#' ter sobrevivido ao funil, porque a pergunta da arguição não é "quantos
#' candidatos vocês têm" e sim "por que este e não aquele".
#'
#' O CRS de saída é EPSG:31983 (SIRGAS 2000 / UTM 23S), métrico, porque tudo
#' que vem depois — buffer, distância, área — exige unidade métrica.
#'
#' @param helipontos data frame com lat, lon em graus decimais e coord_plausivel
#' @param zoneamento sf de polígonos do zoneamento (LPUOS) do GeoSampa
#' @param transporte sf de pontos de estações e terminais do GeoSampa
#' @param crs_alvo código EPSG do CRS métrico de trabalho
#' @param raio_transporte_m raio de busca da estação/terminal mais próximo
#' @return sf de pontos com id, nome, procedencia e atributos urbanísticos
construir_candidatos <- function(helipontos,
                                 zoneamento,
                                 transporte,
                                 crs_alvo          = 31983,
                                 raio_transporte_m = 1000) {
  stopifnot(is.data.frame(helipontos),
            inherits(zoneamento, "sf"), inherits(transporte, "sf"),
            raio_transporte_m > 0)

  pontos <- helipontos[!is.na(helipontos$lat) & !is.na(helipontos$lon) &
                         helipontos$coord_plausivel, , drop = FALSE]

  cand <- sf::st_as_sf(pontos, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
  cand <- sf::st_transform(cand, crs_alvo)

  zon  <- sf::st_transform(zoneamento, crs_alvo)
  tra  <- sf::st_transform(transporte, crs_alvo)

  # atributo urbanístico do lote: qual zona de uso contém o sítio
  cand <- sf::st_join(cand, zon[, intersect(names(zon), c("zona", "sigla_zona"))],
                      join = sf::st_intersects, left = TRUE)

  # distância ao nó de transporte mais próximo — insumo do acesso terrestre
  iz <- sf::st_nearest_feature(cand, tra)
  cand$dist_transporte_m <- as.numeric(
    sf::st_distance(cand, tra[iz, ], by_element = TRUE)
  )
  cand$perto_de_transporte <- cand$dist_transporte_m <= raio_transporte_m

  cand$id <- sprintf("J%03d", seq_len(nrow(cand)))
  cand
}
```

`sf::st_join` com `st_intersects` pode devolver mais linhas que a entrada quando um ponto cai
sobre a fronteira de dois polígonos. **Cheque `nrow()` antes e depois.** Se cresceu, resolva o
empate por regra explícita (por exemplo, a zona de maior área na vizinhança) e registre a regra —
não deixe o `distinct()` escolher por ordem de linha.

#### 3.3 Candidatos adicionais por GIS

D4 prevê "alguns sítios adicionais identificados por análise GIS". Dois geradores defensáveis:

**(a) Nós de transporte de alta capacidade.** Terminais de ônibus, estações de metrô e CPTM. A
justificativa é o modelo, não a intuição: a formulação P1 conta a viagem porta-a-porta, e o
tempo de acesso `t_acc` entra na economia `Δ`. Um vertiporto sobre um nó de transporte reduz
`t_acc` para toda a bacia de captação daquele nó. É um candidato bom pela razão certa.

**(b) Eixos de Estruturação da Transformação Urbana (EETU).** São os corredores em que a própria
legislação municipal já admite maior densidade e gabarito. Um sítio ali tem viabilidade
urbanística estruturalmente melhor. **Isso é uma hipótese de trabalho baseada na leitura do
instrumento urbanístico, não uma regra de licenciamento aeronáutico** — declare assim.

Em ambos os casos: gere poucos, marque `procedencia = "gis"`, e **rode o modelo com e sem eles**.
Se a solução ótima não usar nenhum candidato sintético, isso é um resultado forte a favor da tese
de D4 — a infraestrutura existente basta. Se usar, isso também é um resultado: diz onde falta
infraestrutura. Nos dois casos o experimento vale mais que a escolha a priori.

**O que não fazer: k-means sobre a demanda.** Já argumentado em §0. Vale acrescentar o detalhe
que fecha a discussão na arguição: gerar candidatos por clusterização da demanda e depois medir
cobertura da demanda é avaliar o modelo com a informação que foi usada para construí-lo. O
resultado é bom por construção e não distingue uma boa localização de uma ruim.

#### 3.4 O funil, e o dimensionamento de `|J|`

**Por que 40 a 60 e não "todos".** Na formulação P1 (Caminho 1), as **variáveis binárias são
exatamente os `y_j`** — uma por candidato. As `w_qjk` são contínuas em `[0,1]`. O
branch-and-bound ramifica **apenas** sobre variáveis inteiras: a árvore de busca é governada por
`|J|`, não pelo número total de variáveis do modelo.

A consequência é que dobrar `|J|` é qualitativamente pior que dobrar `|Q|`. Mais pares OD deixam
a relaxação linear maior e mais lenta de resolver — custo linear-ish, e a relaxação é um LP.
Mais candidatos deixam o **espaço de busca** maior, no pior caso exponencialmente. Com 200
candidatos, `sum(y_j) <= p` admite `choose(200, p)` combinações; com 50, `choose(50, p)`. Um
MILP não enumera isso, mas a diferença aparece no tamanho da árvore e no *gap* que sobra quando
o tempo acaba.

Há um segundo efeito, mais silencioso: `|J|` entra ao quadrado no conjunto de pares `P_q` de
pré-processamento, porque `(j,k) ∈ J × J`. Com 60 candidatos são até 3.540 pares ordenados
distintos por par OD elegível, antes dos cortes de `t̄` e `θ`. Com 200, são 39.800. O
pré-processamento absorve boa parte, mas o número de colunas `w_qjk` cresce com o produto
`|Q| × |P_q|`, e o alerta de `ompr` acima de ~10⁵ variáveis está em `01-revisao-literatura.md`.

**Como reduzir de ~200 para 40–60 sem arbitrariedade.** Um funil em cascata, com a contagem
registrada em cada degrau:

| Degrau | Critério | Registra |
| --- | --- | --- |
| 0 | extração ANAC, município = São Paulo/SP | `N₀` e a data de extração |
| 1 | coordenada válida e dentro do envelope do município | `N₁`, e a tabela dos descartados |
| 2 | sem restrição operacional bloqueante no ROTAER | `N₂` |
| 3 | fusão de sítios a menos de `raio_conflito_m` — dois helipontos no mesmo quarteirão são um candidato | `N₃` e a regra de fusão |
| 4 | ordenação por critério declarado e corte em `n_alvo` | `N₄` e o critério |

O degrau 4 é o único que exige escolha, e por isso é o que precisa de decisão registrada. Duas
opções defensáveis:

- **Por acessibilidade potencial** — ordenar por população ou por viagens capturáveis nas zonas
  a menos de `t̄` do sítio. Risco: aproxima-se do defeito circular do k-means, mas de forma
  bem mais fraca, porque os sítios continuam sendo os que existem. Se usar, **diga isso no
  relatório** em vez de esperar que perguntem.
- **Por cobertura espacial** — amostragem que garanta representação de cada subprefeitura ou
  macrorregião, evitando que o conjunto herde inteiro o viés de concentração do vetor sudoeste.
  Mais defensável quanto a viés, menos aderente à operação real.

A escolha é de Antônio, registrada em nome dele, e ele a defende na arguição (§4.3 do G00 — não
delegar a escolha de hipóteses). O que **não** é aceitável é cortar em 50 "porque deu 50".

#### 3.5 O mapa

```r
# app/R/plotar_candidatos.R
# @produz    outputs/fig/dados_candidatos.png
# @consome   outputs/candidatos.rds
# @decisao   decisao:D04
# @tarefa    tarefa:T20.3

#' Mapa do conjunto J sobre o contorno do município, colorido por procedência.
#'
#' A procedência precisa estar visível no mapa porque a primeira pergunta que
#' um leitor faz diante de uma nuvem de pontos é de onde ela veio — e a resposta
#' "helipontos que já existem" é o argumento central de decisao:D04.
#'
#' @param candidatos sf de pontos com a coluna procedencia
#' @param municipio_sf sf do contorno do município
#' @param zonas_sf sf das macrozonas OD, opcional, desenhado ao fundo
#' @return objeto ggplot
plotar_candidatos <- function(candidatos, municipio_sf, zonas_sf = NULL) {
  stopifnot(inherits(candidatos, "sf"), inherits(municipio_sf, "sf"))

  p <- ggplot2::ggplot()
  if (!is.null(zonas_sf)) {
    p <- p + ggplot2::geom_sf(data = sf::st_transform(zonas_sf, sf::st_crs(candidatos)),
                              fill = NA, colour = "grey85", linewidth = 0.2)
  }
  p +
    ggplot2::geom_sf(data = sf::st_transform(municipio_sf, sf::st_crs(candidatos)),
                     fill = NA, colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_sf(data = candidatos,
                     ggplot2::aes(shape = procedencia, colour = procedencia),
                     size = 2, alpha = 0.9) +
    ggplot2::labs(
      title    = "Conjunto de candidatos a vertiporto",
      subtitle = sprintf("|J| = %d; municipio de Sao Paulo; EPSG:%s",
                         nrow(candidatos), sf::st_crs(candidatos)$epsg),
      caption  = "Fonte: ANAC, Lista de Aerodromos Privados V2, extracao de [data]; ROTAER/DECEA; GeoSampa"
    ) +
    ggplot2::theme_minimal()
}
```

O `caption` com a data de extração não é enfeite: é o que permite responder "de quando é este
mapa" sem abrir o código, e é a mesma exigência que faz a §7 do G00 perguntar qual script gerou a
figura da página 12.

#### 3.6 Os alvos no pipeline

```r
# fragmento de _targets.R
tar_target(municipio_sp,      sf::st_read("data/raw/geosampa/municipio.gpkg", quiet = TRUE)),
tar_target(zoneamento_sp,     sf::st_read("data/raw/geosampa/zoneamento.gpkg", quiet = TRUE)),
tar_target(transporte_sp,     sf::st_read("data/raw/geosampa/estacoes_transporte.gpkg", quiet = TRUE)),

tar_target(anac_csv,          "data/raw/anac/aerodromos_privados_v2_2026-08-25.csv",
                              format = "file"),
tar_target(helipontos_anac,   ler_helipontos_anac(anac_csv)),
tar_target(helipontos_val,    validar_coordenadas(helipontos_anac, municipio_sp)),
tar_target(candidatos,        construir_candidatos(helipontos_val, zoneamento_sp,
                                                   transporte_sp),
                              format = "rds"),
tar_target(fig_candidatos,    plotar_candidatos(candidatos, municipio_sp))
```

`format = "file"` no CSV é o que faz o `targets` invalidar a jusante quando o arquivo de entrada
for reextraído. Sem isso, uma nova extração da ANAC não reprocessa nada e o mapa fica velho sem
avisar.

---

## Critério de pronto

- [ ] `decisao:D04` existe em YAML, com as três alternativas descartadas e assinada por Antônio.
- [ ] O CSV da ANAC está em `app/data/raw/anac/` com a data de extração no nome e versionado.
- [ ] `outputs/candidatos.rds` existe, é `sf`, e `sf::st_crs(candidatos)$epsg == 31983`.
- [ ] `40 <= nrow(candidatos) <= 60`.
- [ ] Nenhum `NA` em geometria; todos os pontos dentro do envelope do município.
- [ ] Toda linha tem `id` estável, `procedencia` ∈ {anac, rotaer, gis} e o degrau do funil em que
      entrou.
- [ ] A tabela do funil (`N₀`…`N₄`) está registrada, com a contagem de cada degrau.
- [ ] A tabela de sítios **descartados**, com motivo, existe e está salva — descarte sem registro
      é indistinguível de erro de parser.
- [ ] `fonte:` registradas no grafo para ANAC, ROTAER/DECEA e GeoSampa, cada uma com limitações.
- [ ] `outputs/fig/dados_candidatos.png` gerado pelo pipeline, não à mão.
- [ ] `targets::tar_outdated()` sai vazio.
- [ ] O validador do grafo passa.

---

## Armadilhas conhecidas

**O download da ANAC devolve HTML e o `readr` não reclama.** O CAPTCHA do `gov.br` responde com
status 200 e corpo HTML. O sintoma é um data frame de uma coluna com `<!DOCTYPE html>` na
primeira linha. Confira `ncol()` logo após a leitura.

**Encoding errado zera o filtro por município.** Se o arquivo for `latin1` e for lido como UTF-8,
"SÃO PAULO" não casa com nada e o resultado é zero linhas — que parece um filtro funcionando.
Um `nrow() == 0` depois do filtro deve parar o pipeline, não seguir adiante.

**Latitude e longitude trocadas.** Sobrevive à conversão DMS sem erro nenhum e produz uma nuvem
de pontos no oceano Índico. O envelope de `validar_coordenadas()` pega — desde que o envelope
venha do contorno do município, e não de constantes digitadas de memória.

**Parser DMS de largura fixa.** `substr(x, 1, 2)` funciona na latitude e quebra na longitude,
onde o grau tem três dígitos. O erro resultante é de ~1°, ou seja, ~100 km: longe demais para
passar no envelope, mas se o envelope for frouxo passa. Use a regex ancorada.

**`st_join` duplicando linhas.** Ponto sobre fronteira de dois polígonos de zoneamento vira duas
linhas. Se ninguém checar, `|J|` cresce sozinho e aparecem dois candidatos idênticos com ids
diferentes — que o solver trata como sítios independentes, inflando a cobertura.

**Reprojetar depois de calcular.** `st_distance` e `st_buffer` sobre EPSG:4326 devolvem graus,
não metros, e o `sf` avisa mas segue. Transforme para 31983 **antes** de qualquer operação
métrica. Regra: só existe um CRS no projeto depois da leitura.

**Dois helipontos no mesmo edifício.** Lajes vizinhas, ou cadastro duplicado do mesmo sítio,
aparecem como candidatos distintos a poucos metros. Para o modelo eles são quase intercambiáveis,
e a solução ótima fica instável entre eles sem que nada de fato mude. Funda-os no degrau 3.

**O ROTAER mudou entre a extração e a conferência.** Ciclo AIRAC de 28 dias. Se o número de
sítios divergir de uma semana para outra, isso é esperado e vira nota datada — não conserto em
silêncio (regra 7).

**Excluir sítio ausente do cadastro municipal.** É a armadilha invertida: como o cadastro exclui
estruturalmente o que foi aprovado antes de 23/10/2009, filtrar por ele remove preferencialmente
os helipontos mais consolidados. `consta_cadastro_municipal` é informativo, nunca eliminatório.

**Aceitar o número de heliponto que já se sabia.** Se a contagem der perto de 200 ou de 214, a
tentação é validar por coincidência com o número jornalístico. Não é validação: é a única
verificação que os números jornalísticos permitem, e eles não têm rastro. Se der bem diferente,
investigue a diferença e escreva o que encontrou — isso é resultado, não problema.

---

## O que registrar

**Decisões**

- `decisao:D04` — candidatos = helipontos existentes + sítios GIS. Alternativas descartadas já
  redigidas em `03-encontro-26-08.md`; transcreva com o motivo específico de cada rejeição.
- Decisão sobre o **critério do degrau 4** do funil (acessibilidade vs. cobertura espacial), com
  `n_alvo` como parâmetro e a alternativa descartada.
- Decisão sobre `raio_conflito_m` e a regra de fusão de sítios coincidentes.
- Decisão sobre usar Python (`pdfplumber`) para o parsing do ROTAER, se for o caminho escolhido.

**Fontes** — cada uma com origem, formato, cobertura e limitações:

| `fonte:` | Limitação obrigatória no registro |
| --- | --- |
| `fonte:anac-aerodromos-v2` | reflete **cadastro, não operação real**; coordenadas em DMS; CAPTCHA impede automação; **N e data de extração no corpo do registro** |
| `fonte:rotaer` | PDF não estruturado; **ciclo AIRAC de 28 dias**; API exige chave |
| `fonte:geosampa` | **só o município**; CAPTCHA; datas de atualização heterogêneas por camada |
| `fonte:licenciamento-smul` | registro estruturalmente incompleto antes de 23/10/2009 |

**Pendências**

- `pendencia:` para a chave da API AISWEB enquanto não sair, com aresta `BLOQUEIA tarefa:T20.2`.
- `pendencia:` para cada `[A CONFIRMAR]` que sobrar (INDE/robots.txt, camadas exportáveis do
  GeoAISWEB, `raio_conflito_m`).

**Notas em tarefa** — datadas e assinadas: a contagem de cada degrau do funil; o viés herdado do
cadastro (escrever **antes** de rodar o modelo); a divergência entre a contagem própria e os
números que circulam.

**Arquivos** — `arquivo:app-R-construir-candidatos`, `arquivo:app-R-converter-dms`,
`arquivo:app-R-plotar-candidatos`, com aresta `PRODUZ` para `outputs/candidatos.rds` e para a
figura. Os cabeçalhos de proveniência já escritos acima são o que o compilador lê.

**Interação de IA** — se o parser ou o texto saiu de sessão com IA, `ia:` com `critica_humana`
não-vazia. Aponte pelo menos: quais colunas do CSV foram presumidas e não verificadas, e que a
faixa 40–60 é escolha de tratabilidade do grupo, não resultado medido.

---

## Como isso vira relatório

**Seção de dados.** A tabela do funil (`N₀`…`N₄`) é a figura da seção — ela mostra em uma imagem
que o conjunto `J` foi construído por critérios, e não escolhido. Acompanha o mapa
`dados_candidatos.png` e a frase que ancora a contagem: "a extração de [data] da Lista de
Aeródromos Privados V2 da ANAC, filtrada por município = São Paulo/SP, devolve N sítios".

**Seção de metodologia.** O argumento de §0 — por que infraestrutura existente e não candidatos
sintéticos — com a citação de Ribeiro et al. (2023) e o contraste explícito com a clusterização
de Chicago, Munique e Pequim. É aqui que o trabalho se distingue da literatura, e vale escrever
com cuidado.

**Seção de limitações (§4.3 do enunciado).** Três itens, todos já levantados aqui: a incompletude
estrutural do cadastro municipal anterior a 23/10/2009; a defasagem do ROTAER pelo ciclo AIRAC; e
o viés de concentração herdado do cadastro de helipontos, que é aviação corporativa. O critério
de excelência do enunciado inclui "mostra o que não funcionou, e por quê" — e reconhecer a
limitação do próprio dado é o que o §3.2 valoriza sobre apresentá-lo sem ressalva.

**Seção de resultados computacionais.** `|J|` é metade da descrição da instância — o indicador
comum exigido a todos os grupos pede tamanho da instância junto com valor da FO e tempo de
solução. O argumento de §3.4, de que são os `y_j` binários que governam o branch-and-bound, é o
que transforma "temos 50 candidatos" em uma justificativa de engenharia.

**Arguição.** As duas perguntas prováveis: *"por que 50 e não 200?"* — respondida por §3.4 mais o
registro do degrau 4; e *"vocês não escolheram os candidatos onde já sabiam que havia demanda?"* —
respondida por §0 mais o experimento com e sem os candidatos sintéticos de §3.3.
