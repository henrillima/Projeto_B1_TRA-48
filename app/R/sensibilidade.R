# @produz    outputs/sensib.rds
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T32
# Extraído de docs/guias/G08-analises.md. Adaptar, não reescrever.

# app/R/varredura.R
# @produz    outputs/sensibilidade.rds
# @consome   outputs/arcos_completo.rds
# @tarefa    tarefa:T32

#' Varre a grade de limiares e devolve valor e solução de cada célula.
#'
#' Recebe os arcos SEM filtro de t_barra e theta e filtra dentro do laço, porque
#' reconstruir P_q a partir do dado bruto a cada célula é o que garante que a
#' varredura mede o efeito do parâmetro, e não o efeito de um cache que alguém
#' esqueceu de invalidar.
#'
#' @param arcos_completo arcos com t_acesso, t_egresso e delta, sem filtro
#' @param candidatos vetor de ids de candidato
#' @param grade data frame com colunas t_barra e theta
#' @param p orçamento fixo durante a varredura
#' @return data frame com uma linha por célula: parâmetros, z, tempo, e a lista de abertos
varrer_limiares <- function(arcos_completo, candidatos, grade, p) {
  stopifnot(all(c("t_barra", "theta") %in% names(grade)),
            all(c("t_acesso", "t_egresso", "delta", "coef") %in% names(arcos_completo)))

  purrr::pmap_dfr(grade, function(t_barra, theta) {
    a <- dplyr::filter(arcos_completo,
                       t_acesso  <= t_barra,
                       t_egresso <= t_barra,
                       delta     >= theta)
    if (nrow(a) == 0) {
      return(data.frame(t_barra = t_barra, theta = theta, n_arcos = 0L,
                        z = 0, segundos = 0, abertos = I(list(character(0)))))
    }
    m   <- montar_modelo(a, candidatos, p = p, forma = "desagregada")
    sol <- resolver(m, inteiro = TRUE)
    y   <- m$idx$y$id[sol$x[m$idx$y$col] > 0.5]
    data.frame(t_barra = t_barra, theta = theta, n_arcos = nrow(a),
               z = sol$z, segundos = sol$segundos, abertos = I(list(y)))
  })
}


#' Frequência de seleção de cada candidato ao longo da grade de sensibilidade.
#'
#' A estabilidade da SOLUÇÃO é mais defensável que a estabilidade do VALOR: o
#' relatório recomenda locais, não recomenda um número. Um vertiporto que
#' aparece em todos os cenários é uma recomendação; um que aparece em metade é
#' uma hipótese com endereço.
#'
#' @param sens saída de `varrer_limiares()`
#' @param candidatos vetor de ids de candidato
#' @return data frame com id, n_cenarios, freq, e a classificação
estabilidade <- function(sens, candidatos) {
  stopifnot(nrow(sens) > 0)
  n <- nrow(sens)
  cont <- table(factor(unlist(sens$abertos), levels = candidatos))
  data.frame(id = candidatos,
             n_cenarios = as.integer(cont),
             freq = as.integer(cont) / n) |>
    dplyr::mutate(classe = dplyr::case_when(
      freq >= 1            ~ "nucleo",
      freq >  0            ~ "periferia_de_decisao",
      TRUE                 ~ "nunca"
    )) |>
    dplyr::arrange(dplyr::desc(freq))
}
