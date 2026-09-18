# @produz    outputs/curva.rds
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T33
# Extraído de docs/guias/G08-analises.md. Adaptar, não reescrever.

# app/R/curva_implantacao.R
# @produz    outputs/curva_implantacao.rds
# @consome   outputs/arcos.rds
# @tarefa    tarefa:T33

#' Levanta Z*(p) para p = 1..p_max, em um dos dois modelos.
#'
#' Devolve também os abertos de cada p porque a curva sozinha não responde à
#' pergunta que o leitor faz em seguida — "e quais são?" — e porque a sequência
#' de conjuntos ao longo de p diz se a implantação é aninhada (cada passo
#' acrescenta sem remover) ou não. Ela não precisa ser, e quando não é, isso é
#' uma restrição prática de faseamento que o relatório precisa mencionar.
#'
#' @param arcos data frame de arcos viáveis
#' @param candidatos vetor de ids
#' @param p_max maior orçamento a testar
#' @param montar função montadora: `montar_modelo` ou `montar_mclp_unilateral`
#' @return data frame com p, z, segundos, gap, abertos
curva_implantacao <- function(arcos, candidatos, p_max = 25, montar = montar_modelo) {
  stopifnot(p_max >= 2, is.function(montar))

  purrr::map_dfr(seq_len(p_max), function(p) {
    m   <- montar(arcos, candidatos, p = p)
    sol <- resolver(m, inteiro = TRUE)
    data.frame(p = p, z = sol$z, segundos = sol$segundos, status = sol$status,
               abertos = I(list(m$idx$y$id[sol$x[m$idx$y$col] > 0.5])))
  })
}


#' Testa o formato em S da curva de implantação.
#'
#' Reporta a inflexão e a saturação, mas devolve também o vetor inteiro de
#' segundas diferenças: um S de verdade tem um bloco contíguo de sinal positivo,
#' e não um sinal positivo isolado no meio do ruído. A distinção entre as duas
#' coisas é o que separa achado de artefato, e ela não cabe num único número.
#'
#' @param curva saída de `curva_implantacao()`
#' @param tol tolerância absoluta para considerar a segunda diferença nula
#' @param frac_sat fração de Z*(p_max) que define a saturação
#' @return lista com d2, p_inflexao, p_massa_critica, p_saturacao e o veredito
testar_s <- function(curva, tol = 1e-6, frac_sat = 0.95) {
  stopifnot(all(c("p", "z") %in% names(curva)), nrow(curva) >= 5)
  z  <- curva$z[order(curva$p)]
  d1 <- diff(z)
  d2 <- diff(d1)

  sinal <- ifelse(d2 >  tol,  1L, ifelse(d2 < -tol, -1L, 0L))
  pos   <- which(sinal ==  1L)
  neg   <- which(sinal == -1L)

  list(
    d2              = d2,
    marginal        = d1,
    p_massa_critica = if (any(z > tol)) curva$p[which(z > tol)[1]] else NA_integer_,
    p_inflexao      = if (length(pos) && length(neg) && min(pos) < max(neg))
                        curva$p[max(pos[pos < max(neg)]) + 1L] else NA_integer_,
    p_saturacao     = curva$p[which(z >= frac_sat * max(z))[1]],
    tem_bloco_convexo = length(pos) > 0 && all(diff(pos) == 1),
    veredito        = if (length(pos) == 0) "sem trecho convexo — curva côncava"
                      else if (all(diff(pos) == 1)) "S consistente"
                      else "convexidade não contígua — investigar antes de afirmar S"
  )
}
