# G03 — O filtro de demanda capturável

> **Pacote de trabalho de Pedro Karbage.** Prazo: **02/09/2026**.
> Depende inteiramente do G02. Leia o `G00-como-trabalhar.md` antes deste.

---

## 1. Objetivo

Ao fim deste pacote existe, em `app/outputs/`, uma **matriz de pares origem-destino
plausivelmente capturáveis por mobilidade aérea urbana** — um subconjunto pequeno e justificado
da matriz de macrozonas do G02 — junto com o **diário de calibração** que registra cada
combinação de limiares testada e o que ela produziu.

O que se entrega aqui não é principalmente um arquivo. É uma **posição defendida**: quais
viagens paulistanas fazem sentido migrar para o ar, sob que condições, e com que sustentação em
dado ou literatura.

---

## 2. Tarefas no grafo

| Id | Título | Prazo | Depende de |
| --- | --- | --- | --- |
| `tarefa:T12` | Definir e aplicar o filtro de demanda capturável | 02/09 | `tarefa:T11` |

Realiza `meta:M1`, atribuída a `pessoa:pedro`. A decisão que ela materializa é a
**`decisao:D03`**.

**Bloqueio ativo:** `pendencia:P01` tem aresta `BLOQUEIA` para `tarefa:T12`. Se os microdados da
OD 2023 existirem, a base do filtro muda e este pacote inteiro se reexecuta sobre outro dado. A
T10.2 do G02 é quem resolve isso — e é por isso que ela tem prazo de 26/08 e não de 02/09.

---

## 3. Pré-requisitos

- **G02 concluído**, com o critério de pronto inteiro cumprido. Em particular:
  `validar_expansao()` reproduzindo os 42 milhões de viagens/dia. Filtrar um dado mal expandido
  produz uma seleção corretíssima de viagens erradas.
- `app/outputs/od_macrozonas.rds` — matriz OD entre macrozonas, expandida por `FE_via`,
  calibrada pelo nível de 2023, em EPSG:31983.
- **Centroides das macrozonas** em EPSG:31983, para a distância em linha reta.
- Os nomes reais das variáveis de **motivo** e de **renda** confirmados no layout do ZIP (passo
  5.3 do G02). Este pacote não pode começar com `[PREENCHER]` em nenhum dos dois.
- Ter lido a `decisao:D03` em `docs/03-encontro-26-08.md` §D3.
- Ter lido as fichas de **Wu & Zhang (2021)**, **Rimjha et al. (2021)** e **Volakakis &
  Mahmassani (2025)** em `docs/01-revisao-literatura.md` §2.2.

---

## 4. Insumos

### 4.1 A pergunta, na letra do enunciado

> *"Que parcela da mobilidade paulistana faria sentido migrar para o ar, sob que condições, e
> por quê?"*

E o enunciado **deliberadamente não sugere critérios**. Isso não é omissão — é o objeto da
avaliação. A estratégia adotada, seus parâmetros e sua sustentação em dado ou literatura são
**parte do que se avalia**, e é por isso que este pacote tem um guia próprio apesar de conter
uma única tarefa.

A regra do `G00` §4.3 se aplica com força máxima aqui: **a escolha dos limiares não se delega.**
A IA pode listar opções e trazer a literatura de apoio; a escolha é registrada em nome de uma
pessoa, e essa pessoa a defende na arguição.

### 4.2 As quatro camadas decididas (`decisao:D03`)

Capturável é a viagem que satisfaz **simultaneamente**:

| Camada | Critério | Parâmetro | Faixa de sensibilidade |
| --- | --- | --- | --- |
| Distância | ≥ 15 km em linha reta | `dist_min_km` | 10 · 12 · 15 · 20 · 25 |
| Duração terrestre | ≥ 45–60 min declarados na OD | `dur_min_min` | 30 · 40 · 45 · 60 · 75 |
| Motivo | trabalho / negócios | `motivos` | + estudo · + saúde · todos |
| Renda | faixas superiores da OD | `faixas_renda` | só a mais alta · duas mais altas · três |

### 4.3 A literatura que sustenta cada camada

Os números abaixo foram confirmados em metadado bibliográfico e nas fichas de
`docs/01-revisao-literatura.md`. Onde o texto integral não foi lido, isso está dito.

**Wu, Z. & Zhang, Y. (2021).** *Integrated Network Design and Demand Forecast for On-Demand
Urban Air Mobility.* **Engineering** 7(4), 473–487. DOI `10.1016/j.eng.2020.11.007`.
Filtram por **≥ 10 milhas / ≥ 30 min** sobre **266.734 viagens candidatas** do Tampa Bay
Regional Planning Model, e chegam a **532 viagens efetivamente UAM** — cerca de **0,20% de
adoção**. Sem logit: regra determinística de utilidade, em que o usuário migra se o valor do
tempo economizado supera o custo adicional.

**Rimjha, M., Hotle, S., Trani, A. & Hinze, N. (2021).** *Commuter demand estimation and
feasibility assessment for Urban Air Mobility in Northern California.* **Transportation Research
Part A** 148, 506–524. DOI `10.1016/j.tra.2021.03.020`.
Parâmetros operacionais explícitos: **distância mínima de voo de 10 milhas**, **velocidade média
120 mph**, **5 min de ingresso/egresso**, **load factor 60%** (2,4 pax/veículo). Conclusão dura:
a viabilidade econômica **exige tarifas irrealisticamente baixas** dado o custo imobiliário, e a
confiabilidade precisa igualar a do automóvel. Padrões de *commute* fortemente direcionais.

