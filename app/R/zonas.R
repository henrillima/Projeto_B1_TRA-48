# @produz    outputs/macrozonas.rds
# @consome   outputs/od_expandida.rds
# @decisao   decisao:D01
# @tarefa    tarefa:T11
# Extraído de docs/guias/G02-dados-od.md. Adaptar, não reescrever.

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
