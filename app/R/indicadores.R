# @produz    outputs/indicadores.rds
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T33
# Extraído de docs/guias/G08-analises.md. Adaptar, não reescrever.

# app/R/tabela_indicadores.R
# @produz    outputs/tab_indicadores.rds
# @consome   outputs/solucao_base.rds
# @tarefa    tarefa:T33

#' Monta a tabela dos quatro indicadores comuns do §6.3 a partir de uma solução.
#'
#' Existe como função e não como trecho de relatório porque esses quatro números
#' vão para o painel comparativo entre grupos, e reconstruí-los à mão na véspera
#' é como se produz a divergência que ninguém consegue explicar na arguição.
#' Gerada da solução, ela é sempre coerente com o experimento que a originou.
#'
#' @param sol retorno de `resolver()` sobre o modelo inteiro
#' @param modelo lista no contrato de G07
#' @param arcos data frame de arcos, com coluna f_q (viagens/dia do par)
#' @param od_capturavel saída de G03, para o denominador da participação
#' @param candidatos sf de candidatos, com id e nome
#' @param experimento id do nó de experimento que produziu esta solução
#' @return data frame de uma linha, com os quatro indicadores
tabela_indicadores <- function(sol, modelo, arcos, od_capturavel, candidatos, experimento) {
  stopifnot(!is.null(sol$z), "f_q" %in% names(arcos),
            is.character(experimento), nchar(experimento) > 0)

  w        <- sol$x[modelo$idx$w$col]
  abertos  <- modelo$idx$y$id[sol$x[modelo$idx$y$col] > 0.5]
  atendida <- sum(arcos$f_q * w)
  total_cap <- sum(od_capturavel$viagens_dia)

  data.frame(
    experimento          = experimento,
    n_vertiportos        = length(abertos),
    vertiportos          = paste(sort(candidatos$nome[candidatos$id %in% abertos]),
                                 collapse = "; "),
    demanda_atendida_dia = atendida,
    demanda_capturavel_dia = total_cap,
    participacao         = atendida / total_cap,
    beneficio            = sol$z,
    beneficio_unidade    = "pax.min/dia",
    n_pares_Q            = dplyr::n_distinct(arcos$q),
    n_candidatos_J       = nrow(candidatos),
    n_arcos_P            = nrow(arcos),
    linhas               = sol$n_linhas,
    colunas              = sol$n_colunas,
    nao_zeros            = sol$n_nz,
    segundos             = sol$segundos,
    status               = sol$status,
    stringsAsFactors     = FALSE
  )
}
