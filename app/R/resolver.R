# @produz    outputs/sol_*.rds
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T23
# Extraído de docs/guias/G08-analises.md. Adaptar, não reescrever.

# app/R/resolver.R
# @produz    outputs/solucao_*.rds
# @consome   outputs/modelo_p1.rds
# @decisao   decisao:[a registrar - congelamento da formulacao]
# @tarefa    tarefa:T30

#' Resolve uma instância do P1, inteira ou relaxada, e devolve tudo que as
#' análises do G08 precisam.
#'
#' Existe com o argumento `inteiro` em vez de duas funções porque a comparação
#' entre Z_IP e Z_LP é o objeto de T30: as duas resoluções têm que ser
#' garantidamente a MESMA matriz, e a única forma de garantir isso é não ter
#' dois caminhos de construção.
#'
#' @param modelo lista no contrato de G07 (ver G08 §0.2)
#' @param inteiro TRUE resolve o MIP; FALSE relaxa as binárias para [0,1]
#' @param tempo_max_s limite de tempo do solver, em segundos
#' @return lista com z, x, duais, status, segundos, n_linhas, n_colunas, n_nz
resolver <- function(modelo, inteiro = TRUE, tempo_max_s = 600) {
  stopifnot(is.list(modelo), inherits(modelo$A, "Matrix"),
            is.logical(inteiro), length(inteiro) == 1,
            length(modelo$obj) == ncol(modelo$A))

  tipos <- if (inteiro) modelo$tipos else rep("C", length(modelo$obj))

  cron <- system.time(
    res <- highs::highs_solve(
      L       = modelo$obj,
      lower   = modelo$lb,
      upper   = modelo$ub,
      A       = modelo$A,
      lhs     = modelo$lhs,
      rhs     = modelo$rhs,
      types   = tipos,
      maximum = TRUE,
      control = highs::highs_control(time_limit = tempo_max_s)
    )
  )

  list(
    z         = res$objective_value,
    x         = res$primal_solution,
    duais     = if (inteiro) NULL else extrair_duais(res),
    status    = res$status_message,
    segundos  = as.numeric(cron[["elapsed"]]),
    n_linhas  = nrow(modelo$A),
    n_colunas = ncol(modelo$A),
    n_nz      = Matrix::nnzero(modelo$A)
  )
}

#' Extrai o vetor de duais de linha do retorno do HiGHS.
#'
#' Encapsulado porque a posição desse vetor no objeto de retorno já mudou entre
#' versões do pacote `highs`. Um `str(res)` uma vez, aqui, evita descobrir a
#' mudança no meio da varredura de sensibilidade.
extrair_duais <- function(res) {
  d <- res$solver_msg$row_dual        # [A CONFIRMAR na versão do renv.lock]
  if (is.null(d)) d <- res$dual
  if (is.null(d)) return(NULL)
  as.numeric(d)
}


# app/R/duais.R
# @produz    outputs/duais.rds
# @consome   outputs/modelo_p1.rds
# @tarefa    tarefa:T31

#' Fixa as binárias na solução inteira ótima e re-resolve o LP restante.
#'
#' Existe porque o MIP não devolve dual algum, e o dual do LP relaxado responde
#' a outra pergunta (o preço-sombra de uma rede fracionária, que não existe).
#' Com y fixo, o que sobra é um LP em w cujos duais têm leitura direta:
#' o valor de servir cada par, dada a rede que efetivamente vamos construir.
#'
#' @param modelo lista no contrato de G07
#' @param y_otimo vetor nomeado 0/1 por id de candidato, do ótimo inteiro
#' @return o mesmo retorno de `resolver()`, com duais não nulos
resolver_restrito <- function(modelo, y_otimo) {
  stopifnot(!is.null(modelo$idx$y), all(modelo$idx$y$id %in% names(y_otimo)))

  m <- modelo
  cols <- m$idx$y$col
  val  <- as.numeric(y_otimo[m$idx$y$id])
  m$lb[cols]    <- val
  m$ub[cols]    <- val
  m$tipos[cols] <- "C"          # já fixas; deixar inteiras só atrapalharia

  resolver(m, inteiro = FALSE)
}

#' Nomeia o vetor de duais usando o mapa de linhas do modelo.
#'
#' Sem isto, o dual é um vetor de números sem endereço. O mapa `modelo$linhas`
#' é o que permite dizer qual componente é pi, qual é alpha_q e qual é gamma_j —
#' e é por isso que ele é parte do contrato do montador, e não um extra.
#'
#' @param modelo lista no contrato de G07
#' @param sol retorno de `resolver()` com duais
#' @return lista com pi (escalar), alpha (data frame q, valor), gamma (data frame j, valor)
nomear_duais <- function(modelo, sol) {
  stopifnot(!is.null(sol$duais), nrow(modelo$linhas) == length(sol$duais))
  d <- data.frame(modelo$linhas, dual = sol$duais)

  list(
    pi    = d$dual[d$bloco == "cardinalidade"],
    alpha = d[d$bloco == "cobertura",  c("q", "dual")],
    gamma = d[d$bloco == "capacidade", c("j", "dual")],
    mu    = d[d$bloco %in% c("liga_o", "liga_d"), c("bloco", "q", "j", "k", "dual")]
  )
}