**Volakakis, V. & Mahmassani, H.S. (2025).** *Strategic Vertiport Placement for Airport Access.*
**Infrastructures** 10(9), 242. DOI `10.3390/infrastructures10090242`.
Identificam a demanda UAM potencial a partir de automóvel, transporte público, táxi e
ride-hailing **por limiares de tempo e distância** — mesma família de filtro que a nossa — e
obtêm **6.124 solicitações/dia** em Chicago no cenário moderado.

### 4.4 A conclusão para a qual a literatura converge

**A fatia capturável é pequena, e é muito sensível à tarifa.**

Três trabalhos independentes, em três metrópoles diferentes, com métodos diferentes — regra
determinística de utilidade, logit condicional, limiar de tempo/distância — chegam à mesma
ordem de grandeza: alguns milhares de viagens por dia numa região metropolitana inteira, ou
frações de ponto percentual do total.

Isso tem uma consequência operacional direta e desconfortável: **um filtro generoso produz
demanda fantasma.** E um modelo de localização construído sobre demanda inventada é, na palavra
do próprio enunciado, um **exercício de aritmética** — não engenharia. O modelo continua
rodando, o solver continua devolvendo uma solução ótima, os mapas continuam bonitos. Só que a
resposta é para outra cidade.

O erro nesta direção é assimétrico e é por isso que se prefere errar apertado: um filtro
apertado demais produz uma instância pequena e uma conclusão modesta, que é honesta e
defensável. Um filtro frouxo produz uma instância grande, uma conclusão ambiciosa, e um
resultado indefensável na arguição.

### 4.5 Um ponto de método que é fácil errar

Nosso filtro **não é** o análogo dos 0,20% de Wu & Zhang. É o análogo das **266.734 viagens
candidatas** — o passo geométrico anterior.

A queda de 266.734 para 532 vem de um segundo estágio: a regra de utilidade que compara tempo
economizado com custo adicional. Nós não temos esse segundo estágio, porque a `decisao:D03` já
descartou o logit calibrado (não existe logit de UAM calibrado para o Brasil, e transplantar β's
de Munique ou da Califórnia introduziria parâmetro sem procedência brasileira).

**Portanto: a matriz que sai deste pacote é um limite superior da demanda, não uma previsão de
adoção.** Essa frase precisa estar no relatório com essas palavras. Chamar o resultado do filtro
de "demanda UAM" sem a ressalva é exatamente o tipo de imprecisão que a arguição encontra.

---

## 5. Passo a passo

### 5.1 Camada 1 — distância em linha reta

**Justificativa:** abaixo de certa distância o tempo de solo — deslocamento até o vertiporto,
embarque, espera, desembarque, deslocamento até o destino final — consome inteiramente o ganho
do trecho aéreo. A viagem porta-a-porta fica mais lenta que de carro, e a mais cara também.

**Sustentação:** Wu & Zhang usam **≥ 10 milhas** (≈ 16,1 km); Rimjha et al. usam **distância
mínima de voo de 10 milhas**, com **5 min de ingresso e egresso** e velocidade média de
**120 mph**. Duas fontes independentes convergem na mesma ordem de grandeza, e nosso **15 km**
fica ligeiramente abaixo de ambas — o que é conservador na direção certa (mais permissivo), e
por isso a sensibilidade precisa testar valores acima.

**Parâmetro:** `dist_min_km = 15`. **Faixa a testar:** 10, 12, 15, 20, 25.

⚠️ **Linha reta, não rota.** É deliberado: a distância em linha reta aproxima o trecho aéreo,
que é o que a UAM percorre. A distância rodoviária entre as mesmas macrozonas é maior e é
matéria do G05. Não misture as duas — e nomeie a coluna `dist_reta_km`, não `dist_km`, para que
ninguém as confunda três semanas depois.

⚠️ **Distância entre centroides de macrozona.** Depois da agregação do G02, a menor unidade
espacial é a macrozona, e a distância é centroide a centroide. Para macrozonas grandes na
periferia isso introduz erro de vários quilômetros, e o erro é maior justamente perto do limiar,
onde ele decide a inclusão. Registre como limitação.

### 5.2 Camada 2 — duração terrestre declarada

**Justificativa:** esta é a camada mais forte das quatro, e por um motivo específico de São
Paulo: **a duração declarada na OD já embute o congestionamento real.** Não é tempo de rota
livre calculado por um roteador; é o tempo que a pessoa disse ter levado, num dia útil típico,
com o trânsito que existe. A OD é a única das três fontes de tempo do projeto que tem essa
propriedade — OSRM roteia em free-flow e subestima o pico, que é exatamente quando a UAM ganha.

Em outras palavras: a duração declarada mede diretamente a dor que a UAM se propõe a resolver.

**Sustentação:** Wu & Zhang filtram por **≥ 30 min**; Volakakis & Mahmassani identificam demanda
potencial por limiares de tempo e distância. Nosso **45–60 min** é mais restritivo que os 30 min
de Wu & Zhang, o que é coerente com uma cidade em que 30 minutos de deslocamento é rotina banal
e não motivo para pagar tarifa premium.

**Parâmetro:** `dur_min_min = 45`, com 60 como cenário conservador. **Faixa:** 30, 40, 45, 60,
75.

⚠️ **A duração na OD é da viagem inteira, incluindo acesso e espera**, conforme a definição que
está no `Manual` dentro do ZIP. Leia essa definição antes de comparar com qualquer tempo
calculado. E note que a duração vem no nível viagem — para levá-la ao nível par de macrozonas é
preciso **média ponderada por `FE_via`**, nunca `mean()`.

