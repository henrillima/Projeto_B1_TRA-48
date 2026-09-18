# @produz    outputs/duais.rds
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T31
# Extraído de docs/guias/G08-analises.md. Adaptar, não reescrever.

# app/R/verificar_pi.R
# @produz    outputs/verificacao_pi.rds
# @consome   outputs/curva_implantacao.rds
# @tarefa    tarefa:T31

#' Confronta o dual da cardinalidade com a diferença finita da curva Z*(p).
#'
#' É o teste de sanidade mais barato de toda a T31: se pi e a diferença finita
#' do LP não baterem, o erro está na extração do dual, e todo o resto da seção
#' econômica estaria sendo escrito sobre um número errado.
#'
#' @param arcos data frame de arcos viáveis
#' @param candidatos vetor de ids
#' @param ps vetor de valores de p a testar
#' @return data frame com p, pi_lp, dif_lp, dif_ip e o erro relativo
verificar_pi <- function(arcos, candidatos, ps = 2:20) {
  stopifnot(length(ps) >= 2, all(diff(ps) == 1))

  z <- purrr::map_dfr(ps, function(p) {
    m  <- montar_modelo(arcos, candidatos, p = p, forma = "desagregada")
    lp <- resolver(m, inteiro = FALSE)
    ip <- resolver(m, inteiro = TRUE)
    data.frame(p = p, z_lp = lp$z, z_ip = ip$z,
               pi_lp = nomear_duais(m, lp)$pi)
  })

  z$dif_lp <- c(diff(z$z_lp), NA_real_)
  z$dif_ip <- c(diff(z$z_ip), NA_real_)
  z$erro_rel <- abs(z$pi_lp - z$dif_lp) / pmax(abs(z$dif_lp), 1e-9)
  z
}
