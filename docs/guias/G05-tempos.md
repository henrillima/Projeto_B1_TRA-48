# G05 — Matriz de tempos terrestres e de voo

> Pacote de trabalho de **Antônio Garcia**. Prazo do pacote: **02/09/2026**.
> Leia `docs/guias/G00-como-trabalhar.md` e `CLAUDE.md` antes deste.

---

## Objetivo

Ao fim deste pacote existem quatro matrizes de tempo em disco, cacheadas pelo `targets` e
reproduzíveis do zero: acesso zona→candidato, egresso candidato→zona, voo candidato→candidato e
o tempo terrestre porta-a-porta zona→zona do **modo concorrente** — mais um fator de
congestionamento calibrado, com a discrepância entre as três fontes de tempo registrada em vez
de escondida.

---

## Tarefas no grafo

| Id | Título | Prazo | Est. |
| --- | --- | --- | --- |
| `tarefa:T13` | Construir a matriz de tempos terrestres entre macrozonas | 02/09 | — |
| `tarefa:T13.1` | Subir OSRM local sobre o extrato Geofabrik do Sudeste | 30/08 | 5 h |
| `tarefa:T13.2` | Calibrar o fator de congestionamento por amostra de pico | 02/09 | 4 h |

`T13 REALIZA meta:M1` e `DEPENDE_DE tarefa:T11`. `T13.2 DEPENDE_DE tarefa:T13.1`. Todas
`ATRIBUIDA_A pessoa:antonio`.

Note a assimetria de dependências: **T13.1 não depende de nada** — subir o OSRM é infraestrutura
e pode ser feito hoje, antes de a OD estar agregada. **T13, sim, depende de T11**, porque a
matriz precisa dos centroides das macrozonas. Faça T13.1 enquanto Pedro trabalha em T11; não há
motivo para os dois esperarem.

---

## Pré-requisitos

- [ ] **`tarefa:T11` entregue** — as ~120 macrozonas com geometria, em EPSG:31983, e o centroide
      (ou o ponto representativo) de cada uma. Sem isso não há de onde nem para onde rotear.
- [ ] **`tarefa:T20` entregue ou em rascunho** — os candidatos de G04. As matrizes de acesso,
      egresso e voo têm `|J|` como dimensão. Um `J` provisório serve para desenvolver o código;
      a matriz final espera o `J` final.
- [ ] **Docker funcionando** na máquina, com espaço em disco e RAM suficientes para processar o
      extrato do Sudeste. O `osrm-extract` é o passo mais pesado; se a máquina engasgar, o
      caminho é recortar o `.pbf` para a RMSP antes (ver §1.2).
- [ ] `renv` com `httr2`, `jsonlite`, `dplyr`, `sf`, `targets` no lock.
- [ ] Para T13.2: a duração declarada de viagem já legível na OD (saída de G02).

---

## Insumos

| Insumo | Onde | Formato |
| --- | --- | --- |
| Extrato OSM do Sudeste | `https://download.geofabrik.de/south-america/brazil/sudeste.html` | `.osm.pbf` |
| OSRM | `https://project-osrm.org` | binários via imagem Docker |
| Macrozonas + centroides (T11) | `outputs/macrozonas.rds` | `sf` |
| Candidatos (T20) | `outputs/candidatos.rds` | `sf` |
| Duração declarada da OD | saída de G02 | data frame no nível viagem |
| Google Routes API — validação | `https://developers.google.com/maps/documentation/routes/usage-and-billing` | REST/JSON, **pago por elemento** |
| HERE Matrix Routing — validação | `https://developer.here.com/documentation/matrix-routing-api/dev_guide/index.html` | REST/JSON, freemium |

**Licença do OSM: ODbL.** Exige atribuição e é *share-alike*. Consequência prática que precisa
estar no relatório e no repositório: a matriz de tempos é **obra derivada**. A atribuição
("© OpenStreetMap contributors") entra em toda figura que use a rede e na seção de dados.

### Parâmetros do eVTOL

Todos de **Rimjha, Hotle, Trani & Hinze (2021)**, *Transportation Research Part A* 148, 506–524,
DOI `10.1016/j.tra.2021.03.020`, e de **Rimjha et al. (2021)**, *AIAA Aviation 2021 Forum*, DOI
`10.2514/6.2021-3209`:

| Parâmetro | Valor | Nome no código |
| --- | --- | --- |
| Velocidade média de cruzeiro | 120 mph ≈ **193 km/h** | `v_cruzeiro_kmh` |
| Tempo de ingresso (processamento no vertiporto de origem) | **5 min** | `tau_emb_min` |
| Tempo de egresso (processamento no vertiporto de destino) | **5 min** | `tau_des_min` |
| Caminhada máxima até o vertiporto | **0,1 milha** ≈ 161 m | `caminhada_max_m` |
| Load factor | **60%** (2,4 pax/veículo) | `load_factor` |
| Distância mínima de voo | **10 milhas** ≈ 16,1 km | `dist_min_voo_km` |

**Todos entram como parâmetros com valor-padrão, nunca como literais no meio do código**
(regra 8 do `CLAUDE.md`). São parâmetros de contexto norte-americano aplicados a São Paulo:
isso é uma limitação declarada, não uma medição brasileira. `caminhada_max_m` e `load_factor`
não entram na matriz de tempos — ficam registrados aqui porque pertencem ao mesmo conjunto de
parâmetros operacionais e serão necessários em G07/G08.