### 5.3 Camada 3 — motivo da viagem

**Justificativa:** o valor do tempo é o que paga a tarifa. Viagens a trabalho e a negócios são o
segmento com maior valor do tempo e maior disposição a pagar, e frequentemente com o custo
absorvido pelo empregador — o que desloca a decisão do bolso do usuário.

**Sustentação:** Rimjha et al. (2021, AIAA) modelam explicitamente **dois logits condicionais
separados, um para negócios e outro para não-negócios**, o que é reconhecimento formal de que os
dois segmentos têm comportamento distinto. Rimjha et al. (2021, TRA) constatam padrões de
*commute* fortemente direcionais, com um distrito de negócios funcionando como hub dominante —
padrão que São Paulo replica com o eixo Faria Lima / Berrini / Itaim.

**Parâmetro:** `motivos = c("trabalho", "negocios")`. **Faixa:** só negócios; trabalho +
negócios; + estudo; + saúde; todos os motivos.

⚠️ **Motivo na origem ou no destino?** A OD registra **os dois**. Uma viagem casa→trabalho tem
motivo de destino "trabalho"; a volta trabalho→casa tem motivo de origem "trabalho" e motivo de
destino "residência". Filtrar só por motivo de destino **descarta metade do fluxo pendular** — e
o modelo é bilateral, então perder a volta distorce a estrutura da matriz, não só o volume.
**Decida explicitamente**, registre, e o mais defensável é aceitar a viagem se **qualquer uma
das duas pontas** for trabalho ou negócios.

⚠️ Rimjha et al. recomendam, na conclusão, **incluir propósitos além de commuting**. Isso é uma
crítica direta à camada 3 vinda de uma das fontes que a sustentam, e vale registrá-la — o
cenário "todos os motivos" da sensibilidade é a resposta a ela.

### 5.4 Camada 4 — renda

**Justificativa:** a UAM é serviço premium em qualquer cenário de tarifa considerado seriamente
na literatura. Rimjha et al. concluem que a viabilidade econômica **exige tarifas
irrealisticamente baixas**; se nem com tarifa irrealista fecha a conta, modelar demanda sem
recorte de renda é fingir um mercado que não existe.

**Parâmetro:** `faixas_renda = c(4, 5)` — as duas faixas superiores. **Faixa a testar:** só a
faixa 5; as duas superiores; as três superiores; sem filtro de renda.

⚠️ **A OD é estratificada por cinco faixas de renda.** A codificação exata da variável de faixa
sai do layout dentro do ZIP — **não programe contra `c(4, 5)` sem confirmar o que 4 e 5
significam.** Se a codificação for invertida, o filtro seleciona precisamente o público errado e
o resultado sai plausível.

**De onde vem a renda — e a alternativa descartada:**

Use a **renda da própria OD**. Ela está no banco, tem fator de expansão, e já está **na
geografia de zona OD**. Cruzar com setor censitário exigiria compatibilização areal — repartir
valores de uma malha para outra por área ou por população —, o que introduz erro de agregação
numa variável que é a mais sensível das quatro camadas.

| Opção | A favor | Contra | Veredito |
| --- | --- | --- | --- |
| **Renda da OD** | Mesma geografia, mesmo fator de expansão, mesma pesquisa | Resolução espacial limitada à zona/macrozona | **Escolhida** |
| Censo 2010 por setor censitário | Muito mais fino espacialmente | **16 anos de defasagem**; exige compatibilização areal | Descartada |
| Censo 2022 — Agregados por Setores | Recente | **Rendimento não coletado no universo com a granularidade de 2010**; renda detalhada só em recorte mais agregado **[A CONFIRMAR quais variáveis de rendimento estão nos Agregados 2022]** | Descartada |

⚠️ **Nível do fator, de novo.** Renda é atributo de **domicílio/família**, não de viagem. A
renda média de uma macrozona se calcula com `FE_pes` (ou `FE_dom`) sobre a tabela desduplicada,
não com `FE_via` sobre a tabela achatada. Ver G02 §5.6 — o erro é o mesmo, e aqui ele enviesa
justamente a variável de corte.

⚠️ **A camada de renda é a mais contestável das quatro, e isso é bom.** Ela embute um juízo
sobre quem a política pública deve servir, e a literatura de equidade em UAM (Volakakis &
Mahmassani 2024) existe precisamente para questioná-lo. Rodar o cenário **sem filtro de renda**
não é só sensibilidade: é a base do parágrafo de equidade do relatório, e a resposta pronta para
a pergunta que vai vir na arguição.

### 5.5 A implementação

Os quatro limiares entram como **parâmetros**, nunca como constantes literais — regra 8 do
`CLAUDE.md`, e o motivo é operacional: número mágico no meio do código é um experimento que não
vai poder ser rodado.

