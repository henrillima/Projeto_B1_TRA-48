# @produz    outputs/od_bruta.rds
# @consome   data/raw/OD-2017.zip
# @decisao   decisao:D02
# @tarefa    tarefa:T10
# Extraído de docs/guias/G02-dados-od.md. Adaptar, não reescrever.

# app/R/mapa_variaveis_od.R
# @produz    (objeto de configuração, sem arquivo)
# @decisao   decisao:D02
# @tarefa    tarefa:T10.1

#' Mapa entre os nomes canônicos usados no projeto e os nomes reais das colunas da OD 2017.
#'
#' Existe porque os nomes reais das variáveis da OD não estavam confirmados em nenhuma
#' fonte acessível no levantamento de 24/08 (ver docs/02-fontes-de-dados.md §1.4). Em vez
#' de espalhar nomes possivelmente errados por todo o código, o projeto programa contra
#' nomes canônicos e resolve a tradução em um único ponto, preenchido a partir da planilha
#' de layout que vem dentro do OD-2017.zip.
#'
#' @return vetor nomeado: nomes canônicos -> nomes reais no banco
mapa_variaveis_od <- function() {
  c(
    zona_o      = "[PREENCHER a partir do layout]",
    zona_d      = "[PREENCHER]",
    municipio_o = "[PREENCHER]",
    municipio_d = "[PREENCHER]",
    modo_prin   = "[PREENCHER]",
    motivo_d    = "[PREENCHER]",
    duracao     = "[PREENCHER]",
    hora_saida  = "[PREENCHER]",
    renda_fa    = "[PREENCHER]",
    faixa_renda = "[PREENCHER]",
    fe_dom      = "[PREENCHER]",
    fe_pes      = "[PREENCHER]",
    fe_via      = "[PREENCHER]"
  )
}


# app/R/ler_od.R
# @produz    data/interim/od_viagens.rds
# @consome   data/raw/od2017/
# @decisao   decisao:D02
# @tarefa    tarefa:T10.1

#' Lê o banco de viagens da OD 2017 e devolve as colunas canônicas do projeto.
#'
#' Esta é uma das poucas funções do projeto que toca disco: o caminho vem do targets, e
#' toda a transformação a jusante é pura. Ela não filtra, não agrega e não expande —
#' devolve o nível viagem inteiro, porque a expansão e o filtro são decisões registradas
#' (decisao:D03) que precisam ser reversíveis sem reler o banco.
#'
#' @param caminho_sav caminho do .sav dentro de `Banco de Dados`
#' @param mapa vetor nomeado de mapa_variaveis_od()
#' @param manter_rotulos se TRUE, converte colunas rotuladas do SPSS em factor
#' @return data frame no nível viagem, com nomes canônicos
ler_od <- function(caminho_sav, mapa = mapa_variaveis_od(), manter_rotulos = TRUE) {
  stopifnot(file.exists(caminho_sav), is.character(mapa), !any(grepl("PREENCHER", mapa)))

  bruto <- haven::read_sav(caminho_sav)

  faltantes <- setdiff(unname(mapa), names(bruto))
  if (length(faltantes) > 0) {
    stop("Colunas ausentes no banco: ", paste(faltantes, collapse = ", "),
         ". Conferir o layout dentro do OD-2017.zip.")
  }

  od <- bruto[, unname(mapa), drop = FALSE]
  names(od) <- names(mapa)

  if (manter_rotulos) {
    rotulaveis <- c("modo_prin", "motivo_d", "faixa_renda")
    for (v in intersect(rotulaveis, names(od))) {
      od[[v]] <- haven::as_factor(od[[v]], levels = "default")
    }
  }

  tibble::as_tibble(od)
}


#' @param caminho_dbf caminho do .dbf dentro de `Banco de Dados`
ler_od_dbf <- function(caminho_dbf, mapa = mapa_variaveis_od()) {
  stopifnot(file.exists(caminho_dbf))
  bruto <- foreign::read.dbf(caminho_dbf, as.is = TRUE)
  # DBF do Metrô não declara codificação; acentos vêm quebrados se não converter
  chr <- vapply(bruto, is.character, logical(1))
  bruto[chr] <- lapply(bruto[chr], function(x) iconv(x, from = "latin1", to = "UTF-8"))
  od <- bruto[, unname(mapa), drop = FALSE]
  names(od) <- names(mapa)
  tibble::as_tibble(od)
}