---

## Passo a passo

### 0. O que precisa ser calculado, e por quê são quatro coisas

A formulação P1 mede a economia de tempo porta-a-porta de um par OD `q = (o,d)` roteado por um
par de vertiportos `(j,k)`:

```
T_uam(q,j,k) = t_acesso(o,j) + tau_emb + t_voo(j,k) + tau_des + t_egresso(k,d)
Δ(q,j,k)     = T_terrestre(q) − T_uam(q,j,k)
```

Daí as quatro matrizes:

| Matriz | Dimensão | O que é |
| --- | --- | --- |
| `t_acesso` | zonas × candidatos | tempo terrestre do centroide da zona de origem até o vertiporto `j` |
| `t_egresso` | candidatos × zonas | tempo terrestre do vertiporto `k` até o centroide da zona de destino |
| `t_voo` | candidatos × candidatos | tempo de voo eVTOL entre vertiportos |
| `T_terrestre` | zonas × zonas | **o modo concorrente** — fazer a viagem inteira de carro |

A quarta é a que se esquece, e é a mais importante. **Sem `T_terrestre` não existe `Δ`, e sem
`Δ` a função objetivo não existe** — a FO de P1 é `Σ f_q · Δ_qjk · w_qjk`. Um modelo sem o modo
concorrente estaria maximizando "tempo de viagem por eVTOL", que é uma quantidade sem sentido:
a alternativa "não fazer nada" precisa estar no modelo, e ela é o carro.

`t_acesso` e `t_egresso` são calculadas separadamente e **não são transpostas uma da outra**.
Duas razões: a rede viária tem sentido único, então ir de A a B não custa o mesmo que voltar; e
Volakakis & Mahmassani (2025) constatam que a sensibilidade ao tempo difere entre acesso e
egresso (ver `01-revisao-literatura.md`). Calcular uma e transpor economizaria metade do tempo de
cômputo e introduziria um erro que ninguém detectaria depois.

### 1. T13.1 — OSRM self-hosted

#### 1.1 Por que self-host

O servidor de demonstração do projeto OSRM tem *rate limit* severo e é explicitamente destinado a
testes. Nossa demanda é de dezenas de milhares de pares (§4), em várias rodadas, com recálculo
sempre que `J` ou as macrozonas mudarem. Um serviço com limite de taxa transforma isso em horas
de espera e em falha intermitente no meio do pipeline — o pior modo de falha possível, porque
produz matriz parcialmente preenchida.

Self-host também torna o resultado **reprodutível**: a matriz depende de uma versão datada do
extrato Geofabrik, que fica registrada. Um serviço remoto muda por baixo sem aviso, e "qualquer
pessoa deve conseguir rodar o projeto do zero" — exigência textual do enunciado — deixaria de ser
verdade.

#### 1.2 O passo a passo com Docker

```bash
# 1. baixar o extrato do Sudeste (Geofabrik) para app/data/raw/osm/
#    registrar a DATA do arquivo: o extrato muda diariamente
cd app/data/raw/osm
curl -O https://download.geofabrik.de/south-america/brazil/sudeste-latest.osm.pbf

# 2. pre-processar. O perfil `car.lua` e o modo de deslocamento terrestre concorrente.
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-extract -p /opt/car.lua /data/sudeste-latest.osm.pbf

# 3. particionar e customizar (algoritmo MLD - multi-level Dijkstra)
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-partition /data/sudeste-latest.osrm
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-customize /data/sudeste-latest.osrm

# 4. subir o serviço
docker run -t -i -p 5000:5000 -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-routed --algorithm mld --max-table-size 1000 /data/sudeste-latest.osrm
```

Quatro observações que economizam uma tarde:

**`--max-table-size`.** O padrão do OSRM limita o número de coordenadas por requisição `/table`,
e requisições maiores voltam com erro `TooBig`. Suba o limite **e** faça a consulta em blocos
(§1.4) — as duas coisas, porque um limite alto não evita que a resposta JSON fique grande demais
para ser confortável.

**O `osrm-extract` é o gargalo.** Ele consome bastante RAM e disco para o Sudeste inteiro. Se a
máquina não aguentar, recorte o `.pbf` para a RMSP antes com `osmium extract` e uma caixa
envolvente derivada do contorno metropolitano — **não digite a caixa de memória**, derive-a do
shapefile de municípios que já está no `OD-2017.zip`. Registre o recorte como decisão: ele muda o
que a rede conhece, e rotas que saem e voltam pela borda deixam de existir.

**O perfil importa.** `car.lua` rotea automóvel. É o certo para o modo concorrente
(`T_terrestre`) e defensável para acesso/egresso, dado que o segmento de mercado de D3 é
trabalho/negócios em faixas de renda superiores. Mas é uma escolha: acesso a pé ou por transporte
público daria outra matriz. Registre a escolha com a alternativa descartada.

**Nada disso entra no git.** O `.pbf` e os `.osrm*` derivados são grandes; `app/data/raw/*` já
está no `.gitignore` (§6.3 das convenções). O que entra é o **script que os reproduz** e a data
do extrato.

#### 1.3 O endpoint `/table`

`/table` devolve a matriz de durações entre coordenadas em uma requisição, sem calcular a
geometria de cada rota — que é exatamente o que precisamos e é ordens de magnitude mais rápido
que chamar `/route` par a par.

