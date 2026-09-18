# @produz    outputs/candidatos.rds
# @consome   data/raw/anac_aerodromos_privados.csv
# @decisao   decisao:D04
# @tarefa    tarefa:T20
# Extraído de docs/guias/G04-candidatos.md. Adaptar, não reescrever.

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