```r
# app/R/filtrar_captura.R
# @produz    outputs/od_capturavel.rds
# @consome   data/interim/od_macrozonas.rds
# @decisao   decisao:D03
# @tarefa    tarefa:T12

#' Filtra a matriz OD para os pares plausivelmente capturáveis por UAM.
#'
#' A fração capturável é a primeira decisão difícil do projeto e o enunciado
#' deliberadamente não sugere critérios (§3.3). As quatro camadas abaixo são a decisão do
#' grupo, registrada em decisao:D03, e são parâmetros e não constantes porque viram a
#' análise de sensibilidade da S3.
#'
#' O resultado é um LIMITE SUPERIOR da demanda, não uma previsão de adoção: não há
#' segundo estágio de escolha modal (a decisao:D03 descartou o logit por ausência de
#' calibração brasileira). Wu & Zhang (2021) mostram que o segundo estágio reduz as
#' viagens candidatas em cerca de duas ordens de grandeza.
#'
#' @param od data frame por par de macrozonas, com viagens_dia já expandida e calibrada
#' @param dist_min_km distância mínima em linha reta entre centroides. Ver decisao:D03
#' @param dur_min_min duração terrestre declarada mínima, em minutos
#' @param motivos vetor de motivos aceitos
#' @param faixas_renda vetor de faixas de renda aceitas
#' @param ponta se "qualquer", aceita a viagem se origem OU destino tiver motivo elegível
#' @return data frame com macro_o, macro_d, viagens_dia e os atributos usados no filtro
filtrar_captura <- function(od,
                            dist_min_km  = 15,
                            dur_min_min  = 45,
                            motivos      = c("trabalho", "negocios"),
                            faixas_renda = c(4, 5),
                            ponta        = c("qualquer", "destino")) {
  stopifnot(is.data.frame(od),
            dist_min_km > 0, dur_min_min > 0,
            length(motivos) > 0, length(faixas_renda) > 0,
            all(c("macro_o", "macro_d", "viagens_dia",
                  "dist_reta_km", "dur_terrestre_min",
                  "motivo_o", "motivo_d", "faixa_renda") %in% names(od)))
  ponta <- match.arg(ponta)

  ok_motivo <- switch(
    ponta,
    qualquer = od$motivo_o %in% motivos | od$motivo_d %in% motivos,
    destino  = od$motivo_d %in% motivos
  )

  od[
    od$dist_reta_km      >= dist_min_km  &
    od$dur_terrestre_min >= dur_min_min  &
    ok_motivo                            &
    od$faixa_renda       %in% faixas_renda,
    ,
    drop = FALSE
  ]
}
```

A distância em linha reta, calculada uma vez sobre os centroides:

```r
# app/R/distancia_pares.R
# @produz    data/interim/dist_pares.rds
# @consome   data/interim/macrozonas.rds
# @decisao   decisao:D03
# @tarefa    tarefa:T12

#' Distância em linha reta entre centroides de macrozona, em quilômetros.
#'
#' Linha reta e não rota: aproxima o trecho aéreo, que é o que a UAM percorre. A distância
#' rodoviária é outro objeto e pertence ao G05. Exige CRS métrico — daí o stopifnot.
#'
#' @param macrozonas objeto sf das macrozonas, em CRS métrico (EPSG:31983)
#' @param col_id nome da coluna de identificador da macrozona
#' @return data frame com macro_o, macro_d, dist_reta_km
distancia_pares <- function(macrozonas, col_id = "macrozona") {
  stopifnot(inherits(macrozonas, "sf"), col_id %in% names(macrozonas))

  crs <- sf::st_crs(macrozonas)
  if (is.na(crs) || isTRUE(sf::st_is_longlat(macrozonas))) {
    stop("Macrozonas em coordenadas geograficas ou sem CRS. ",
         "Reprojetar para EPSG:31983 antes: distancia em graus comparada com ",
         "limiar em km produz um filtro que parece funcionar e nao funciona.")
  }

  cent <- sf::st_centroid(sf::st_geometry(macrozonas))
  ids  <- macrozonas[[col_id]]

  m <- sf::st_distance(cent, cent)                 # matriz de unidades 'm'
  km <- units::set_units(m, "km")

  expand.grid(macro_o = ids, macro_d = ids, KEEP.OUT.ATTRS = FALSE,
              stringsAsFactors = FALSE) |>
    dplyr::mutate(dist_reta_km = as.numeric(as.vector(km))) |>
    dplyr::filter(macro_o != macro_d)
}
```

E a duração terrestre declarada, agregada ao nível par com o peso certo:

```r
#' Duração terrestre média declarada por par de macrozonas, ponderada por FE_viagem.
#'
#' Ponderada porque a OD é amostra estratificada: mean() simples devolve a média da
#' amostra, enviesada exatamente na dimensão de renda que a camada 4 usa para filtrar.
#'
#' @param od_viagens data frame no nível viagem, com macro_o, macro_d, duracao e fe_via
#' @return data frame com macro_o, macro_d, dur_terrestre_min
duracao_por_par <- function(od_viagens) {
  stopifnot(all(c("macro_o", "macro_d", "duracao", "fe_via") %in% names(od_viagens)))

  od_viagens |>
    dplyr::filter(!is.na(duracao), duracao > 0, !is.na(fe_via)) |>
    dplyr::group_by(macro_o, macro_d) |>
    dplyr::summarise(
      dur_terrestre_min = sum(duracao * fe_via) / sum(fe_via),
      .groups = "drop"
    )
}
```

Os alvos, no `_targets.R`:

```r
list(
  # ... alvos do G02 ...
  tar_target(dist_pares,    distancia_pares(macrozonas)),
  tar_target(dur_pares,     duracao_por_par(od_macro_viagens)),
  tar_target(od_atributos,  montar_atributos_par(od_macro, dist_pares, dur_pares)),
  tar_target(od_capturavel, filtrar_captura(od_atributos,
                                            dist_min_km  = 15,
                                            dur_min_min  = 45,
                                            motivos      = c("trabalho", "negocios"),
                                            faixas_renda = c(4, 5))),
  tar_target(diario,        diario_calibracao(od_atributos, grade_limiares()))
)
```