```
GET http://localhost:5000/table/v1/driving/{lon1,lat1;lon2,lat2;...}
      ?sources=0;1;2&destinations=3;4&annotations=duration
```

Três detalhes que quebram na primeira tentativa:

- **A ordem é `lon,lat`**, não `lat,lon`. Trocar produz uma matriz inteira de `null` (nenhum
  ponto encontra rede) ou, pior, uma matriz plausível e completamente errada.
- **As coordenadas vão em WGS 84 (EPSG:4326)**, então é preciso reprojetar a partir de 31983
  antes da chamada — e voltar a trabalhar em 31983 depois.
- **`durations` sai em segundos**, e o modelo trabalha em minutos. Converta em um único lugar.

#### 1.4 O cliente em R

```r
# app/R/consultar_osrm.R
# @produz    data/interim/tempos_osrm.rds
# @consome   outputs/macrozonas.rds
# @consome   outputs/candidatos.rds
# @decisao   decisao:[a registrar - perfil car.lua]
# @tarefa    tarefa:T13.1

#' Consulta a matriz de duracoes do OSRM local entre dois conjuntos de pontos.
#'
#' Existe como funcao pura e em blocos porque a alternativa - uma requisicao
#' unica com todos os pontos - falha com `TooBig` justamente na matriz grande,
#' isto e, na unica que interessa. O bloqueio tambem torna a falha parcial
#' diagnosticavel: sabe-se qual bloco quebrou.
#'
#' @param origens sf de pontos (qualquer CRS projetado ou geografico)
#' @param destinos sf de pontos
#' @param url_base endereco do OSRM local
#' @param perfil perfil de roteamento do OSRM
#' @param bloco numero maximo de pontos por lado em cada requisicao
#' @return matriz numerica de duracoes em MINUTOS, origens nas linhas
consultar_osrm <- function(origens,
                           destinos,
                           url_base = "http://localhost:5000",
                           perfil   = "driving",
                           bloco    = 100L) {
  stopifnot(inherits(origens, "sf"), inherits(destinos, "sf"), bloco >= 1L)

  coord <- function(x) sf::st_coordinates(sf::st_transform(sf::st_geometry(x), 4326))
  co <- coord(origens)
  cd <- coord(destinos)

  no <- nrow(co); nd <- nrow(cd)
  out <- matrix(NA_real_, nrow = no, ncol = nd)

  bo <- split(seq_len(no), ceiling(seq_len(no) / bloco))
  bd <- split(seq_len(nd), ceiling(seq_len(nd) / bloco))

  for (io in bo) {
    for (id in bd) {
      pontos <- rbind(co[io, , drop = FALSE], cd[id, , drop = FALSE])
      cs <- paste(sprintf("%.6f,%.6f", pontos[, 1], pontos[, 2]), collapse = ";")

      idx_o <- paste(seq_along(io) - 1L, collapse = ";")
      idx_d <- paste(length(io) + seq_along(id) - 1L, collapse = ";")

      resp <- httr2::request(url_base) |>
        httr2::req_url_path_append("table", "v1", perfil, cs) |>
        httr2::req_url_query(sources      = idx_o,
                             destinations = idx_d,
                             annotations  = "duration") |>
        httr2::req_retry(max_tries = 3) |>
        httr2::req_perform()

      js <- httr2::resp_body_json(resp, simplifyVector = TRUE)
      if (!identical(js$code, "Ok")) {
        stop("OSRM devolveu code=", js$code, " no bloco (", min(io), ",", min(id), ")")
      }

      out[io, id] <- js$durations / 60
    }
  }
  out
}
```

`req_retry()` cobre a falha transitória de um contêiner que ainda está subindo. O `stop()` no
`code != "Ok"` é o que impede uma matriz meio preenchida de seguir adiante disfarçada de
resultado.

#### 1.5 Montar as quatro matrizes

```r
# app/R/matriz_tempos.R
# @produz    outputs/matrizes_tempo.rds
# @consome   data/interim/tempos_osrm.rds
# @decisao   decisao:[a registrar - fator de congestionamento]
# @tarefa    tarefa:T13

#' Monta as quatro matrizes de tempo do modelo a partir do OSRM e do voo.
#'
#' Reune num unico objeto o que a formulacao P1 consome, com dimnames pelos ids
#' de zona e de candidato - e nao por posicao. Indexar matriz por posicao e o
#' erro que sobrevive a todo teste ate a hora em que a ordem de `J` muda por um
#' filtro novo, e ai a solucao continua otima para a instancia errada.
#'
#' @param zonas sf de centroides das macrozonas, com coluna id_zona
#' @param candidatos sf de candidatos, com coluna id
#' @param fator_congestionamento multiplicador sobre o tempo free-flow do OSRM
#' @param v_cruzeiro_kmh velocidade media de cruzeiro do eVTOL
#' @param usar_geodesica TRUE para grande circulo, FALSE para euclidiana em UTM
#' @return lista com t_acesso, t_egresso, t_voo e T_terrestre, em minutos
matriz_tempos <- function(zonas,
                          candidatos,
                          fator_congestionamento = 1,
                          v_cruzeiro_kmh         = 193,
                          usar_geodesica         = FALSE) {
  stopifnot(inherits(zonas, "sf"), inherits(candidatos, "sf"),
            fator_congestionamento >= 1, v_cruzeiro_kmh > 0)

  f <- fator_congestionamento

  t_acesso    <- consultar_osrm(zonas, candidatos) * f
  t_egresso   <- consultar_osrm(candidatos, zonas) * f
  T_terrestre <- consultar_osrm(zonas, zonas)      * f

  geom_c <- if (usar_geodesica) sf::st_transform(sf::st_geometry(candidatos), 4326)
            else                sf::st_geometry(candidatos)
  d_m   <- as.matrix(sf::st_distance(geom_c, geom_c))
  t_voo <- (as.numeric(d_m) / 1000) / v_cruzeiro_kmh * 60
  t_voo <- matrix(t_voo, nrow = nrow(d_m))
  diag(t_voo) <- 0

  dimnames(t_acesso)    <- list(zonas$id_zona, candidatos$id)
  dimnames(t_egresso)   <- list(candidatos$id, zonas$id_zona)
  dimnames(t_voo)       <- list(candidatos$id, candidatos$id)
  dimnames(T_terrestre) <- list(zonas$id_zona, zonas$id_zona)

  list(t_acesso = t_acesso, t_egresso = t_egresso,
       t_voo = t_voo, T_terrestre = T_terrestre)
}
```

