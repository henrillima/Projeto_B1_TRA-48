# @produz    outputs/od_expandida.rds
# @consome   outputs/od_bruta.rds
# @decisao   decisao:D02
# @tarefa    tarefa:T10.3
# Extraído de docs/guias/G02-dados-od.md. Adaptar, não reescrever.

# app/R/expandir.R
# @produz    data/interim/od_expandida.rds
# @consome   data/interim/od_viagens.rds
# @decisao   decisao:D02
# @tarefa    tarefa:T10.3

#' Constrói a matriz OD de viagens diárias por par de zonas, expandida pelo fator de viagem.
#'
#' Existe como função separada da leitura porque a expansão é o ponto onde o erro clássico
#' da OD acontece (misturar níveis de fator) e onde o teste de validação da tarefa:T10.3
#' se aplica. Isolá-la torna o erro testável em vez de difuso.
#'
#' @param od data frame no nível viagem, saída de ler_od()
#' @param por vetor de colunas de agrupamento além de zona_o e zona_d
#' @return data frame com zona_o, zona_d, as colunas de `por`, e viagens_dia
expandir_viagens <- function(od, por = character(0)) {
  stopifnot(is.data.frame(od),
            all(c("zona_o", "zona_d", "fe_via") %in% names(od)),
            all(por %in% names(od)))

  od |>
    dplyr::filter(!is.na(zona_o), !is.na(zona_d), !is.na(fe_via)) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c("zona_o", "zona_d", por)))) |>
    dplyr::summarise(viagens_dia = sum(fe_via), .groups = "drop")
}

#' População expandida por zona, no nível pessoa.
#'
#' Separada de propósito: é a função que NÃO pode usar fe_via. A desduplicação por
#' id de pessoa é obrigatória porque a tabela distribuída vem achatada no nível viagem.
#'
#' @param od data frame no nível viagem, com id de pessoa e fe_pes
#' @param col_id_pessoa nome da coluna que identifica a pessoa (ver layout)
#' @return data frame com zona (do domicílio) e pessoas
expandir_pessoas <- function(od, col_id_pessoa) {
  stopifnot(is.data.frame(od), col_id_pessoa %in% names(od), "fe_pes" %in% names(od))

  od |>
    dplyr::distinct(.data[[col_id_pessoa]], .keep_all = TRUE) |>
    dplyr::group_by(zona_dom = .data$zona_dom) |>
    dplyr::summarise(pessoas = sum(.data$fe_pes), .groups = "drop")
}

#' Média ponderada segura: falha se o peso vier de outro nível por engano.
#'
#' @param x vetor numérico
#' @param w vetor de pesos, do mesmo nível de x
media_ponderada <- function(x, w) {
  stopifnot(length(x) == length(w), all(w >= 0, na.rm = TRUE))
  ok <- !is.na(x) & !is.na(w)
  sum(x[ok] * w[ok]) / sum(w[ok])
}


# app/R/validar_expansao.R
# @produz    outputs/validacao_expansao.rds
# @consome   data/interim/od_viagens.rds
# @tarefa    tarefa:T10.3

#' Confronta os totais expandidos com os números publicados pelo Metrô para a OD 2017.
#'
#' Este é o teste que a nota da tarefa:T10.3 descreve: se o total de viagens não
#' reproduzir os 42 milhões publicados, o erro provável é de nível de fator de expansão.
#' Os valores de referência são parâmetros e não constantes, porque a mesma função
#' precisa servir para validar a OD 2023 se os microdados aparecerem (pendencia:P01).
#'
#' @param od data frame no nível viagem, saída de ler_od()
#' @param alvo_viagens_dia total publicado de viagens diárias
#' @param tolerancia desvio relativo aceito
#' @return data frame com indicador, valor obtido, valor de referência e desvio relativo
validar_expansao <- function(od,
                             alvo_viagens_dia = 42e6,
                             tolerancia       = 0.02) {
  stopifnot(is.data.frame(od), "fe_via" %in% names(od), tolerancia > 0)

  total <- sum(od$fe_via, na.rm = TRUE)

  data.frame(
    indicador  = "viagens_dia_total",
    obtido     = total,
    referencia = alvo_viagens_dia,
    desvio_rel = (total - alvo_viagens_dia) / alvo_viagens_dia,
    passou     = abs(total - alvo_viagens_dia) / alvo_viagens_dia <= tolerancia
  )
}


#' @param od data frame no nível viagem
#' @param col_modo coluna de modo principal já classificada em coletivo/individual/nao_motorizado
#' @return data frame com participação de cada grupo modal, ponderada por fe_via
validar_divisao_modal <- function(od, col_modo = "grupo_modal") {
  stopifnot(col_modo %in% names(od))

  od |>
    dplyr::group_by(grupo = .data[[col_modo]]) |>
    dplyr::summarise(viagens = sum(fe_via, na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(participacao = viagens / sum(viagens))
}


# app/R/calibrar_nivel.R
# @produz    data/interim/od_calibrada.rds
# @consome   data/interim/od_expandida.rds
# @decisao   decisao:D02
# @tarefa    tarefa:T10.3

#' Aplica o fator de correção de nível de 2017 para 2023 sobre a matriz OD expandida.
#'
#' A OD 2023 publicou agregados mas não microdados identificáveis (pendencia:P01), então
#' a única correção defensável é de nível, não de estrutura: reescala o volume total sem
#' alterar a distribuição espacial entre pares. A hipótese embutida — que a queda foi
#' aproximadamente homogênea no espaço — é falsa e precisa estar dita no relatório.
#'
#' @param od_matriz saída de expandir_viagens()
#' @param viagens_2017 total publicado da OD 2017
#' @param viagens_2023 total publicado da OD 2023
#' @param por_grupo se fornecido, nome da coluna de grupo modal para calibração diferenciada
#' @param fatores_grupo vetor nomeado de fatores por grupo modal, se por_grupo for usado
#' @return od_matriz com a coluna viagens_dia reescalada e o fator aplicado registrado
calibrar_nivel <- function(od_matriz,
                           viagens_2017  = 42.0e6,
                           viagens_2023  = 35.6e6,
                           por_grupo     = NULL,
                           fatores_grupo = NULL) {
  stopifnot(is.data.frame(od_matriz), "viagens_dia" %in% names(od_matriz),
            viagens_2017 > 0, viagens_2023 > 0)

  if (is.null(por_grupo)) {
    fator <- viagens_2023 / viagens_2017          # ~ 0,8476
    return(dplyr::mutate(od_matriz,
                         viagens_dia   = viagens_dia * fator,
                         fator_nivel   = fator))
  }

  stopifnot(por_grupo %in% names(od_matriz), !is.null(fatores_grupo),
            all(unique(od_matriz[[por_grupo]]) %in% names(fatores_grupo)))

  dplyr::mutate(od_matriz,
                fator_nivel = unname(fatores_grupo[as.character(.data[[por_grupo]])]),
                viagens_dia = viagens_dia * fator_nivel)
}
