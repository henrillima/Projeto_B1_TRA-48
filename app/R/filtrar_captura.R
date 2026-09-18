# @produz    outputs/od_capturavel.rds
# @consome   outputs/macrozonas.rds
# @decisao   decisao:D03
# @tarefa    tarefa:T12
# Extraído de docs/guias/G03-demanda-capturavel.md. Adaptar, não reescrever.

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
