# @produz    modelo em memoria
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T23
# Extraído de docs/guias/G07-implementacao.md. Adaptar, não reescrever.

# app/R/montar_matriz_p1.R
# @produz    (objeto de modelo, sem alvo proprio)
# @consome   outputs/colunas_p1.rds
# @tarefa    tarefa:T23

#' Monta P1 como matriz esparsa, no formato que highs::highs_solve() consome.
#'
#' Existe porque o ompr constroi o modelo em R puro e fica muito lento acima de
#' ~1e5 variaveis, que e a ordem de grandeza desta instancia. Toda a matriz sai
#' de vetores construidos de uma vez sobre a tabela de colunas: nao ha loop
#' sobre q, j ou k em lugar nenhum, e e por isso que a montagem leva segundos.
#'
#' @param colunas saida de construir_colunas(), com col_id em 1..nrow
#' @param candidatos data frame com a coluna id
#' @param p cardinalidade maxima
#' @param relaxado TRUE devolve y continuo, para a relaxacao linear e os duais
#' @return lista com A, lhs, rhs, lower, upper, types, objective, offset, maximum
montar_matriz_p1 <- function(colunas, candidatos, p, relaxado = FALSE) {

  stopifnot(identical(colunas$col_id, seq_len(nrow(colunas))))

  idx <- stats::setNames(seq_len(nrow(candidatos)), candidatos$id)
  cj  <- unname(idx[colunas$j])
  ck  <- unname(idx[colunas$k])
  nC  <- nrow(colunas)
  nJ  <- nrow(candidatos)

  q_lin <- as.integer(factor(colunas$q_id))    # linha do bloco 1 de cada coluna
  nQ    <- max(q_lin)
  n_lin <- nQ + 2L * nC + 1L

  lin <- c(q_lin,                                 # bloco 1: w
           nQ + seq_len(nC),                      # bloco 2: +w
           nQ + seq_len(nC),                      # bloco 2: -y_j
           nQ + nC + seq_len(nC),                 # bloco 3: +w
           nQ + nC + seq_len(nC),                 # bloco 3: -y_k
           rep.int(n_lin, nJ))                    # bloco 4: y

  col <- c(seq_len(nC),
           seq_len(nC), nC + cj,
           seq_len(nC), nC + ck,
           nC + seq_len(nJ))

  val <- c(rep.int( 1, nC),
           rep.int( 1, nC), rep.int(-1, nC),
           rep.int( 1, nC), rep.int(-1, nC),
           rep.int( 1, nJ))

  A <- Matrix::sparseMatrix(i = lin, j = col, x = val,
                            dims = c(n_lin, nC + nJ))

  list(
    A         = A,
    lhs       = rep.int(-Inf, n_lin),
    rhs       = c(rep.int(1, nQ), rep.int(0, 2L * nC), p),
    lower     = rep.int(0, nC + nJ),
    upper     = rep.int(1, nC + nJ),
    types     = c(rep.int("C", nC),
                  rep.int(if (relaxado) "C" else "I", nJ)),
    objective = c(colunas$coef, rep.int(0, nJ)),
    offset    = 0,
    maximum   = TRUE
  )
}

#' Resolve o modelo montado por montar_matriz_p1() com HiGHS.
#'
#' @param mp lista devolvida por montar_matriz_p1()
#' @param control lista de opcoes do HiGHS
#' @return o objeto de solucao do pacote highs
resolver_highs <- function(mp, control = list(time_limit = 600, mip_rel_gap = 0)) {
  highs::highs_solve(L       = mp$objective,
                     lower   = mp$lower,
                     upper   = mp$upper,
                     A       = mp$A,
                     lhs     = mp$lhs,
                     rhs     = mp$rhs,
                     types   = mp$types,
                     maximum = mp$maximum,
                     offset  = mp$offset,
                     control = control)
}
