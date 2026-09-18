# @produz    outputs/tempos.rds
# @consome   outputs/macrozonas.rds, outputs/candidatos.rds
# @decisao   decisao:D01
# @tarefa    tarefa:T13
# Extraído de docs/guias/G05-tempos.md. Adaptar, não reescrever.

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
