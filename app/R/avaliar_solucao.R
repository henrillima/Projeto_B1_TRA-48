# @produz    outputs/indicadores.rds
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T23
# Extraído de docs/guias/G07-implementacao.md. Adaptar, não reescrever.

# app/R/avaliar_solucao.R
# @tarefa    tarefa:T24

#' Valor otimo de P1 dado um conjunto de vertiportos abertos, sem chamar solver.
#'
#' E a proposicao de G06 §4 em codigo: com y fixo, o subproblema em w separa-se
#' por par OD e o otimo e o melhor coeficiente disponivel. Serve para tres
#' coisas: conferir a instancia-brinquedo, avaliar a solucao do baseline
#' unilateral com a regua bilateral (T25), e dar cota inferior inicial ao B&B.
#'
#' @param colunas saida de construir_colunas()
#' @param abertos vetor de ids de candidatos abertos
#' @return valor da funcao objetivo, em pax*min/dia
avaliar_solucao <- function(colunas, abertos) {
  stopifnot(is.data.frame(colunas), is.character(abertos) || is.factor(abertos))
  sel <- colunas[colunas$j %in% abertos & colunas$k %in% abertos, , drop = FALSE]
  if (nrow(sel) == 0L) return(0)
  sum(tapply(sel$coef, sel$q_id, max))
}
