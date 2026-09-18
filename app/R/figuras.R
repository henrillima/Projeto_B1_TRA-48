# @produz    outputs/fig/*.png
# @consome   outputs/curva.rds, outputs/sensib.rds, outputs/sol_bilateral.rds
# @decisao   decisao:D05
# @tarefa    tarefa:T33
#
# Figuras do relatório. Três regras que valem para todas e não são gosto:
#
#   1. UM eixo. Nunca dois eixos y. Duas medidas de escala diferente viram
#      duas figuras ou são indexadas a uma base comum.
#   2. Categórica = ordem fixa de matizes, nunca ciclada. Sequencial = UM
#      matiz, claro para escuro. Nunca arco-íris num mapa de calor.
#   3. Identidade nunca só por cor: com duas séries, rótulo direto na curva
#      além da cor, porque o relatório pode ser impresso em preto e branco.
#
# A paleta abaixo foi validada para daltonismo, não escolhida por gosto:
# separação ΔE 13,7 em deuteranopia e 27,0 em visão normal, ambas acima do
# piso, com croma e contraste contra fundo claro aprovados.

# --- paleta ----------------------------------------------------------------
COR_BILATERAL  <- "#0E9488"   # teal
COR_UNILATERAL <- "#C2410C"   # laranja queimado
COR_TINTA      <- "#1F2937"   # texto primário
COR_SECUNDARIA <- "#6B7280"   # texto secundário, eixos
COR_GRADE      <- "#E5E7EB"   # grade recessiva
COR_SEQ_BAIXO  <- "#E6F4F2"   # rampa sequencial: claro
COR_SEQ_ALTO   <- "#0B5F57"   #                   escuro

#' Tema comum das figuras: grade recessiva, sem moldura, texto sóbrio.
#'
#' `base_size = 11` porque a figura entra no LaTeX em largura de coluna e o
#' texto precisa bater com o corpo do relatório. Aumentar aqui e reduzir no
#' \includegraphics produz tipografia inconsistente entre figuras.
tema_b1 <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor   = ggplot2::element_blank(),
      panel.grid.major   = ggplot2::element_line(colour = COR_GRADE, linewidth = 0.3),
      axis.title         = ggplot2::element_text(colour = COR_SECUNDARIA, size = base_size - 1),
      axis.text          = ggplot2::element_text(colour = COR_SECUNDARIA),
      plot.title         = ggplot2::element_text(colour = COR_TINTA, face = "bold",
                                                 size = base_size + 1),
      plot.subtitle      = ggplot2::element_text(colour = COR_SECUNDARIA,
                                                 size = base_size - 1),
      plot.caption       = ggplot2::element_text(colour = COR_SECUNDARIA,
                                                 size = base_size - 2, hjust = 0),
      legend.position    = "none",   # duas séries -> rótulo direto, não legenda
      plot.margin        = ggplot2::margin(6, 14, 6, 6)
    )
}