Repare que os quatro limiares aparecem **explicitamente no `_targets.R`**, não escondidos como
default dentro da função. Os defaults existem para documentar a decisão; os valores efetivos
ficam visíveis no único arquivo de orquestração do projeto, que é onde alguém que abre o
repositório procura por eles.

### 5.6 Os sanity checks obrigatórios

Nenhum é opcional. Os três respondem perguntas que a arguição faz.

#### Check 1 — que fração das viagens totais sobra?

```r
#' @param od_total matriz OD completa entre macrozonas
#' @param od_filtrada saída de filtrar_captura()
#' @return data frame com pares e viagens, absolutos e relativos
resumir_captura <- function(od_total, od_filtrada) {
  data.frame(
    pares_total      = nrow(od_total),
    pares_capturav   = nrow(od_filtrada),
    frac_pares       = nrow(od_filtrada) / nrow(od_total),
    viagens_total    = sum(od_total$viagens_dia),
    viagens_capturav = sum(od_filtrada$viagens_dia),
    frac_viagens     = sum(od_filtrada$viagens_dia) / sum(od_total$viagens_dia)
  )
}
```

**Como ler `frac_viagens`:**

| Faixa | Leitura |
| --- | --- |
| **acima de ~2%** | Filtro frouxo. Comparado com a literatura, é demanda fantasma. Aperte antes de prosseguir |
| **entre ~1% e ~2%** | Plausível como **limite superior** de demanda potencial, dado que não há segundo estágio de escolha modal |
| **abaixo de ~0,5%** | Filtro apertado. Pode ser correto, mas confira se a instância ainda tem pares suficientes para o modelo bilateral fazer sentido |
| **zero pares** | Bug antes de resultado. Comece pela unidade da distância |

⚠️ **Esse corte de 1–2% é uma heurística de calibração do grupo, não um número publicado.**
Ele foi construído por analogia: Wu & Zhang partem de 266.734 candidatas e chegam a 532 (0,20%)
após o estágio de utilidade; nosso filtro corresponde ao estágio anterior, então nossa fração
tem que ser maior que 0,20% e ainda assim pequena. **Escreva no relatório que é heurística do
grupo.** Apresentá-lo como se fosse valor de referência da literatura seria exatamente o tipo de
número não rastreável que a regra 3 do `CLAUDE.md` proíbe.

**Segunda âncora, mais concreta:** Volakakis & Mahmassani (2025) obtêm **6.124 solicitações/dia**
em Chicago no cenário moderado. É outra cidade, outro recorte (acesso aeroportuário) e outra
metodologia — mas é a ordem de grandeza que se espera de uma metrópole. Se a nossa matriz
capturável somar centenas de milhares de viagens/dia, **não é a São Paulo que é diferente; é o
filtro que está errado.**

#### Check 2 — onde estão espacialmente os pares que sobram?

```r
#' @param od_filtrada saída de filtrar_captura()
#' @param macrozonas objeto sf das macrozonas
#' @return sf com viagens capturáveis geradas e atraídas por macrozona
concentracao_espacial <- function(od_filtrada, macrozonas) {
  ger <- od_filtrada |>
    dplyr::group_by(macrozona = macro_o) |>
    dplyr::summarise(geradas = sum(viagens_dia), .groups = "drop")
  atr <- od_filtrada |>
    dplyr::group_by(macrozona = macro_d) |>
    dplyr::summarise(atraidas = sum(viagens_dia), .groups = "drop")

  macrozonas |>
    dplyr::left_join(ger, by = "macrozona") |>
    dplyr::left_join(atr, by = "macrozona") |>
    tidyr::replace_na(list(geradas = 0, atraidas = 0))
}
```

Calcule também a concentração: a fração das viagens capturáveis nas 5 e nas 10 macrozonas de
maior atração.

**Se todos os pares que sobram estiverem no quadrilátero Itaim / Faria Lima / Berrini, isso é um
achado a discutir, não um bug a esconder.** É a confirmação empírica, com dado paulistano, de
que a UAM se comporta como infraestrutura de elite — e é consistente com Rimjha et al., que
encontram padrões de *commute* fortemente direcionais com um distrito de negócios como hub
dominante.

Esse resultado é material de **três** seções do relatório: resultados, equidade e limitações. O
que seria erro metodológico é o inverso — escolher critérios que evitem esse resultado para
produzir um mapa mais confortável. A `decisao:D01` já registrou isso ao descartar a alternativa
"só o quadrilátero central expandido", pelo motivo de que ela **enviesaria o resultado para a
conclusão que se quer testar, em vez de deixá-la emergir do modelo**. O mesmo raciocínio vale na
direção contrária.

#### Check 3 — distribuição de distância e duração dos pares capturáveis

```r
#' @param od_filtrada saída de filtrar_captura()
#' @return data frame com quantis ponderados por viagens_dia
perfil_capturavel <- function(od_filtrada) {
  q <- c(0.05, 0.25, 0.50, 0.75, 0.95)
  wq <- function(x, w, p) {
    o <- order(x); x <- x[o]; w <- w[o]
    cw <- cumsum(w) / sum(w)
    stats::approx(cw, x, xout = p, rule = 2)$y
  }
  data.frame(
    quantil  = q,
    dist_km  = wq(od_filtrada$dist_reta_km,      od_filtrada$viagens_dia, q),
    dur_min  = wq(od_filtrada$dur_terrestre_min, od_filtrada$viagens_dia, q)
  )
}
```

