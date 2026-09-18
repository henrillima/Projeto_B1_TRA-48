# @produz    outputs/relaxacao.rds
# @consome   outputs/colunas.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T30
# Extraído de docs/guias/G08-analises.md. Adaptar, não reescrever.

# app/R/instancias_brinquedo.R
# @produz    outputs/brinquedo_relaxacao.rds
# @tarefa    tarefa:T30

#' Constrói as duas instâncias-brinquedo que exibem a quebra de quase-integralidade.
#'
#' Não é exemplo didático solto: é o teste de regressão do montador de modelo.
#' Se `montar_modelo()` mudar e essas duas pararem de dar 0/0,5 e 1/2, alguma
#' coisa quebrou na restrição de ligação — e num modelo grande isso passaria
#' despercebido, porque a solução continuaria plausível.
#'
#' @return lista com os dois objetos de modelo, prontos para `resolver()`
instancias_brinquedo <- function() {
  arcos_a <- data.frame(q = "q1", j = "v1", k = "v2", coef = 1)
  arcos_b <- data.frame(
    q    = c("q1", "q2", "q3"),
    j    = c("v1", "v1", "v2"),
    k    = c("v2", "v3", "v3"),
    coef = c(1, 1, 1)
  )
  list(
    A = montar_modelo(arcos_a, c("v1", "v2"),             p = 1),
    B = montar_modelo(arcos_b, c("v1", "v2", "v3"),       p = 2)
  )
}


# app/R/montar_modelo.R
# @produz    outputs/modelo_p1.rds
# @consome   outputs/arcos.rds
# @decisao   decisao:[a registrar - forma da restricao de ligacao]
# @tarefa    tarefa:T30

#' Monta as linhas de ligação entre w e y, na forma pedida.
#'
#' As três formas resolvem o MESMO problema inteiro e produzem relaxações
#' diferentes. Ter as três atrás de um argumento — em vez de reescrever o
#' montador — é o que garante que a comparação de T30 compare formulação, e
#' não dois códigos escritos em dias diferentes.
#'
#' @param arcos data frame com q, j, k, coef; uma linha por elemento de P_q
#' @param col_w vetor de índices de coluna das variáveis w, na ordem de `arcos`
#' @param col_y vetor nomeado de índices de coluna das variáveis y, por id
#' @param forma "desagregada", "agregada" ou "media"
#' @return lista com i, j, v (tripletos), rhs, e o data frame `linhas`
linhas_ligacao <- function(arcos, col_w, col_y, forma = c("desagregada", "agregada", "media")) {
  forma <- match.arg(forma)
  stopifnot(nrow(arcos) == length(col_w), all(arcos$j %in% names(col_y)))

  yj <- col_y[arcos$j]
  yk <- col_y[arcos$k]
  n  <- nrow(arcos)

  if (forma == "desagregada") {
    # linha t:      w_t - y_j <= 0        (bloco liga_o)
    # linha n + t:  w_t - y_k <= 0        (bloco liga_d)
    i <- c(seq_len(n), seq_len(n), n + seq_len(n), n + seq_len(n))
    j <- c(col_w,      yj,         col_w,          yk)
    v <- c(rep(1, n),  rep(-1, n), rep(1, n),      rep(-1, n))
    linhas <- data.frame(
      bloco = rep(c("liga_o", "liga_d"), each = n),
      q = rep(arcos$q, 2), j = rep(arcos$j, 2), k = rep(arcos$k, 2),
      linha = seq_len(2 * n)
    )
    return(list(i = i, j = j, v = v, rhs = rep(0, 2 * n), linhas = linhas))
  }

  if (forma == "media") {
    # linha t: w_t - 0,5 y_j - 0,5 y_k <= 0
    i <- c(seq_len(n), seq_len(n), seq_len(n))
    j <- c(col_w,      yj,         yk)
    v <- c(rep(1, n),  rep(-0.5, n), rep(-0.5, n))
    linhas <- data.frame(bloco = "media", q = arcos$q, j = arcos$j, k = arcos$k,
                         linha = seq_len(n))
    return(list(i = i, j = j, v = v, rhs = rep(0, n), linhas = linhas))
  }

  # agregada: uma linha por (j,k) e por lado, com big-M = |Q_jk|
  chave <- paste(arcos$j, arcos$k, sep = "|")
  g     <- match(chave, unique(chave))
  ng    <- max(g)
  mjk   <- as.integer(table(g))                       # |Q_jk|, o big-M mais justo
  par_j <- col_y[arcos$j[!duplicated(g)]]
  par_k <- col_y[arcos$k[!duplicated(g)]]

  i <- c(g,             seq_len(ng),  ng + g,        ng + seq_len(ng))
  j <- c(col_w,         par_j,        col_w,         par_k)
  v <- c(rep(1, n),     -mjk,         rep(1, n),     -mjk)
  linhas <- data.frame(
    bloco = rep(c("liga_o_agr", "liga_d_agr"), each = ng),
    q = NA_character_,
    j = rep(arcos$j[!duplicated(g)], 2), k = rep(arcos$k[!duplicated(g)], 2),
    linha = seq_len(2 * ng)
  )
  list(i = i, j = j, v = v, rhs = rep(0, 2 * ng), linhas = linhas)
}


# app/R/tabela_relaxacao.R
# @produz    outputs/tab_relaxacao.rds
# @tarefa    tarefa:T30

#' Roda as três formas, inteira e relaxada, e monta a tabela de T30.
#'
#' Devolve tamanho da instância junto com o gap porque a comparação só é honesta
#' se o custo de cada formulação aparecer ao lado do benefício: a desagregada
#' compra relaxação forte com linhas, e a tabela precisa mostrar as duas metades.
#'
#' @param arcos data frame de arcos viáveis
#' @param candidatos vetor de ids de candidato
#' @param p orçamento de vertiportos
#' @param formas vetor de formas a comparar
#' @return data frame com uma linha por forma
tabela_relaxacao <- function(arcos, candidatos, p,
                             formas = c("desagregada", "media", "agregada")) {
  stopifnot(is.data.frame(arcos), p >= 1)

  purrr::map_dfr(formas, function(fm) {
    m   <- montar_modelo(arcos, candidatos, p = p, forma = fm)
    ip  <- resolver(m, inteiro = TRUE)
    lp  <- resolver(m, inteiro = FALSE)
    data.frame(
      forma       = fm,
      linhas      = ip$n_linhas,
      colunas     = ip$n_colunas,
      nao_zeros   = ip$n_nz,
      z_ip        = ip$z,
      z_lp        = lp$z,
      gap_abs     = lp$z - ip$z,
      gap_rel     = ifelse(ip$z > 0, (lp$z - ip$z) / lp$z, NA_real_),
      y_frac_lp   = sum(lp$x[m$idx$y$col] > 1e-6 & lp$x[m$idx$y$col] < 1 - 1e-6),
      seg_ip      = ip$segundos,
      seg_lp      = lp$segundos
    )
  })
}