O `fator_congestionamento` aparece como argumento com padrão `1` — rodar com `1` dá a matriz
free-flow crua, que é o cenário de sensibilidade "pico ignorado". É assim que a limitação vira
experimento em vez de nota de rodapé.

### 2. A limitação decisiva: o OSRM roteia em free-flow

Este é o parágrafo mais importante do guia.

**O OSRM calcula tempo de percurso a partir da velocidade nominal da via, sem dados de tráfego.**
Em São Paulo, isso significa que `T_terrestre` sai sistematicamente **subestimado** — e não de
forma uniforme: subestima mais justamente nos corredores e horários congestionados.

O efeito sobre o modelo é direto e conservador na direção errada. `Δ = T_terrestre − T_uam`. Se
`T_terrestre` está baixo demais, `Δ` está baixo demais, e a economia de tempo atribuída ao eVTOL
está subestimada. Pior: o filtro `Δ ≥ θ` do conjunto `P_q` **elimina pares** que na realidade de
pico seriam viáveis. A instância encolhe, a cobertura ótima cai, e a conclusão do trabalho fica
enviesada contra a UAM por um artefato da fonte de dados.

E o pico é exatamente o momento em que o eVTOL ganha. Rodar o modelo só com free-flow é medir a
tecnologia na condição em que ela é menos competitiva, sem dizer que foi isso que se fez.

Isso não é um detalhe de implementação. **É o parâmetro que mais afeta o resultado do trabalho**,
e ele precisa aparecer no relatório como escolha explícita, com o `fator_congestionamento` na
análise de sensibilidade da S3. Ver `pendencia:` a abrir em §"O que registrar".

### 3. T13.2 — calibrar o fator de congestionamento

#### 3.1 As três âncoras

| Âncora | O que é | Vantagem | Defeito |
| --- | --- | --- | --- |
| **(a) OSRM free-flow** | rede OSM, velocidade nominal | cobre a matriz inteira, gratuito, reprodutível | ignora tráfego |
| **(b) Google Routes API ou HERE Matrix Routing** | tempo com tráfego, em horário de pico | mede a condição real de hoje | **pago por elemento** (Google); só amostra |
| **(c) duração declarada na própria OD** | o que o entrevistado disse que a viagem durou | **já embute o congestionamento real de SP**, e é a mesma base da demanda | declarada, não medida; é de 2017 |

A âncora (b) é **amostra de validação, não fonte da matriz**. O motivo é aritmético: Google cobra
por elemento, e uma matriz 500×500 são **250 mil elementos**. Mesmo a nossa matriz reduzida
(§4) é grande demais para orçamento acadêmico. Algumas **dezenas de pares** em horário de pico
bastam para validar — e algumas dezenas custam quase nada.

Há um segundo motivo para não usar Google como fonte: os termos restringem cache e reuso e
exigem exibição em mapa Google. Publicar uma matriz derivada em repositório aberto — que é o que
este projeto faz — é atrito garantido. HERE é freemium, otimizado para matrizes grandes e sem
esse atrito, mas com cobertura de tráfego menos densa no Brasil.

A âncora (c) é a mais barata e provavelmente a melhor, e vale dizer por quê: ela vem **da mesma
pesquisa que gera a demanda**. Se o filtro de captura de D3 usa "duração terrestre declarada
≥ 45–60 min" e a matriz do modelo usa outra escala de tempo, o modelo estará filtrando por uma
régua e otimizando por outra. Calibrar contra a OD é o que mantém as duas coerentes.

#### 3.2 O método

Regressão do **tempo declarado da OD** contra o **tempo free-flow do OSRM**, para os mesmos pares
de macrozonas, **por faixa horária**. O produto é um multiplicador `f` por faixa.