**O que procurar:** se a mediana da distância estiver colada nos 15 km, o filtro está sendo
decidido inteiramente pela camada 1, e as outras três estão decorativas. Se a distribuição de
duração for quase toda acima de 90 min, o limiar de 45 min está frouxo e a camada real é outra.

Este check diz **qual camada está efetivamente amarrando** — e essa informação vale mais que os
quatro limiares juntos, porque diz onde a sensibilidade precisa ser fina.

### 5.7 O diário de calibração

Uma tabela com uma linha por combinação de limiares testada. Ela vira, sem retrabalho, o
material da análise de sensibilidade da S3.

```r
# app/R/diario_calibracao.R
# @produz    outputs/diario_calibracao.csv
# @consome   data/interim/od_atributos.rds
# @decisao   decisao:D03
# @tarefa    tarefa:T12

#' Varre a grade de limiares e registra o efeito de cada combinação sobre a instância.
#'
#' Existe para que a análise de sensibilidade da S3 seja leitura de uma tabela já
#' produzida, e não uma reconstrução de memória na véspera da entrega. Cada linha é uma
#' hipótese testada; o conjunto é a demonstração de que os limiares da decisao:D03 foram
#' escolhidos, e não adotados por inércia.
#'
#' @param od data frame por par, com os atributos do filtro
#' @param grade data frame com uma linha por combinação: dist_min_km, dur_min_min,
#'   rotulo_motivos, rotulo_renda
#' @param motivos_por_rotulo lista nomeada de vetores de motivo
#' @param renda_por_rotulo lista nomeada de vetores de faixa de renda
#' @return grade acrescida de pares, viagens, fração de viagens e concentração top-5
diario_calibracao <- function(od, grade, motivos_por_rotulo, renda_por_rotulo) {
  stopifnot(is.data.frame(od), is.data.frame(grade),
            all(c("dist_min_km", "dur_min_min",
                  "rotulo_motivos", "rotulo_renda") %in% names(grade)))

  total_viagens <- sum(od$viagens_dia)

  resultados <- lapply(seq_len(nrow(grade)), function(i) {
    g <- grade[i, ]
    f <- filtrar_captura(
      od,
      dist_min_km  = g$dist_min_km,
      dur_min_min  = g$dur_min_min,
      motivos      = motivos_por_rotulo[[g$rotulo_motivos]],
      faixas_renda = renda_por_rotulo[[g$rotulo_renda]]
    )
    top5 <- if (nrow(f) == 0) NA_real_ else {
      atr <- tapply(f$viagens_dia, f$macro_d, sum)
      sum(sort(atr, decreasing = TRUE)[1:min(5, length(atr))]) / sum(atr)
    }
    data.frame(
      pares        = nrow(f),
      viagens_dia  = sum(f$viagens_dia),
      frac_viagens = sum(f$viagens_dia) / total_viagens,
      conc_top5    = top5
    )
  })

  cbind(grade, do.call(rbind, resultados))
}

#' Grade padrão de limiares a varrer. Os valores centrais são os da decisao:D03.
grade_limiares <- function() {
  expand.grid(
    dist_min_km    = c(10, 12, 15, 20, 25),
    dur_min_min    = c(30, 40, 45, 60, 75),
    rotulo_motivos = c("negocios", "trabalho_negocios", "com_estudo", "todos"),
    rotulo_renda   = c("faixa5", "faixas45", "faixas345", "sem_filtro"),
    stringsAsFactors = FALSE
  )
}
```

O formato de saída, que é o que vai para o relatório:

| dist_min_km | dur_min_min | motivos | renda | pares | viagens/dia | % do total | conc. top-5 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 10 | 30 | todos | sem filtro | … | … | … | … |
| 15 | 45 | trabalho+negócios | faixas 4–5 | … | … | … | … |
| 20 | 60 | negócios | faixa 5 | … | … | … | … |

**Duas regras para o diário:**

1. **Registre também as combinações que você descartou rapidamente.** A linha que mostra 12% das
   viagens sobrando com o filtro frouxo é a evidência de que o filtro escolhido não foi
   arbitrário. Sem ela, "escolhemos 15 km" é afirmação; com ela, é conclusão.
2. **Ele é append-only, em espírito.** A grade completa se roda de uma vez, mas se em 10/09
   alguém testar uma combinação nova, ela se acrescenta — não se regenera o arquivo apagando o
   histórico.

**Cada linha do diário que virar rodada do modelo vira também um nó `experimento`** no grafo,
com hipótese, parâmetros, commit, FO, gap, tempo e conclusão. O diário é o mapa de quais valem a
pena rodar.

---

## 6. Critério de pronto

- [ ] `filtrar_captura()` implementada com os **quatro limiares como parâmetros**, com
      `stopifnot()` no topo e roxygen que diz **por que** a função existe e a qual decisão
      responde
- [ ] Os quatro valores efetivos aparecem **explicitamente no `_targets.R`**
- [ ] A codificação real das variáveis de **motivo** e de **faixa de renda** confirmada contra o
      layout do ZIP — nenhum `[PREENCHER]`, nenhum chute
- [ ] Decisão sobre **motivo na origem, no destino ou em qualquer ponta** tomada e registrada
- [ ] Distância calculada em **CRS métrico**, com o `stopifnot` de `st_is_longlat` ativo
- [ ] Duração por par calculada como **média ponderada por `FE_via`**
- [ ] Renda tratada no **nível pessoa/domicílio**, não no nível viagem
- [ ] **Check 1** rodado: fração de pares e de viagens que sobra, comparada com a heurística de
      1–2% e com as 6.124 solicitações/dia de Chicago
