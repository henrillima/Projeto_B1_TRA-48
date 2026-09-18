# @produz    modelo em memoria
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T23
# Extraído de docs/guias/G07-implementacao.md. Adaptar, não reescrever.

# app/R/resolver_p1_ompr.R
# @produz    outputs/sol_p1.rds
# @consome   outputs/colunas_p1.rds
# @consome   outputs/candidatos.rds
# @tarefa    tarefa:T23

#' Monta e resolve P1 (MCLP de fluxo bilateral) com ompr sobre HiGHS.
#'
#' As duas restricoes w <= y_j e w <= y_k sao o mecanismo de bilateralidade
#' (G06 §3.1); fundi-las numa so admitiria meia viagem chegando a um vertiporto
#' que nao existe. w e continua por causa da proposicao de G06 §4: dado y
#' inteiro, o otimo em w ja e 0 ou 1, entao declara-la binaria acrescentaria
#' 1e5 variaveis inteiras sem admitir uma unica solucao nova.
#'
#' @param colunas saida de construir_colunas()
#' @param candidatos data frame com a coluna id
#' @param p cardinalidade maxima de vertiportos
#' @param relaxado TRUE resolve a relaxacao linear (y continuo em [0,1])
#' @param agregada TRUE usa a vinculacao agregada de G06 §5, para comparacao
#' @return objeto de modelo do ompr, pronto para solve_model()
montar_p1_ompr <- function(colunas, candidatos, p,
                           relaxado = FALSE, agregada = FALSE) {

  stopifnot(is.data.frame(colunas), nrow(colunas) > 0L,
            "id" %in% names(candidatos), p >= 1)

  idx <- stats::setNames(seq_len(nrow(candidatos)), candidatos$id)
  stopifnot(all(colunas$j %in% names(idx)), all(colunas$k %in% names(idx)))

  cj    <- unname(idx[colunas$j])
  ck    <- unname(idx[colunas$k])
  coef  <- colunas$coef
  nC    <- nrow(colunas)
  nJ    <- nrow(candidatos)

  # a lista de colunas de cada par OD, pre-computada: ver Armadilhas
  idx_q <- unname(split(seq_len(nC), factor(colunas$q_id)))
  nQ    <- length(idx_q)

  # e, para a variante agregada, as colunas em que cada candidato aparece
  idx_j <- unname(split(seq_len(nC), factor(cj, levels = seq_len(nJ))))
  idx_k <- unname(split(seq_len(nC), factor(ck, levels = seq_len(nJ))))

  tipo_y <- if (relaxado) "continuous" else "binary"

  m <- ompr::MIPModel() |>
    ompr::add_variable(y[j], j = 1:nJ, type = tipo_y, lb = 0, ub = 1) |>
    ompr::add_variable(w[c], c = 1:nC, type = "continuous", lb = 0, ub = 1) |>
    ompr::set_objective(ompr::sum_over(coef[c] * w[c], c = 1:nC), "max") |>
    ompr::add_constraint(ompr::sum_over(w[c], c = idx_q[[q]]) <= 1, q = 1:nQ) |>
    ompr::add_constraint(ompr::sum_over(y[j], j = 1:nJ) <= p)

  if (agregada) {
    m <- m |>
      ompr::add_constraint(
        ompr::sum_over(w[c], c = idx_j[[j]]) <= nQ * y[j],
        j = 1:nJ, .show_progress_bar = FALSE) |>
      ompr::add_constraint(
        ompr::sum_over(w[c], c = idx_k[[k]]) <= nQ * y[k],
        k = 1:nJ, .show_progress_bar = FALSE)
  } else {
    m <- m |>
      ompr::add_constraint(w[c] - y[cj[c]] <= 0, c = 1:nC, .show_progress_bar = FALSE) |>
      ompr::add_constraint(w[c] - y[ck[c]] <= 0, c = 1:nC, .show_progress_bar = FALSE)
  }
  m
}