```r
# app/R/calibrar_congestionamento.R
# @produz    outputs/fator_congestionamento.rds
# @consome   outputs/matrizes_tempo.rds
# @consome   data/interim/od_macrozonas.rds
# @decisao   decisao:[a registrar - estimador do fator]
# @tarefa    tarefa:T13.2

#' Estima o multiplicador que converte tempo free-flow em tempo com congestionamento.
#'
#' Dois estimadores, de proposito. A regressao pela origem e o que se reporta;
#' a razao de somas e o que se confere. Quando os dois divergem muito, a causa
#' costuma ser um punhado de pares curtos com tempo declarado arredondado
#' ("uns 30 minutos"), que dominam a razao individual e nao a razao agregada -
#' e essa e uma informacao sobre o dado, nao um incomodo a suprimir.
#'
#' @param od data frame de viagens com zona_o, zona_d, duracao_min, fe_viagem, hora_saida
#' @param T_ff matriz de tempos free-flow do OSRM, em minutos, com dimnames de zona
#' @param faixas vetor de cortes de hora para as faixas horarias
#' @return data frame com faixa, n, fator_regressao, fator_razao e r2
calibrar_congestionamento <- function(od, T_ff,
                                      faixas = c(0, 6, 9, 16, 20, 24)) {
  stopifnot(is.data.frame(od), is.matrix(T_ff),
            all(c("zona_o", "zona_d", "duracao_min", "fe_viagem", "hora_saida") %in% names(od)))

  od <- od[od$zona_o %in% rownames(T_ff) & od$zona_d %in% colnames(T_ff), , drop = FALSE]
  od$t_ff <- T_ff[cbind(match(od$zona_o, rownames(T_ff)),
                        match(od$zona_d, colnames(T_ff)))]

  od <- od[is.finite(od$t_ff) & od$t_ff > 0 &
             is.finite(od$duracao_min) & od$duracao_min > 0, , drop = FALSE]
  od$faixa <- cut(od$hora_saida, breaks = faixas, right = FALSE, include.lowest = TRUE)

  res <- lapply(split(od, od$faixa), function(g) {
    if (nrow(g) < 30L) {
      return(data.frame(n = nrow(g), fator_regressao = NA_real_,
                        fator_razao = NA_real_, r2 = NA_real_))
    }
    m <- stats::lm(duracao_min ~ 0 + t_ff, data = g, weights = g$fe_viagem)
    data.frame(
      n               = nrow(g),
      fator_regressao = unname(stats::coef(m)[["t_ff"]]),
      fator_razao     = sum(g$duracao_min * g$fe_viagem) / sum(g$t_ff * g$fe_viagem),
      r2              = summary(m)$r.squared
    )
  })

  out <- do.call(rbind, res)
  out$faixa <- rownames(out)
  out[, c("faixa", "n", "fator_regressao", "fator_razao", "r2")]
}
```

Quatro escolhas embutidas, cada uma delas registrável como decisão:

**Regressão pela origem (`~ 0 + t_ff`).** Sem intercepto, o coeficiente *é* o multiplicador, que
é o que a matriz consome. Com intercepto, o modelo separa um tempo terminal fixo — estacionar,
caminhar até o carro — do fator proporcional, o que é mais realista mas produz dois parâmetros em
vez de um. **Rode as duas versões e reporte as duas.** Se o intercepto sair grande, isso é um
achado sobre a estrutura do tempo de viagem em SP, não ruído.

**Ponderação por `fe_viagem`.** A OD é amostra estratificada por renda; nada nela se soma sem
peso (§1.5 de `02-fontes-de-dados.md`). Uma regressão não ponderada estima o fator da amostra,
não o da cidade.

**As faixas horárias.** Os cortes acima são um ponto de partida plausível, não um padrão
canônico — **[A CONFIRMAR]** contra a definição de pico que a própria OD 2017 usa nos seus
tabulados. Se a OD tiver faixas próprias, use as dela: assim o resultado é comparável ao que o
Metrô publica.

**O mínimo de 30 observações por faixa.** Faixa com poucos casos devolve `NA` explícito em vez de
um fator estimado sobre nada. `NA` que aparece é melhor que número que não deveria existir.

#### 3.3 Cruzar as três, e publicar a discrepância

O produto de T13.2 não é o número `f`. É **uma tabela com as três estimativas lado a lado**, nos
mesmos pares:

| Par (amostra de pico) | (a) OSRM free-flow | (b) Google/HERE com tráfego | (c) OD declarada | b/a | c/a |
| --- | --- | --- | --- | --- | --- |
| ... | | | | | |

Se as três convergirem, o fator é robusto e isso se diz em uma linha. Se divergirem — e vão, ao
menos porque (c) é de 2017 e (b) é de 2026 — a divergência é o resultado. Duas leituras
possíveis, ambas interessantes: (b) > (c) sugere que o congestionamento piorou desde a OD; (c) >
(b) sugere que a duração declarada embute tempo de acesso e estacionamento que o roteador não
conta.

**Registrar a discrepância vale mais na avaliação que escondê-la** (§3.2 do enunciado). O erro é
escolher em silêncio o fator mais conveniente e apresentar uma matriz sem ressalva.

### 4. Tempo de voo, e a geometria

#### 4.1 Grande círculo ou euclidiana em UTM?

Na escala urbana, a diferença é desprezível — mas "desprezível" é uma afirmação que precisa ser
**medida**, não citada. O projeto trabalha em EPSG:31983 (SIRGAS 2000 / UTM 23S), e São Paulo
fica dentro da zona 23S, longe da borda onde a distorção de escala cresce.

Meça uma vez e registre o número:

```r
# comparacao empirica: euclidiana em UTM 23S vs. grande circulo
d_utm <- as.matrix(sf::st_distance(sf::st_geometry(candidatos),
                                   sf::st_geometry(candidatos)))
d_geo <- as.matrix(sf::st_distance(sf::st_transform(sf::st_geometry(candidatos), 4326),
                                   sf::st_transform(sf::st_geometry(candidatos), 4326)))

dif <- as.numeric(d_utm) - as.numeric(d_geo)
summary(abs(dif[is.finite(dif) & dif != 0]))          # em metros
summary(abs(dif / as.numeric(d_geo))[is.finite(dif)]) # relativo
```