- [ ] **Check 2** rodado: mapa de geradas e atraídas + concentração top-5 e top-10, com a
      interpretação escrita — inclusive se ela for desconfortável
- [ ] **Check 3** rodado: quantis ponderados de distância e duração, com a identificação de qual
      camada está amarrando
- [ ] **Diário de calibração** gerado, com no mínimo as 5 × 5 combinações de distância e duração
      no cenário central de motivo e renda
- [ ] Cenário **sem filtro de renda** rodado e registrado — é a base do parágrafo de equidade
- [ ] `decisao:D03` registrada no grafo com **as três alternativas descartadas** e o motivo
      específico de cada uma
- [ ] A frase "**limite superior da demanda, não previsão de adoção**" escrita no roxygen da
      função e no rascunho do relatório
- [ ] `tar_make()` completo, `tar_outdated()` vazio, validador do grafo passando

---

## 7. Armadilhas conhecidas

**Chamar o resultado de "demanda UAM".** É demanda **potencial**, limite superior, sem estágio
de escolha modal. Wu & Zhang mostram que o segundo estágio corta duas ordens de grandeza. O
nome do objeto é `od_capturavel`, e a distinção precisa sobreviver até o relatório.

**Filtro frouxo por medo de instância pequena.** A tentação aparece quando `frac_viagens` dá
0,3% e a instância fica com poucos pares. Afrouxar o filtro para ter um problema mais
interessante é fabricar demanda — e o enunciado tem nome para isso. Se a instância ficar pequena
demais, a resposta é a agregação (G02, `n_alvo`) ou o número de candidatos (G04), nunca o
filtro.

**Unidade da distância.** `sf::st_distance()` devolve objeto com unidade. Um `as.numeric()`
direto entrega **metros**, e comparar metros com `dist_min_km = 15` faz passar essencialmente
tudo. Use `units::set_units()` antes de converter, como no código, e confira a mediana: uma
mediana de distância de 12.000 é metros disfarçados.

**Distância em graus.** Se as macrozonas vierem em EPSG:4326, a distância sai em graus e nenhum
par passa dos 15. O `stopifnot` de `st_is_longlat` está lá para isso.

**Filtrar só por motivo de destino.** Descarta metade do fluxo pendular. Como o modelo é
bilateral, isso não reduz só o volume — distorce a estrutura da matriz, porque a viagem de volta
some enquanto a de ida fica.

**Ponderação com o fator errado na renda.** Renda é atributo de domicílio. Usar `FE_via`
sobrepesa quem viaja mais e infla a renda média das zonas de alta mobilidade — que são
exatamente as que o filtro vai selecionar. O viés se auto-reforça e o resultado sai coerente.

**Média não ponderada da duração.** `mean(duracao)` numa amostra estratificada por renda enviesa
a duração exatamente ao longo da dimensão da camada 4.

**Codificação de faixa de renda invertida.** Se 1 for a faixa mais alta e não a mais baixa, o
filtro seleciona o público oposto ao pretendido e devolve um resultado inteiramente plausível.
Confirme no layout, e confirme de novo olhando a renda média das faixas selecionadas.

**Rodar a grade inteira sem pensar.** `grade_limiares()` tem 5 × 5 × 4 × 4 = 400 combinações. É
barato de rodar e caro de ler. Rode tudo, mas leve ao relatório o corte que responde a uma
pergunta: distância × duração no cenário central, e depois os cenários de motivo e renda
separados.

**Esconder o achado espacial.** Se os pares se concentrarem no eixo Faria Lima–Berrini–Itaim, é
resultado. Escondê-lo é pior que reportá-lo, e é detectável — a concentração top-5 está no
diário.

**Tratar `pendencia:P01` como formalidade.** Ela bloqueia esta tarefa por um motivo real: se os
microdados de 2023 aparecerem, todo este pacote se reexecuta sobre outro dado, e as conclusões
de nível mudam.

**Deixar o diário para depois.** Reconstruir na véspera as combinações testadas duas semanas
antes é exatamente o "banco preenchido em bloco na semana da entrega" que o enunciado lista como
comprometedor da nota. O diário é subproduto do trabalho, não tarefa extra — desde que se
escreva enquanto se testa.

---

## 8. O que registrar

### `decisao:D03` — a decisão central deste pacote

Precisa conter as quatro camadas com **justificativa, parâmetro, sustentação e faixa de
sensibilidade** de cada uma, e as três alternativas descartadas com o motivo **específico**:

| Alternativa descartada | Motivo específico da rejeição |
| --- | --- |
| Usar **toda a matriz OD** | "Um modelo de localização construído sobre demanda inventada é um exercício de aritmética" (§3.1 do enunciado). A literatura converge para uma fatia pequena: Wu & Zhang chegam a 0,20% de adoção |
| **Só filtro de distância** | Captura viagens periféricas longas de baixa renda, que não são o mercado real da UAM, e infla o resultado |
| **Logit calibrado de escolha modal** | Correto em tese, mas **não existe logit calibrado para UAM no Brasil**. Transplantar β's de Munique ou da Califórnia introduziria parâmetro sem procedência brasileira. Fica como extensão da S4 e como cenário de sensibilidade |

Sub-decisões que também precisam de registro, ainda que como notas na D03: **motivo em qualquer
ponta vs. só destino**; **renda da OD vs. Censo**, com as duas alternativas da tabela de §5.4.

### Referências

Registrar como nós `referencia`, cada uma com autor, ano, periódico e DOI **e com o estado de
leitura**:

