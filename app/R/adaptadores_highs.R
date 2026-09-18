# @produz    nada; são acessores
# @consome   o objeto de solução de highs::highs_solve()
# @decisao   decisao:D05
# @tarefa    tarefa:T24
#
# A FRONTEIRA COM O `highs` FICA AQUI, E EM NENHUM OUTRO LUGAR.
#
# O G07 §4.5 é explícito sobre isso: o pacote pode renomear campos entre
# versões, e espalhar `sol$objective_value` por dez arquivos faria uma
# atualização do solver quebrar o projeto inteiro em lugares que ninguém
# associa ao solver. Concentrando aqui, uma mudança de versão custa editar
# duas funções.
#
# Os dois acessores procuram o campo numa lista de nomes plausíveis e, se não
# acharem nenhum, **falham dizendo quais campos existem de verdade**. Isso é
# deliberado: um acessor que devolve NULL em silêncio produz um teste que
# passa com valor vazio, que é pior que um teste que falha.

#' Localiza um campo do objeto de solução, ou falha dizendo o que existe.
#'
#' @param sol a lista devolvida por highs::highs_solve()
#' @param candidatos vetor de nomes plausíveis, em ordem de preferência
#' @param oque descrição para a mensagem de erro
.campo_highs <- function(sol, candidatos, oque) {
  achado <- intersect(candidatos, names(sol))
  if (length(achado) == 0) {
    stop(sprintf(
      "não encontrei %s no objeto de solução do highs.\n  Procurei por: %s\n  Existem: %s\n  Ajuste .campo_highs() em app/R/adaptadores_highs.R.",
      oque, paste(candidatos, collapse = ", "),
      paste(names(sol), collapse = ", ")), call. = FALSE)
  }
  sol[[achado[1]]]
}

#' Valor da função objetivo da solução.
#'
#' Em P1 a unidade é pax·min/dia — economia de tempo-passageiro por dia. A
#' unidade precisa estar explicitada em todo lugar que reporta este número:
#' é exigência do §6.3 do enunciado, entre os indicadores comuns a todos os
#' grupos.
#'
#' @param sol objeto devolvido por resolver_highs()
#' @return numérico de comprimento 1
valor_objetivo <- function(sol) {
  v <- .campo_highs(sol, c("objective_value", "objval", "obj_value", "objective"),
                    "o valor da função objetivo")
  as.numeric(v)[1]
}

#' Ids dos vertiportos abertos na solução.
#'
#' Depende do leiaute de colunas de `montar_matriz_p1()`: as primeiras
#' `nrow(colunas)` são as variáveis w, e as `nrow(candidatos)` seguintes são as
#' y, na ordem de `candidatos$id`. Se aquele montador mudar o leiaute, esta
#' função quebra — e é por isso que o `stopifnot` abaixo confere o comprimento
#' antes de fatiar, em vez de confiar.
#'
#' O corte em 0,5 é seguro no MIP, onde y é binária. Na relaxação linear y pode
#' ser fracionária de propósito — é justamente o que a análise de relaxação
#' quer ver (G08 §T30) — e aí "aberto" não é uma pergunta bem posta. Por isso o
#' aviso.
#'
#' @param sol objeto devolvido por resolver_highs()
#' @param colunas a tabela esparsa de colunas usada para montar o modelo
#' @param candidatos data frame de candidatos, com a coluna id
#' @return vetor de ids
vertiportos_abertos <- function(sol, colunas, candidatos) {
  x  <- as.numeric(.campo_highs(sol, c("primal_solution", "solution", "x", "primal"),
                                "o vetor solução primal"))
  nC <- nrow(colunas)
  nJ <- nrow(candidatos)
  stopifnot(length(x) == nC + nJ)

  y <- x[nC + seq_len(nJ)]
  if (any(y > 1e-6 & y < 1 - 1e-6)) {
    warning("há y fracionário na solução: isto é relaxação linear, não MIP. ",
            "'Vertiportos abertos' não é pergunta bem posta aqui.", call. = FALSE)
  }
  candidatos$id[y > 0.5]
}