**Declare a escolha:** euclidiana em UTM 23S, porque todo o resto do pipeline já está em 31983 e
misturar CRS por conveniência é como se introduz erro sem perceber. O `usar_geodesica = TRUE` de
`matriz_tempos()` existe para que a alternativa seja um argumento, e não um reescrever de código.

E há uma imprecisão maior que essa, que convém dizer antes que perguntem: **a distância em linha
reta não é a rota de voo**. Rotas de helicóptero em São Paulo seguem corredores definidos pelo
HELICONTROL, e a diferença entre linha reta e rota real é muito maior que a diferença entre
euclidiana e geodésica. Modelar a linha reta é uma simplificação declarada — e é o que Rimjha et
al. fazem também. A discussão sobre grande círculo é honesta, mas é a segunda casa decimal de uma
aproximação cuja primeira casa é outra.

#### 4.2 A conversão

```
t_voo(j,k) = distancia(j,k) / v_cruzeiro_kmh  ... em horas, × 60 para minutos
T_uam      = t_acesso + tau_emb + t_voo + tau_des + t_egresso
```

`v_cruzeiro_kmh = 193` é velocidade **média**, não velocidade de cruzeiro pura — em Rimjha et al.
ela já absorve subida e descida. Aplicá-la a distâncias curtas ainda superestima o desempenho,
porque o perfil de voo de um trecho de 15 km é quase todo subida e descida. É por isso que
`dist_min_voo_km = 16,1` (10 milhas) existe como parâmetro: abaixo dela, a hipótese de velocidade
média deixa de valer. O filtro de distância mínima de D3 (≥ 15 km em linha reta) já ataca isso
pelo lado da demanda; o `dist_min_voo_km` ataca pelo lado da oferta e serve como conferência
cruzada dos dois limiares.

`tau_emb` e `tau_des` de 5 minutos cada são o tempo de processamento no vertiporto. Somam
**10 minutos fixos** a toda viagem UAM, independentemente da distância. Esse é o termo que
inviabiliza a viagem curta e é o principal motivo de o conjunto `P_q` ser muito menor que
`|Q| × |J|²`.

### 5. Tamanho da matriz, e por que a agregação é pré-requisito

Com **~120 macrozonas** (saída de T11) e **40–60 candidatos** (saída de T20):

| Matriz | Dimensão | Células |
| --- | --- | --- |
| `t_acesso` | 120 × 60 | **7.200** |
| `t_egresso` | 60 × 120 | **7.200** |
| `t_voo` | 60 × 60 | **3.600** |
| `T_terrestre` | 120 × 120 | **14.400** |
| **Total** | | **~32.400** |

Trinta e dois mil valores em ponto flutuante são alguns megabytes em memória e alguns minutos de
OSRM local. Não é um problema de engenharia.

Agora o contrafactual. **Sem a agregação de T11**, com as 517 zonas OD originais:

| Matriz | Dimensão | Células |
| --- | --- | --- |
| `T_terrestre` | 517 × 517 | **267.289** |
| `t_acesso` + `t_egresso` | 2 × 517 × 60 | **62.040** |

E o efeito real não está no armazenamento — 267 mil doubles ainda cabem em memória. Está a
jusante: `|Q|` são os pares OD elegíveis, e ele cresce com o **quadrado** do número de zonas. O
número de colunas `w_qjk` do modelo é `|Q| × |P_q|`. Multiplicar `|Q|` por ~18 (de 120² para
517²) multiplica o modelo por ~18, e o alerta de `01-revisao-literatura.md` é que `ompr` fica
muito lento acima de ~10⁵ variáveis.

**É por isso que G02/T11 é pré-requisito de G05, e não uma etapa de arrumação.** A agregação
517→~120 é o que torna a instância resolvível como MILP exato — e resolver como MILP exato é o
que preserva relaxação linear, duais e sensibilidade, que são o vínculo obrigatório com o
bimestre de PL (§4.4).

### 6. Cache: a matriz não muda

A matriz de tempos depende do extrato OSM, das macrozonas e dos candidatos. Nenhum dos três muda
entre rodadas do modelo. Recalculá-la a cada `tar_make()` é desperdício puro — e, quando o
recálculo demora, é o tipo de desperdício que leva alguém a começar a rodar coisas à mão fora do
pipeline, que é o começo do fim da rastreabilidade.

```r
# fragmento de _targets.R
tar_target(centroides_zonas, sf::st_point_on_surface(macrozonas)),

tar_target(t_ff, matriz_tempos(centroides_zonas, candidatos,
                               fator_congestionamento = 1),
           format = "rds"),

tar_target(fator_cong, calibrar_congestionamento(od_macrozonas, t_ff$T_terrestre),
           format = "rds"),

tar_target(matrizes_tempo, matriz_tempos(centroides_zonas, candidatos,
                                         fator_congestionamento = fator_pico),
           format = "rds")
```

Duas notas sobre isso:

`format = "rds"` é o serializador padrão e preserva `dimnames`, que é o que garante que as
matrizes continuem indexadas por id e não por posição.