| Id sugerido | Referência | Estado |
| --- | --- | --- |
| `referencia:wu2021` | Wu & Zhang (2021), *Engineering* 7(4), 473–487, DOI 10.1016/j.eng.2020.11.007 | Ficha detalhada em `01-revisao-literatura.md` |
| `referencia:rimjha2021a` | Rimjha, Hotle, Trani & Hinze (2021), *TRA* 148, 506–524, DOI 10.1016/j.tra.2021.03.020 | idem |
| `referencia:rimjha2021b` | Rimjha et al. (2021), *AIAA Aviation 2021 Forum*, DOI 10.2514/6.2021-3209 | Parâmetros operacionais confirmados |
| `referencia:volakakis2025` | Volakakis & Mahmassani (2025), *Infrastructures* 10(9), 242, DOI 10.3390/infrastructures10090242 | idem |
| `referencia:volakakis2024` | Volakakis & Mahmassani (2024), *Infrastructures* 9(12), 239, DOI 10.3390/infrastructures9120239 | Base do argumento de equidade |

⚠️ **Regra 4 do `CLAUDE.md`:** não se cita a formulação matemática de um artigo que ninguém
abriu. Onde só o metadado foi confirmado, o registro precisa dizer isso — e
`pendencia:P02` já rastreia as quatro referências centrais que estão em paywall.

### Fontes

Se a renda vier da OD, ela já está coberta por `fonte:od2017` do G02. Se algo do Censo entrar,
mesmo como camada de apoio, vira nó `fonte` próprio com a limitação de defasagem escrita.

### Notas na `tarefa:T12`

No mínimo três, datadas e assinadas por `pedro`:

1. Os valores efetivos dos quatro limiares e o resultado do **Check 1**.
2. O achado espacial do **Check 2**, escrito como achado — com a concentração top-5 numérica.
3. Qual camada está efetivamente amarrando, conforme o **Check 3**. Essa é a informação que
   orienta a sensibilidade da S3 e a que mais economiza tempo depois.

### `pendencia:P01`

Atualizar com o que a T10.2 descobriu, e fechar se houver decisão definitiva. Enquanto aberta,
a T12 está formalmente bloqueada, e o kanban precisa refletir isso — lembrando que `bloqueada`
não é estado armazenado, e sim derivado da pendência (regra 6 do `CLAUDE.md`).

### Registro de IA

`ia:<data>-<slug>` com `critica_humana` não vazia. Neste pacote, os alvos naturais de crítica:

- O corte de **1–2%** é heurística construída por analogia com Wu & Zhang, **não** número
  publicado. Se uma resposta de IA o apresentar como referência da literatura, isso é
  exatamente a "estimativa apresentada como medição" que o `G00` §4.4 manda procurar.
- A escolha de **15 km** é mais permissiva que as 10 milhas (≈16,1 km) das duas fontes que a
  sustentam. É defensável, mas é uma escolha do grupo contra a literatura, e precisa estar dita
  como tal.
- O **motivo em qualquer ponta** e o **motivo só no destino** são ambos defensáveis. Qualquer
  recomendação de IA aqui é preferência, não conclusão.
- A camada de **renda** embute um juízo normativo sobre quem a política deve servir. Nenhuma
  IA pode assinar esse juízo pelo grupo.

E lembre da pergunta garantida na arguição — *"mostrem a decisão em que vocês discordaram da
IA"*. Este pacote é o candidato mais forte do projeto inteiro a fornecer essa resposta, porque é
onde as escolhas são mais discutíveis. Se a discordância acontecer, marque a nota com
`#discordancia`.

---

## 9. Como isso vira relatório

| Seção do relatório | O que este pacote entrega |
| --- | --- |
| **Formulação do problema — demanda** | A resposta literal à pergunta do enunciado: que parcela da mobilidade paulistana faria sentido migrar para o ar, sob que condições, e por quê |
| **Método — hipóteses de captura** | As quatro camadas, cada uma com justificativa, parâmetro e sustentação. A tabela de §4.2 é praticamente a tabela do relatório |
| **Método — sustentação na literatura** | Wu & Zhang, Rimjha et al. e Volakakis & Mahmassani, com a convergência dos três explicitada: a fatia é pequena e sensível à tarifa |
| **Resultados — caracterização da demanda** | Fração capturável, distribuição de distância e duração, e o mapa de concentração espacial |
| **Análise de sensibilidade (S3)** | O diário de calibração inteiro. É a seção que já está escrita quando chegar a hora de escrevê-la |
| **Equidade** | O cenário sem filtro de renda, contra o cenário central. Diálogo direto com Volakakis & Mahmassani (2024) |
| **Limitações** | Quatro itens: limite superior sem estágio de escolha modal; distância centroide a centroide após agregação; renda na resolução da zona OD; e a camada 3 discutível, com a própria recomendação de Rimjha et al. de incluir propósitos além de commuting |
| **Discussão** | Se a concentração no eixo Faria Lima–Berrini–Itaim se confirmar, é aqui que ela vira argumento: evidência empírica paulistana de que a UAM se comporta como infraestrutura de elite, obtida sem que o recorte a tenha induzido |

E a ponte para o próximo pacote: a matriz `od_capturavel` é a **demanda `w_ij` da formulação
bilateral do G06**. Cada par que sobra aqui vira uma variável de cobertura no MILP. Isso liga o
tamanho da instância diretamente aos quatro limiares desta página — e é a razão pela qual o
diário de calibração serve tanto à análise de sensibilidade quanto ao desempenho computacional
que o enunciado exige reportar.
