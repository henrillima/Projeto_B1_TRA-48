# @produz    outputs/sol_unilateral.rds
# @consome   outputs/od_capturavel.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T25
# Extraído de docs/guias/G07-implementacao.md. Adaptar, não reescrever.

# app/R/resolver_mclp_unilateral.R
# @produz    outputs/sol_baseline.rds
# @consome   outputs/od_capturavel.rds
# @consome   outputs/matrizes_tempo.rds
# @tarefa    tarefa:T25

#' Resolve o a-MCLP unilateral (baseline) sobre EXATAMENTE o mesmo dado do P1.
#'
#' A la Volakakis & Mahmassani (2025). E o estado da pratica da literatura
#' aplicada de vertiportos, e serve para duas coisas: comparar quais sitios cada
#' modelo escolhe, e produzir a segunda curva de implantacao. Usa o mesmo Q e o
#' mesmo t_barra do P1 de proposito - se os dados divergirem, a comparacao
#' mede a diferenca de dado e nao a diferenca de formulacao.
#'
#' @param od_capturavel data frame com zona_o, zona_d, viagens_dia
#' @param t_acesso matriz zonas x candidatos, em minutos, com dimnames
#' @param candidatos data frame com a coluna id
#' @param p cardinalidade maxima
#' @param t_barra_min mesmo limiar usado em construir_colunas()
#' @return lista com obj (viagens/dia) e abertos (vetor de ids)
resolver_mclp_unilateral <- function(od_capturavel, t_acesso, candidatos,
                                     p, t_barra_min = 15) {
  stopifnot(is.matrix(t_acesso), !is.null(rownames(t_acesso)), p >= 1)

  h <- tapply(od_capturavel$viagens_dia, od_capturavel$zona_o, sum)
  h <- h[names(h) %in% rownames(t_acesso)]
  zonas <- names(h)

  cobre <- t_acesso[zonas, candidatos$id, drop = FALSE] <= t_barra_min
  nI <- length(zonas); nJ <- nrow(candidatos)

  m <- ompr::MIPModel() |>
    ompr::add_variable(y[j], j = 1:nJ, type = "binary") |>
    ompr::add_variable(z[i], i = 1:nI, type = "continuous", lb = 0, ub = 1) |>
    ompr::set_objective(ompr::sum_over(as.numeric(h)[i] * z[i], i = 1:nI), "max") |>
    ompr::add_constraint(
      z[i] - ompr::sum_over(y[j], j = 1:nJ, cobre[i, j]) <= 0, i = 1:nI) |>
    ompr::add_constraint(ompr::sum_over(y[j], j = 1:nJ) <= p)

  sol <- ompr::solve_model(m, ompr.roi::with_ROI(solver = "highs"))
  ys  <- ompr::get_solution(sol, y[j])

  list(obj     = ompr::objective_value(sol),
       abertos = candidatos$id[ys$j[ys$value > 0.5]])
}