**`st_point_on_surface`, não `st_centroid`.** Zona de forma côncava — e as zonas OD da várzea e
das bordas da cidade são — pode ter centroide fora do próprio polígono, eventualmente dentro de
um rio ou de um parque. O roteador então engancha o ponto na via mais próxima, que pode ser do
outro lado do obstáculo. `st_point_on_surface` garante o ponto dentro da zona. É uma escolha
pequena, com efeito silencioso, e por isso vale uma nota registrada.

---

## Critério de pronto

- [ ] OSRM local responde: `curl "http://localhost:5000/table/v1/driving/-46.63,-23.55;-46.65,-23.56?annotations=duration"` devolve `"code":"Ok"`.
- [ ] O script que reproduz o OSRM do zero está versionado, com a **data do extrato Geofabrik**.
- [ ] `outputs/matrizes_tempo.rds` existe, com as quatro matrizes e `dimnames` por id.
- [ ] Dimensões conferem: `dim(t_acesso) == c(n_zonas, n_candidatos)` e assim por diante.
- [ ] Todos os tempos em **minutos** — não sobrou nenhum segundo do OSRM.
- [ ] `t_egresso` **não** é `t(t_acesso)`; a assimetria foi medida e reportada.
- [ ] Os cinco *sanity checks* de "Armadilhas" rodaram e estão registrados com os números.
- [ ] Zero `NA` nas matrizes, ou cada `NA` tem causa identificada e tratamento declarado.
- [ ] A tabela das três âncoras existe, com a discrepância calculada.
- [ ] `fator_congestionamento` é **parâmetro** do pipeline, com o valor `1` rodável como cenário.
- [ ] Os parâmetros de Rimjha et al. estão em um único lugar, nomeados, com a referência ao lado.
- [ ] A atribuição ODbL ("© OpenStreetMap contributors") está no relatório e no README.
- [ ] `targets::tar_outdated()` sai vazio; o validador do grafo passa.

---

## Armadilhas conhecidas

**`lat,lon` em vez de `lon,lat`.** O OSRM espera `lon,lat`. Invertido, ou tudo vira `null`, ou —
em coordenadas onde os dois valores são plausíveis como par — vem uma matriz completa e errada.
Teste com um par conhecido antes de rodar a matriz inteira.

**Segundos tratados como minutos.** O OSRM devolve segundos. Um `T_terrestre` 60 vezes maior faz
`Δ` gigante, todo par vira viável, e a cobertura ótima dá perto de 100% — um resultado
espetacular que é só um erro de unidade. Converta uma vez, na fronteira do cliente.

**`TooBig`.** Requisição `/table` acima do limite do servidor. Suba `--max-table-size` e mantenha
o bloqueio; as duas coisas.

**Centroide fora do polígono.** Ver §6. `st_point_on_surface`.

**Ponto que não engancha na rede.** Centroide no meio de um parque, de uma represa ou de área sem
via mapeada: o OSRM devolve `null` naquela linha ou coluna inteira. Sintoma: uma zona com `NA`
para todos os destinos. Tratamento, em ordem: (1) mover o ponto representativo para o vértice de
via mais próximo dentro da zona; (2) se persistir, marcar a zona e **declará-la excluída**, com o
volume de viagens que ela representa — excluir zona em silêncio é remover demanda do modelo sem
que ninguém saiba.

**Ilha da rede.** Recorte do `.pbf` cortando uma via de acesso pode isolar um pedaço da malha.
Sintoma diferente do anterior: um bloco de zonas que se alcançam entre si mas não alcançam o
resto. Detecta-se olhando o padrão dos `NA`, não a contagem. Se aparecer, o problema é o recorte
do extrato, não o dado.

**Assimetria interpretada como bug.** `t(t_acesso) != t_egresso` é **esperado**: sentido único,
conversões proibidas, viadutos. Meça a magnitude —
`summary(abs(t_acesso - t(t_egresso)))` — e reporte. Assimetria enorme e localizada, sim, é
suspeita: costuma indicar um ponto enganchado do lado errado de uma via expressa.

**Diagonal zero.** `T_terrestre[i,i] = 0` significa que toda viagem intrazonal é instantânea.
Não é. Com macrozonas de vários quilômetros, o tempo intrazonal é material e afeta o filtro de
captura. Duas saídas: (1) estimar `t_ii` a partir do raio do círculo de área equivalente à zona
dividido por uma velocidade média — a fração exata do raio é convenção, **registre-a como
decisão**; ou (2) excluir os pares intrazonais do conjunto `Q`, o que é coerente com o filtro de
distância mínima de D3 (uma viagem intrazonal dificilmente supera 15 km) e é a saída mais simples
de defender. **Registre qual foi.**

**Tempo absurdo.** Qualquer `T_terrestre` acima de ~4 h dentro do município é implausível e
denuncia um ponto enganchado longe, ou o roteador dando a volta por uma rodovia. Rode
`which(T_terrestre > 240, arr.ind = TRUE)` e olhe os pares caso a caso — são poucos.

**Rodar a matriz antes de `J` estar fechado.** Cada mudança em `J` invalida três das quatro
matrizes. Desenvolva com um `J` provisório pequeno (10 candidatos) e rode a matriz completa uma
vez, depois que T20.3 fechar.

**Calibrar contra a OD sem fator de expansão.** Regressão não ponderada estima o fator da amostra
estratificada, não o da cidade. `weights = fe_viagem`, sempre.

**Aplicar um fator único a tudo.** O congestionamento não é uniforme no espaço nem no tempo. Um
`f` escalar é uma simplificação — legítima, e provavelmente a certa em cinco semanas — mas ela
precisa estar dita, e o `f` por faixa horária de §3.2 é a versão mínima que já reconhece o
problema.

