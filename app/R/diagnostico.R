# @produz    diagnostico no console
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T23
# Extraído de docs/guias/G07-implementacao.md. Adaptar, não reescrever.

guloso <- function(colunas, candidatos, p) {
  abertos <- character(0)
  for (passo in seq_len(p)) {
    restantes <- setdiff(candidatos$id, abertos)
    ganhos <- vapply(restantes,
                     function(v) avaliar_solucao(colunas, c(abertos, v)),
                     numeric(1))
    abertos <- c(abertos, restantes[which.max(ganhos)])
  }
  abertos
}

# app/R/checar_instancia.R
# @tarefa    tarefa:T22

#' Bateria de verificacoes sobre a tabela de colunas, antes de resolver.
#'
#' Falhar cedo e alto e melhor que produzir resultado silenciosamente errado -
#' e num modelo de otimizacao o resultado errado e plausivel e ninguem percebe
#' (convencoes.md §2.2).
#'
#' @param colunas saida de construir_colunas()
#' @param theta_min limiar usado na construcao
#' @param maximo_delta_min maior economia considerada plausivel, em minutos
#' @return colunas, invisivelmente
checar_instancia <- function(colunas, theta_min, maximo_delta_min = 300) {
  stopifnot(
    nrow(colunas) > 0L,
    identical(colunas$col_id, seq_len(nrow(colunas))),
    all(colunas$j != colunas$k),
    min(colunas$delta) >= theta_min,
    max(colunas$delta) <= maximo_delta_min,   # unidade: minutos, nao segundos
    all(colunas$f_q > 0),
    all(is.finite(colunas$coef)),
    !anyDuplicated(colunas[, c("q_id", "j", "k")])
  )
  invisible(colunas)
}
