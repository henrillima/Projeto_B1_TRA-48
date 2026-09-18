# @produz    governanca/data/experimentos/*.yaml
# @consome   a solucao do solver
# @decisao   decisao:D07
# @tarefa    tarefa:T23
# Extraído de docs/guias/G07-implementacao.md. Adaptar, não reescrever.

# app/R/yaml_experimento.R
# @produz    (texto YAML; quem grava e o alvo do targets)
# @tarefa    tarefa:T23

#' Gera o YAML de um no `experimento` a partir do resultado do solver.
#'
#' Pura de proposito: devolve texto e nao escreve arquivo, porque funcao em
#' app/R/ nao tem efeito colateral (convencoes.md §2.2) e porque escrever no
#' grafo e editar YAML e commitar, nunca escrever no banco (CLAUDE.md, regra 2).
#'
#' Exige hipotese E conclusao nao vazias, e falha sem elas. Nao e rigidez: um
#' experimento sem hipotese e uma rodada; um experimento com hipotese e ciencia,
#' e o campo `descricao` do esquema existe justamente para isso.
#'
#' @param id id do no, no formato experimento:E<nn>
#' @param titulo titulo curto e legivel
#' @param parametros lista nomeada de parametros da rodada
#' @param obj valor da funcao objetivo
#' @param gap gap relativo devolvido pelo solver
#' @param segundos tempo de solucao
#' @param commit hash curto do commit; passado de fora, nunca lido por system()
#' @param hipotese o que se esperava ANTES de rodar
#' @param conclusao o que se aprendeu depois
#' @param arestas lista de listas com rel e dst
#' @param criado_em data da rodada
#' @return string com o YAML do no, pronta para gravar
yaml_experimento <- function(id, titulo, parametros, obj, gap, segundos, commit,
                             hipotese, conclusao,
                             arestas   = list(list(rel = "ASSINADA_POR", dst = "pessoa:henri")),
                             criado_em = Sys.Date()) {

  stopifnot(grepl("^experimento:E[0-9]{2}$", id),
            is.list(parametros), length(parametros) > 0L,
            is.finite(obj), is.finite(segundos),
            nzchar(trimws(commit)),
            nchar(trimws(hipotese))  >= 20L,
            nchar(trimws(conclusao)) >= 20L)

  no <- list(
    id         = id,
    kind       = "experimento",
    titulo     = titulo,
    criado_em  = as.character(criado_em),
    commit     = commit,
    parametros = parametros,
    obj        = obj,
    gap        = gap,
    segundos   = segundos,
    descricao  = paste0("Hipotese: ", trimws(hipotese), "\n",
                        "Conclusao: ", trimws(conclusao), "\n"),
    arestas    = arestas
  )
  yaml::as.yaml(no, indent = 2)
}

#' Extrai da solucao os campos que o no `experimento` precisa.
#'
#' Concentra num lugar so a dependencia dos nomes de campo do pacote highs, que
#' variam entre versoes. Confira uma vez com str(sol) e ajuste aqui.
#'
#' @param sol objeto de solucao
#' @param segundos tempo medido com system.time() em volta da chamada do solver
#' @return lista com obj, gap e segundos
resumo_solver <- function(sol, segundos) {
  list(obj      = valor_objetivo(sol),
       gap      = gap_relativo(sol),
       segundos = as.numeric(segundos))
}