---

## O que registrar

**Decisões**

- **Perfil de roteamento `car.lua`** para acesso e egresso. Alternativa descartada: perfil a pé ou
  transporte público, com o motivo específico (segmento de mercado de D3 é trabalho/negócios em
  faixa de renda alta).
- **Estimador do fator de congestionamento** — regressão pela origem vs. razão de somas vs.
  regressão com intercepto. Qual vai para a matriz e por quê.
- **Fonte da calibração** — OD declarada como âncora principal, Google/HERE como validação
  amostral. Alternativa descartada: Google como fonte da matriz inteira, rejeitada por custo por
  elemento (250 mil elementos numa matriz 500×500) e por restrição contratual a cache e reuso.
- **Geometria do voo** — euclidiana em UTM 23S, com o número da comparação empírica de §4.1 na
  justificativa, e a ressalva de que a linha reta não é a rota real.
- **Tratamento do tempo intrazonal** — estimativa por raio equivalente ou exclusão dos pares.
- **Recorte do `.pbf`**, se houver, com a caixa envolvente derivada de dado e não digitada.

**Fontes**

| `fonte:` | Limitação obrigatória no registro |
| --- | --- |
| `fonte:osm-geofabrik-sudeste` | **ODbL**: atribuição e *share-alike*; qualidade heterogênea; **sem dados de tráfego**; data do extrato |
| `fonte:osrm` | **roteia em free-flow — subestima o pico de São Paulo**, que é quando o eVTOL ganha |
| `fonte:google-routes` ou `fonte:here-matrix` | pago por elemento / freemium; usado **só como amostra de validação**; termos restringem cache e reuso |

**Pendências**

- `pendencia:` — "a matriz terrestre está em free-flow; o resultado do modelo é conservador contra
  a UAM enquanto `fator_congestionamento` não for calibrado", com aresta `BLOQUEIA` para as
  tarefas de análise (T30–T34) que dependem de `Δ`. Esta é a pendência mais importante do pacote:
  ela é o que impede uma conclusão de sair do forno apoiada em matriz não calibrada.
- `pendencia:` para as faixas horárias **[A CONFIRMAR]** contra a definição de pico da OD 2017.
- `pendencia:` para zonas sem rota, se sobrarem.

**Experimentos** — a rodada com `fator_congestionamento = 1` **é** um experimento e merece nó
próprio, com hipótese ("quanto da cobertura ótima se perde ignorando o congestionamento?") e
conclusão. Ela e a rodada calibrada são o par que sustenta a afirmação de que o fator importa.

**Notas em tarefa** — os números dos *sanity checks* (magnitude da assimetria, quantos pares acima
de 4 h, quantos `NA` e por quê), e a tabela das três âncoras.

**Arquivos** — `arquivo:app-R-consultar-osrm`, `arquivo:app-R-matriz-tempos`,
`arquivo:app-R-calibrar-congestionamento`, com `PRODUZ` para `outputs/matrizes_tempo.rds` e
`outputs/fator_congestionamento.rds`.

**Interação de IA** — `critica_humana` não-vazia. Candidatos honestos a crítica neste pacote: os
parâmetros de Rimjha et al. são norte-americanos e foram transplantados sem adaptação; a faixa de
`|J|` e o `n_alvo` são escolhas de tratabilidade e não medições; e a afirmação de que a diferença
entre euclidiana e geodésica é desprezível só vale depois de o código de §4.1 ter rodado — antes
disso, ela é uma expectativa.

---

## Como isso vira relatório

**Seção de dados.** A descrição das quatro matrizes, suas dimensões e a origem de cada uma. A
tabela de tamanhos de §5, com o contrafactual de 517×517, é o que justifica a agregação de T11
diante de quem perguntar por que não se usou a base completa — e a resposta "não caberia no
solver" fica quantificada em vez de alegada.

**Seção de metodologia.** O procedimento de calibração de §3.2, com a equação da regressão
ponderada e a tabela das três âncoras. Este é um trecho com valor metodológico próprio: cruzar
roteador free-flow, API com tráfego e duração declarada em pesquisa domiciliar não é o que a
literatura de UAM costuma fazer, e é barato.

**Seção de limitações (§4.3 do enunciado).** Três itens: o free-flow do OSRM e a direção do viés
que ele introduz; a linha reta como aproximação da rota de voo, quando o HELICONTROL define
corredores; e os parâmetros de eVTOL importados de contexto norte-americano por ausência de
parâmetro brasileiro publicado.

**Seção de análise de sensibilidade (S3, T30–T34).** `fator_congestionamento` é um dos eixos
naturais — junto com `t̄` e `θ`. A pergunta "quantos vertiportos a mais o modelo abre quando o
congestionamento de pico é reconhecido?" tem resposta direta, e é uma das mais fortes que este
trabalho pode dar, porque conecta um parâmetro de dado a uma recomendação de política.

**Arguição.** A pergunta provável é *"a matriz de vocês é de free-flow?"*. A resposta boa não é
"não" — é: "a base é free-flow, medimos o viés contra a duração declarada da OD e contra uma
amostra de pico, calibramos um fator por faixa horária, e rodamos os dois cenários; a diferença
na solução ótima está na seção X". A pergunta deixa de ser uma armadilha e vira o momento em que
o trabalho mostra profundidade.
