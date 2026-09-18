# @produz    outputs/colunas.rds
# @consome   outputs/od_capturavel.rds, outputs/candidatos.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T22
# Extraído de docs/guias/G07-implementacao.md. Adaptar, não reescrever.

# app/R/construir_colunas.R
# @produz    outputs/colunas_p1.rds
# @consome   outputs/od_capturavel.rds
# @consome   outputs/matrizes_tempo.rds
# @consome   outputs/candidatos.rds
# @decisao   decisao:[a registrar - valores de t_barra e theta]
# @tarefa    tarefa:T22

#' Converte matriz para tabela longa preservando os dimnames como texto.
#'
#' Existe porque todo o pre-processamento e feito por join sobre ids, nunca por
#' posicao. Indexar por posicao sobrevive a todo teste ate a hora em que a ordem
#' de J muda por um filtro novo - e ai a solucao continua otima para a instancia
#' errada, sem sintoma nenhum.
#'
#' @param m matriz com dimnames nos dois eixos
#' @param nomes vetor de tres nomes de coluna: linha, coluna, valor
#' @return data frame com tres colunas, as duas primeiras de texto
matriz_para_tabela <- function(m, nomes) {
  stopifnot(is.matrix(m), length(nomes) == 3L,
            !is.null(rownames(m)), !is.null(colnames(m)))
  df <- as.data.frame(as.table(m), stringsAsFactors = FALSE)
  names(df) <- nomes
  df
}

#' Constroi a tabela esparsa de colunas w_qjk do modelo P1.
#'
#' Este e o passo que torna o modelo tratavel: a tabela resultante tem
#' sum_q |P_q| linhas, e nao |Q| * |J|^2. Os dois limiares sao PARAMETROS e nao
#' constantes (regra 8 do CLAUDE.md) porque sao os dois eixos principais da
#' analise de sensibilidade da S3 - e porque mudar t_barra nao muda um
#' coeficiente, muda quais colunas existem: cada valor e um modelo novo.
#'
#' @param od_capturavel data frame com zona_o, zona_d, viagens_dia (saida de T12)
#' @param matrizes lista com t_acesso, t_egresso, t_voo, T_terrestre, em minutos
#' @param t_barra_min tempo maximo de acesso e de egresso admitido
#' @param theta_min economia de tempo minima para o par ser servivel
#' @param tau_emb_min processamento no vertiporto de origem
#' @param tau_des_min processamento no vertiporto de destino
#' @param bloco numero de pares OD processados por vez no join
#' @return data frame com col_id, q_id, zona_o, zona_d, j, k, f_q, delta, coef
construir_colunas <- function(od_capturavel,
                              matrizes,
                              t_barra_min  = 15,
                              theta_min    = 10,
                              tau_emb_min  = 5,
                              tau_des_min  = 5,
                              bloco        = 500L) {

  stopifnot(is.data.frame(od_capturavel),
            all(c("zona_o", "zona_d", "viagens_dia") %in% names(od_capturavel)),
            all(c("t_acesso", "t_egresso", "t_voo", "T_terrestre") %in% names(matrizes)),
            t_barra_min > 0, theta_min >= 0,
            tau_emb_min >= 0, tau_des_min >= 0, bloco >= 1L)

  m_ter <- matrizes$T_terrestre   # nome distinto do da coluna, de proposito: ver Armadilhas

  viz_o <- matriz_para_tabela(matrizes$t_acesso,  c("zona", "j", "t_acc"))
  viz_o <- viz_o[viz_o$t_acc <= t_barra_min, , drop = FALSE]

  viz_d <- matriz_para_tabela(matrizes$t_egresso, c("k", "zona", "t_egr"))
  viz_d <- viz_d[viz_d$t_egr <= t_barra_min, , drop = FALSE]

  voo   <- matriz_para_tabela(matrizes$t_voo,     c("j", "k", "t_voo"))

  pares <- od_capturavel[od_capturavel$viagens_dia > 0 &
                           od_capturavel$zona_o != od_capturavel$zona_d, , drop = FALSE]
  pares$q_id  <- seq_len(nrow(pares))
  pares$t_ter <- m_ter[cbind(match(pares$zona_o, rownames(m_ter)),
                             match(pares$zona_d, colnames(m_ter)))]
  stopifnot(all(is.finite(pares$t_ter)))

  blocos <- split(pares, ceiling(pares$q_id / bloco))

  colunas <- dplyr::bind_rows(lapply(blocos, function(g) {
    g |>
      dplyr::inner_join(viz_o, by = c("zona_o" = "zona"),
                        relationship = "many-to-many") |>
      dplyr::inner_join(viz_d, by = c("zona_d" = "zona"),
                        relationship = "many-to-many") |>
      dplyr::filter(.data$j != .data$k) |>
      dplyr::inner_join(voo, by = c("j", "k")) |>
      dplyr::mutate(
        t_uam = .data$t_acc + tau_emb_min + .data$t_voo + tau_des_min + .data$t_egr,
        delta = .data$t_ter - .data$t_uam
      ) |>
      dplyr::filter(.data$delta >= theta_min) |>
      dplyr::select("q_id", "zona_o", "zona_d", "j", "k",
                    f_q = "viagens_dia", "delta")
  }))

  colunas$coef   <- colunas$f_q * colunas$delta
  colunas$col_id <- seq_len(nrow(colunas))

  stopifnot(min(colunas$delta) >= theta_min,
            all(colunas$j != colunas$k),
            !anyDuplicated(colunas$col_id))
  colunas
}