#' Salva em PNG com DPI de impressão e devolve o caminho.
#'
#' Devolver o caminho é o que permite declarar o alvo com `format = "file"` no
#' `_targets.R` — e é assim que `tar_outdated()` consegue dizer que uma figura
#' do relatório foi gerada por código que já mudou.
salvar <- function(p, arquivo, largura = 16, altura = 10) {
  dir.create(dirname(arquivo), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(arquivo, p, width = largura, height = altura,
                  units = "cm", dpi = 300, bg = "white")
  arquivo
}


# ---------------------------------------------------------------------------
#  Figura central: a curva de implantação, bilateral contra unilateral
# ---------------------------------------------------------------------------

#' Curva de implantação: benefício em função do número de vertiportos.
#'
#' É a figura que sustenta a recomendação final (§4.4 do enunciado) e o
#' resultado central do trabalho. A previsão teórica é que a curva bilateral
#' tenha Z*(1) = 0 — um vertiporto sozinho não serve par algum — e formato em
#' S, enquanto a unilateral é côncava desde p = 1. Se o S não aparecer, a
#' figura continua valendo: mostrar o que não funcionou é critério explícito
#' de excelência, e o texto do relatório é que muda, não o gráfico.
#'
#' Linha sólida e linha tracejada, além das cores: a distinção não pode
#' depender só de cor, porque o relatório pode sair impresso em escala de
#' cinza.
#'
#' @param curva data frame com p, Z e formulacao ("bilateral"/"unilateral")
#' @param inflexao p do ponto de inflexão detectado por `testar_s()`, ou NULL
#' @param arquivo caminho de saída
#' @return o caminho do arquivo gerado
plotar_curva <- function(curva, inflexao = NULL,
                         arquivo = "outputs/fig/curva_implantacao.png") {
  stopifnot(is.data.frame(curva),
            all(c("p", "Z", "formulacao") %in% names(curva)))

  rotulos <- curva |>
    dplyr::group_by(.data$formulacao) |>
    dplyr::filter(.data$p == max(.data$p)) |>
    dplyr::ungroup()

  p <- ggplot2::ggplot(curva, ggplot2::aes(.data$p, .data$Z,
                                           colour = .data$formulacao,
                                           linetype = .data$formulacao)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 1.6) +
    ggplot2::geom_text(data = rotulos,
                       ggplot2::aes(label = .data$formulacao),
                       hjust = -0.08, vjust = 0.5, size = 3.2, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = c(bilateral  = COR_BILATERAL,
                                            unilateral = COR_UNILATERAL)) +
    ggplot2::scale_linetype_manual(values = c(bilateral = "solid",
                                              unilateral = "22")) +
    ggplot2::scale_x_continuous(breaks = scales::pretty_breaks(8),
                                expand = ggplot2::expansion(mult = c(0.02, 0.18))) +
    ggplot2::scale_y_continuous(labels = scales::label_number(big.mark = ".",
                                                             decimal.mark = ",")) +
    ggplot2::labs(
      title    = "Curva de implantação",
      subtitle = "Economia de tempo-passageiro capturada por número de vertiportos abertos",
      x        = "p — vertiportos implantados",
      y        = "Z* — pax·min/dia",
      caption  = "Cobertura bilateral exige vertiporto na origem e no destino; a unilateral, só num dos lados."
    ) +
    tema_b1()

  if (!is.null(inflexao)) {
    p <- p +
      ggplot2::geom_vline(xintercept = inflexao, colour = COR_SECUNDARIA,
                          linetype = "dotted", linewidth = 0.4) +
      ggplot2::annotate("text", x = inflexao, y = Inf, label = " massa crítica",
                        hjust = 0, vjust = 1.6, size = 3, colour = COR_SECUNDARIA)
  }
  salvar(p, arquivo)
}


# ---------------------------------------------------------------------------
#  Sensibilidade: mapa de calor bidimensional
# ---------------------------------------------------------------------------

#' Mapa de calor de Z* sobre a grade (t̄, θ).
#'
#' Magnitude, não identidade: rampa SEQUENCIAL de um matiz só, claro para
#' escuro. Arco-íris aqui seria erro — inventa fronteiras onde o dado é
#' contínuo, e some no daltonismo.
#'
#' O que cada eixo mede, e é isso que vai na leitura do relatório: `t̄` mede
#' quanto a UAM depende do first/last mile; `θ` mede a fragilidade da
#' proposta de valor.
#'
#' Valor impresso em cada célula porque a grade é pequena (~16 células) e
#' contraste de cor sozinho não permite ler a magnitude exata.
plotar_sensibilidade <- function(sensib, arquivo = "outputs/fig/sensibilidade.png") {
  stopifnot(is.data.frame(sensib),
            all(c("t_barra", "theta", "Z") %in% names(sensib)))

  # Texto claro sobre célula escura, escuro sobre clara: sem isso metade dos
  # rótulos fica ilegível.
  corte <- stats::median(sensib$Z, na.rm = TRUE)

  p <- ggplot2::ggplot(sensib, ggplot2::aes(factor(.data$t_barra),
                                            factor(.data$theta),
                                            fill = .data$Z)) +
    ggplot2::geom_tile(colour = "white", linewidth = 1.2) +   # respiro de 2px entre células
    ggplot2::geom_text(ggplot2::aes(label = scales::label_number(
                         scale_cut = scales::cut_short_scale())(.data$Z),
                       colour = .data$Z > corte),
                       size = 3, show.legend = FALSE) +
    ggplot2::scale_fill_gradient(low = COR_SEQ_BAIXO, high = COR_SEQ_ALTO,
                                 labels = scales::label_number(
                                   scale_cut = scales::cut_short_scale())) +
    ggplot2::scale_colour_manual(values = c("TRUE" = "white", "FALSE" = COR_TINTA)) +
    ggplot2::labs(
      title    = "Sensibilidade aos limiares",
      subtitle = "Z* sobre a grade de raio máximo de acesso e economia mínima exigida",
      x        = "t̄ — acesso e egresso máximos (min)",
      y        = "θ — economia mínima por par (min)",
      fill     = "Z* (pax·min/dia)",
      caption  = "t̄ mede a dependência do first/last mile; θ, a fragilidade da proposta de valor."
    ) +
    tema_b1() +
    ggplot2::theme(legend.position = "right",
                   panel.grid = ggplot2::element_blank())

  salvar(p, arquivo, largura = 16, altura = 11)
}


# ---------------------------------------------------------------------------
#  Mapa da solução
# ---------------------------------------------------------------------------

#' Mapa dos vertiportos abertos sobre as macrozonas.
#'
#' Duas codificações independentes, de propósito: cor separa aberto de não
#' aberto, e tamanho carrega o fluxo atendido. Quem imprimir em preto e branco
#' ainda distingue pelo tamanho e pela forma.
#'
#' As macrozonas entram como fundo neutro em escala de cinza — são contexto,
#' não dado. Pintar o fundo com uma segunda rampa competiria com os pontos,
#' que são o assunto da figura.
plotar_solucao <- function(sol, candidatos, macrozonas,
                           arquivo = "outputs/fig/solucao.png") {
  stopifnot(inherits(candidatos, "sf"), inherits(macrozonas, "sf"),
            !is.null(sol$abertos))

  cand <- candidatos |>
    dplyr::mutate(
      aberto = .data$id %in% sol$abertos,
      fluxo  = if (!is.null(sol$fluxo_por_candidato))
                 sol$fluxo_por_candidato[match(.data$id, names(sol$fluxo_por_candidato))]
               else NA_real_
    )

  p <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = macrozonas, fill = "#F3F4F6",
                     colour = "white", linewidth = 0.25) +
    ggplot2::geom_sf(data = dplyr::filter(cand, !.data$aberto),
                     shape = 1, size = 1.4, colour = COR_SECUNDARIA, stroke = 0.5) +
    ggplot2::geom_sf(data = dplyr::filter(cand, .data$aberto),
                     ggplot2::aes(size = .data$fluxo),
                     shape = 21, fill = COR_BILATERAL, colour = "white", stroke = 0.7) +
    ggplot2::scale_size_area(max_size = 7,
                             labels = scales::label_number(
                               scale_cut = scales::cut_short_scale())) +
    ggplot2::labs(
      title    = "Solução: vertiportos implantados",
      subtitle = paste0(length(sol$abertos), " vertiportos abertos sobre ",
                        nrow(candidatos), " candidatos"),
      size     = "viagens/dia",
      caption  = "Círculo vazio: candidato não selecionado. Área do disco proporcional ao fluxo atendido."
    ) +
    tema_b1() +
    ggplot2::theme(legend.position = "right",
                   axis.text = ggplot2::element_blank(),
                   panel.grid = ggplot2::element_blank())

  salvar(p, arquivo, largura = 16, altura = 14)
}
