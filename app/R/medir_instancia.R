# @produz    outputs/instancia.rds
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T22
# Extraído de docs/guias/G07-implementacao.md. Adaptar, não reescrever.

# app/R/medir_instancia.R
# @produz    outputs/instancia_medida.rds
# @consome   outputs/colunas_p1.rds
# @tarefa    tarefa:T22

#' Mede o tamanho real da instancia antes de qualquer modelagem.
#'
#' Existe porque as estimativas do plano (|Q| entre 2e3 e 4e3, |P_q| medio entre
#' 20 e 60, w entre 4e4 e 2e5) sao ORDEM DE GRANDEZA, nao medicao - e estao
#' assim declaradas em docs/00-plano-5-semanas.md e em 01-revisao-literatura.md.
#' Escrever o modelo sobre a estimativa e descobrir o tamanho quando o ompr
#' travar e perder um dia; medir custa dois segundos.
#'
#' @param colunas saida de construir_colunas()
#' @param od_capturavel data frame de pares OD elegiveis (denominador da cobertura)
#' @param candidatos data frame de candidatos, com coluna id
#' @return data frame de uma linha com as contagens da instancia
medir_instancia <- function(colunas, od_capturavel, candidatos) {
  stopifnot(is.data.frame(colunas), nrow(colunas) > 0L)

  n_pq <- as.integer(table(colunas$q_id))
  nQ_e <- sum(od_capturavel$viagens_dia > 0 &
                od_capturavel$zona_o != od_capturavel$zona_d)

  data.frame(
    Q_elegiveis   = nQ_e,
    Q_com_opcao   = length(n_pq),
    Q_sem_opcao   = nQ_e - length(n_pq),
    soma_Pq       = nrow(colunas),
    Pq_medio      = mean(n_pq),
    Pq_mediana    = stats::median(n_pq),
    Pq_p95        = unname(stats::quantile(n_pq, 0.95)),
    Pq_max        = max(n_pq),
    var_w         = nrow(colunas),
    var_y         = nrow(candidatos),
    linhas_desagr = length(n_pq) + 2L * nrow(colunas) + 1L,
    linhas_agr    = length(n_pq) + 2L * nrow(candidatos) + 1L,
    nao_zeros     = 5L * nrow(colunas) + nrow(candidatos)
  )
}

#' Falha o pipeline quando a instancia passa do limite de tratabilidade.
#'
#' E um portao, nao um aviso. Um aviso impresso no console e um aviso que
#' ninguem le; um erro no alvo do targets obriga a decisao a ser tomada e
#' registrada, que e o comportamento que o plano pede na S2.
#'
#' @param medida saida de medir_instancia()
#' @param limite numero maximo de variaveis w aceito sem revisao
#' @return a propria medida, invisivelmente, quando passa
checar_tamanho <- function(medida, limite = 2e5) {
  if (medida$soma_Pq > limite) {
    stop("Instancia com ", medida$soma_Pq, " colunas w, acima do limite de ", limite,
         ". Aperte t_barra e theta, ou agregue mais zonas em T11 - e REGISTRE a decisao ",
         "com as alternativas descartadas antes de seguir.")
  }
  invisible(medida)
}
