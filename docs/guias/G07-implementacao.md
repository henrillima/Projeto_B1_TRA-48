# G07 — Pré-processamento, solver, validação

> Pacote de trabalho de **Henri Leonardo**. Prazo do pacote: **09/09/2026**.
> Leia `docs/guias/G00-como-trabalhar.md`, `CLAUDE.md` e `docs/guias/G06-formulacao.md` antes
> deste. Este guia implementa a formulação daquele; ele não a discute.

---

## Objetivo

Ao fim deste pacote o modelo P1 **roda sobre o dado real de São Paulo**, com o tamanho da
instância **medido e não estimado**, validado contra uma instância-brinquedo resolvida à mão,
acompanhado de um baseline unilateral rodado sobre o mesmo dado — e cada rodada registrada como
`experimento` no grafo, com hipótese e conclusão.

O marco de 09/09 é *"2º encontro: modelo rodando, primeiro resultado"*. "Rodando" aqui tem
significado técnico: `targets::tar_make()` sai limpo do zero, os testes passam, e existe um número
de função objetivo com procedência.

---

## Tarefas no grafo

| Id | Título | Prazo | Est. | Atribuída no grafo a |
| --- | --- | --- | --- | --- |
| `tarefa:T22` | Pré-processar e MEDIR o tamanho real da instância | 05/09 | 6 h | `pessoa:henri` |
| `tarefa:T23` | Implementar o modelo em `ompr` e resolver com HiGHS | 08/09 | 10 h | `pessoa:henri` |
| `tarefa:T24` | Validar o modelo com instância-brinquedo resolvida à mão | 08/09 | 4 h | `pessoa:pedro` |
| `tarefa:T25` | Implementar o baseline CFLP unilateral no mesmo dado | 09/09 | 6 h | `pessoa:antonio` |

Dependências: `T22 DEPENDE_DE T21` e `T13`; `T23 DEPENDE_DE T22`; `T24 DEPENDE_DE T21`;
`T25 DEPENDE_DE T22`. Todas `REALIZA meta:M2`.

**Divergência a resolver antes de começar, não depois.** A tabela do `G00` §2 lista o G07 inteiro
como pacote de **Henri**, mas no grafo `T24` está `ATRIBUIDA_A pessoa:pedro` e `T25` a
`pessoa:antonio`. Duas fontes de verdade divergem, sempre — é a regra 6 do `CLAUDE.md` aplicada a
um caso concreto. Escolham uma e corrijam a outra **no mesmo commit**:

- Manter o grafo como está é a leitura melhor, e por dois motivos substantivos, não burocráticos.
  **T24 é validação**, e validação feita por quem escreveu o modelo tende a testar o que o autor
  já acredita — Pedro validando o modelo de Henri é a coluna `revisao` do kanban funcionando de
  fato. E **T25 é o baseline unilateral**, que consome candidatos e matrizes de tempo, terreno de
  Antônio; além disso é a tarefa que garante que cada integrante apareça como autor de commits em
  Camada A, que é exigência avaliada.
- Se preferirem centralizar em Henri, editem o YAML e **registrem a nota** dizendo por quê.

O que não vale é deixar as duas versões no repositório: a auditoria lê isso como incoerência entre
o que foi dito e o que foi feito.

Note ainda que T24 **não depende de T22 nem de T23**: a instância-brinquedo é sintética e pode ser
escrita hoje. Fazer T24 antes de T23 é a ordem certa — assim o teste existe antes do código que
ele testa, e o primeiro `tar_make()` já diz se o modelo está certo. É a única tarefa deste guia
que pode começar imediatamente.

---

## Pré-requisitos

- [ ] **`tarefa:T21` fechada** — a formulação do G06. Implementar antes de a formulação estar
      escrita significa descobrir a formulação por tentativa e erro dentro do código, que é onde
      ela fica invisível para revisão.
- [ ] **`outputs/matrizes_tempo.rds`** (T13/G05) com as quatro matrizes, **em minutos** e com
      `dimnames` por id — não por posição.
- [ ] **`outputs/od_capturavel.rds`** (T12/G03) com `zona_o`, `zona_d`, `viagens_dia`.
- [ ] **`outputs/candidatos.rds`** (T20/G04) com a coluna `id`.
- [ ] **`renv`** com `dplyr`, `Matrix`, `ompr`, `ompr.roi`, `ROI`, `ROI.plugin.highs`, `highs`,
      `testthat`, `yaml`, `targets`. Rode `renv::snapshot()` e commite o `renv.lock` **antes** de
      escrever a primeira linha de modelo: descobrir na semana 3 que a versão do `highs` mudou é
      o modo mais caro de aprender essa lição.
- [ ] **Confirmar a assinatura do solver na versão travada**:
      `args(highs::highs_solve)` e `ROI::ROI_installed_solvers()`. Os nomes dos argumentos do
      pacote `highs` mudaram entre versões, e este guia diz onde isso importa.

---

## Insumos

| Insumo | Onde | O que dá |
| --- | --- | --- |
| Formulação P1 | `docs/guias/G06-formulacao.md` §1 | o que implementar |
| Proposição sobre $w$ | `docs/guias/G06-formulacao.md` §4 | a função de avaliação exata sem solver |
| Desagregada vs. agregada | `docs/guias/G06-formulacao.md` §5 | as duas variantes a implementar |
| Quatro matrizes de tempo | `outputs/matrizes_tempo.rds` | `t_acesso`, `t_egresso`, `t_voo`, `T_terrestre` |
| Demanda capturável | `outputs/od_capturavel.rds` | `f_q` |
| Candidatos | `outputs/candidatos.rds` | `J` |
| Parâmetros de eVTOL | `docs/guias/G05-tempos.md` | `tau_emb_min`, `tau_des_min`, `v_cruzeiro_kmh` |
| Esquema de `experimento` | `docs/referencia/convencoes.md` §9 | o YAML que a §6 gera |
| Pré-processamento em dois estágios | Wu & Zhang (2021), DOI `10.1016/j.eng.2020.11.007` | o precedente da técnica de T22 |
| Baseline unilateral | Volakakis & Mahmassani (2025), DOI `10.3390/infrastructures10090242` | a‑CFLP / a‑MCLP |

---

## Passo a passo

### 1. T22 — pré-processamento, e MEDIR antes de modelar

O pré-processamento é o coração da tratabilidade. Não é uma etapa de arrumação de dados: é onde
duas das restrições conceituais do problema — acesso não longo demais, economia de tempo real —
deixam de ser linhas do MILP e viram ausência de colunas. Wu & Zhang (2021) gastam 2h34min de
pré-processamento para depois resolver em 245 s. A proporção não é acidente.

#### 1.1 O produto: uma tabela esparsa de colunas

Tudo o que este pacote produz cabe numa tabela. Uma linha por variável $w_{qjk}$ do modelo:

| `col_id` | `q_id` | `zona_o` | `zona_d` | `j` | `k` | `f_q` | `delta` | `coef` |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | Z1 | Z3 | V1 | V2 | 100 | 42 | 4200 |
| … | | | | | | | | |

`coef` $=f_q\cdot\Delta_{qjk}$ é o coeficiente da função objetivo. `col_id` é a posição da coluna
na matriz de restrições. **Toda a formulação sai de agregações sobre esta tabela** — ver §3.

#### 1.2 O código

```r
# app/R/construir_colunas.R
# @produz    outputs/colunas_p1.rds
# @consome   outputs/od_capturavel.rds
# @consome   outputs/matrizes_tempo.rds
# @consome   outputs/candidatos.rds
# @decisao   decisao:[a registrar - valores de t_barra e theta]
# @tarefa    tarefa:T22

#' Converte matriz para tabela longa preservando os dimnames como texto.
#'
#' Existe porque todo o pre-processamento e feito por join sobre ids, nunca por
#' posicao. Indexar por posicao sobrevive a todo teste ate a hora em que a ordem
#' de J muda por um filtro novo - e ai a solucao continua otima para a instancia
#' errada, sem sintoma nenhum.
#'
#' @param m matriz com dimnames nos dois eixos
#' @param nomes vetor de tres nomes de coluna: linha, coluna, valor
#' @return data frame com tres colunas, as duas primeiras de texto
matriz_para_tabela <- function(m, nomes) {
  stopifnot(is.matrix(m), length(nomes) == 3L,
            !is.null(rownames(m)), !is.null(colnames(m)))
  df <- as.data.frame(as.table(m), stringsAsFactors = FALSE)
  names(df) <- nomes
  df
}

#' Constroi a tabela esparsa de colunas w_qjk do modelo P1.
#'
#' Este e o passo que torna o modelo tratavel: a tabela resultante tem
#' sum_q |P_q| linhas, e nao |Q| * |J|^2. Os dois limiares sao PARAMETROS e nao
#' constantes (regra 8 do CLAUDE.md) porque sao os dois eixos principais da
#' analise de sensibilidade da S3 - e porque mudar t_barra nao muda um
#' coeficiente, muda quais colunas existem: cada valor e um modelo novo.
#'
#' @param od_capturavel data frame com zona_o, zona_d, viagens_dia (saida de T12)
#' @param matrizes lista com t_acesso, t_egresso, t_voo, T_terrestre, em minutos
#' @param t_barra_min tempo maximo de acesso e de egresso admitido
#' @param theta_min economia de tempo minima para o par ser servivel
#' @param tau_emb_min processamento no vertiporto de origem
#' @param tau_des_min processamento no vertiporto de destino
#' @param bloco numero de pares OD processados por vez no join
#' @return data frame com col_id, q_id, zona_o, zona_d, j, k, f_q, delta, coef
construir_colunas <- function(od_capturavel,
                              matrizes,
                              t_barra_min  = 15,
                              theta_min    = 10,
                              tau_emb_min  = 5,
                              tau_des_min  = 5,
                              bloco        = 500L) {

  stopifnot(is.data.frame(od_capturavel),
            all(c("zona_o", "zona_d", "viagens_dia") %in% names(od_capturavel)),
            all(c("t_acesso", "t_egresso", "t_voo", "T_terrestre") %in% names(matrizes)),
            t_barra_min > 0, theta_min >= 0,
            tau_emb_min >= 0, tau_des_min >= 0, bloco >= 1L)

  m_ter <- matrizes$T_terrestre   # nome distinto do da coluna, de proposito: ver Armadilhas

  viz_o <- matriz_para_tabela(matrizes$t_acesso,  c("zona", "j", "t_acc"))
  viz_o <- viz_o[viz_o$t_acc <= t_barra_min, , drop = FALSE]

  viz_d <- matriz_para_tabela(matrizes$t_egresso, c("k", "zona", "t_egr"))
  viz_d <- viz_d[viz_d$t_egr <= t_barra_min, , drop = FALSE]

  voo   <- matriz_para_tabela(matrizes$t_voo,     c("j", "k", "t_voo"))

  pares <- od_capturavel[od_capturavel$viagens_dia > 0 &
                           od_capturavel$zona_o != od_capturavel$zona_d, , drop = FALSE]
  pares$q_id  <- seq_len(nrow(pares))
  pares$t_ter <- m_ter[cbind(match(pares$zona_o, rownames(m_ter)),
                             match(pares$zona_d, colnames(m_ter)))]
  stopifnot(all(is.finite(pares$t_ter)))

  blocos <- split(pares, ceiling(pares$q_id / bloco))

  colunas <- dplyr::bind_rows(lapply(blocos, function(g) {
    g |>
      dplyr::inner_join(viz_o, by = c("zona_o" = "zona"),
                        relationship = "many-to-many") |>
      dplyr::inner_join(viz_d, by = c("zona_d" = "zona"),
                        relationship = "many-to-many") |>
      dplyr::filter(.data$j != .data$k) |>
      dplyr::inner_join(voo, by = c("j", "k")) |>
      dplyr::mutate(
        t_uam = .data$t_acc + tau_emb_min + .data$t_voo + tau_des_min + .data$t_egr,
        delta = .data$t_ter - .data$t_uam
      ) |>
      dplyr::filter(.data$delta >= theta_min) |>
      dplyr::select("q_id", "zona_o", "zona_d", "j", "k",
                    f_q = "viagens_dia", "delta")
  }))

  colunas$coef   <- colunas$f_q * colunas$delta
  colunas$col_id <- seq_len(nrow(colunas))

  stopifnot(min(colunas$delta) >= theta_min,
            all(colunas$j != colunas$k),
            !anyDuplicated(colunas$col_id))
  colunas
}
```

Cinco decisões embutidas nesse código, e cada uma merece ser dita em voz alta:

**O bloqueio por `bloco` não é cosmético.** O `inner_join` duplo antes do filtro de `delta` produz
um intermediário de tamanho $|Q|\cdot\overline{|N_o|}\cdot\overline{|N_d|}$ — que pode ser uma
ordem de grandeza maior que o resultado final, porque o filtro de $\theta$ ainda não agiu. É o
ponto do pipeline em que a memória estoura, e o sintoma é o R morrer sem mensagem útil. Processar
em blocos de pares OD mantém o pico controlado e, de quebra, torna a falha diagnosticável: sabe-se
qual bloco quebrou.

**A ordem dos filtros é a ordem da seletividade.** Primeiro `t_barra` sobre acesso e egresso
(reduz $J$ para uma vizinhança pequena por zona), depois `j != k`, só então o join com o voo, e
por último `delta >= theta`. Inverter isso — calcular todos os $\Delta$ e filtrar no fim — produz o
mesmo resultado e pode não caber na memória.

**`col_id` é atribuído uma vez, no fim, e nunca recalculado.** Ele é a ponte entre a tabela e as
colunas da matriz esparsa. Se alguém filtrar a tabela depois e o `col_id` deixar de ser
`1..nrow`, a matriz sai silenciosamente errada. Se precisar filtrar, reconstrua a tabela desde
`construir_colunas()`.

**`t_egresso` entra com o candidato na primeira dimensão.** `matrizes$t_egresso` tem
`dimnames = list(candidatos, zonas)` (G05 §1.5), por isso `c("k", "zona", "t_egr")` nessa ordem.
Trocar produz uma tabela plausível e completamente errada — é a versão em `dplyr` da armadilha do
`lon,lat`.

**Os pares OD sem opção nenhuma somem da tabela.** Um $q$ com $P_q=\emptyset$ não gera linha. Isso
é correto para o modelo (ele não tem nada a decidir ali) e **errado para o relatório**, porque a
cobertura precisa de denominador. Por isso a medição da §1.3 conta os dois.

#### 1.3 O passo obrigatório: medir

```r
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
```

**Imprima e registre estes números antes de escrever a primeira linha do modelo.** As estimativas
do plano são ordem de grandeza declarada como tal. A medição é outra coisa: é um dado com
procedência, entra numa nota da `tarefa:T22`, e é o que sustenta a linha "tamanho da instância" do
indicador comum do §6.3 do enunciado.

Se `soma_Pq` passar de $2\times10^5$, as saídas, em ordem de preferência:

1. **Apertar $\theta$.** É o filtro mais seletivo e o mais defensável — aumentar a economia mínima
   exigida restringe o modelo às viagens em que a proposta de valor é forte, que é a hipótese de
   negócio de qualquer forma.
2. **Apertar $\bar t$.** Reduz a vizinhança de cada zona. Cuidado: enviesa a favor de candidatos
   centrais, porque zonas periféricas ficam sem vizinho.
3. **Agregar mais zonas** (voltar a T11 e reduzir `n_alvo`). É a alternativa de maior alcance —
   $|Q|$ cai com o quadrado — e a de maior custo, porque invalida as matrizes de tempo.
4. **Trocar para a formulação agregada** (G06 §5). Reduz linhas, não colunas, e enfraquece a
   relaxação. Só como último recurso, e nunca sem rodar as duas para comparar.

Qualquer uma delas é uma `decisao` com alternativas descartadas. **"Apertamos o filtro" sem
registro é um número mágico que ninguém consegue defender em setembro.**

---

### 2. T23 — implementar em R

Stack: `ompr` + `ompr.roi` + `ROI.plugin.highs`, com **HiGHS** como solver — MIT, código aberto,
e entrega duais na relaxação, que é o que a disciplina exige.

#### 2.1 Rota A — `ompr`

```r
# app/R/resolver_p1_ompr.R
# @produz    outputs/sol_p1.rds
# @consome   outputs/colunas_p1.rds
# @consome   outputs/candidatos.rds
# @tarefa    tarefa:T23

#' Monta e resolve P1 (MCLP de fluxo bilateral) com ompr sobre HiGHS.
#'
#' As duas restricoes w <= y_j e w <= y_k sao o mecanismo de bilateralidade
#' (G06 §3.1); fundi-las numa so admitiria meia viagem chegando a um vertiporto
#' que nao existe. w e continua por causa da proposicao de G06 §4: dado y
#' inteiro, o otimo em w ja e 0 ou 1, entao declara-la binaria acrescentaria
#' 1e5 variaveis inteiras sem admitir uma unica solucao nova.
#'
#' @param colunas saida de construir_colunas()
#' @param candidatos data frame com a coluna id
#' @param p cardinalidade maxima de vertiportos
#' @param relaxado TRUE resolve a relaxacao linear (y continuo em [0,1])
#' @param agregada TRUE usa a vinculacao agregada de G06 §5, para comparacao
#' @return objeto de modelo do ompr, pronto para solve_model()
montar_p1_ompr <- function(colunas, candidatos, p,
                           relaxado = FALSE, agregada = FALSE) {

  stopifnot(is.data.frame(colunas), nrow(colunas) > 0L,
            "id" %in% names(candidatos), p >= 1)

  idx <- stats::setNames(seq_len(nrow(candidatos)), candidatos$id)
  stopifnot(all(colunas$j %in% names(idx)), all(colunas$k %in% names(idx)))

  cj    <- unname(idx[colunas$j])
  ck    <- unname(idx[colunas$k])
  coef  <- colunas$coef
  nC    <- nrow(colunas)
  nJ    <- nrow(candidatos)

  # a lista de colunas de cada par OD, pre-computada: ver Armadilhas
  idx_q <- unname(split(seq_len(nC), factor(colunas$q_id)))
  nQ    <- length(idx_q)

  # e, para a variante agregada, as colunas em que cada candidato aparece
  idx_j <- unname(split(seq_len(nC), factor(cj, levels = seq_len(nJ))))
  idx_k <- unname(split(seq_len(nC), factor(ck, levels = seq_len(nJ))))

  tipo_y <- if (relaxado) "continuous" else "binary"

  m <- ompr::MIPModel() |>
    ompr::add_variable(y[j], j = 1:nJ, type = tipo_y, lb = 0, ub = 1) |>
    ompr::add_variable(w[c], c = 1:nC, type = "continuous", lb = 0, ub = 1) |>
    ompr::set_objective(ompr::sum_over(coef[c] * w[c], c = 1:nC), "max") |>
    ompr::add_constraint(ompr::sum_over(w[c], c = idx_q[[q]]) <= 1, q = 1:nQ) |>
    ompr::add_constraint(ompr::sum_over(y[j], j = 1:nJ) <= p)

  if (agregada) {
    m <- m |>
      ompr::add_constraint(
        ompr::sum_over(w[c], c = idx_j[[j]]) <= nQ * y[j],
        j = 1:nJ, .show_progress_bar = FALSE) |>
      ompr::add_constraint(
        ompr::sum_over(w[c], c = idx_k[[k]]) <= nQ * y[k],
        k = 1:nJ, .show_progress_bar = FALSE)
  } else {
    m <- m |>
      ompr::add_constraint(w[c] - y[cj[c]] <= 0, c = 1:nC, .show_progress_bar = FALSE) |>
      ompr::add_constraint(w[c] - y[ck[c]] <= 0, c = 1:nC, .show_progress_bar = FALSE)
  }
  m
}
```

Resolver:

```r
sol <- ompr::solve_model(
  montar_p1_ompr(colunas, candidatos, p = 12),
  ompr.roi::with_ROI(solver = "highs", verbose = TRUE)
)

ompr::objective_value(sol)
abertos <- ompr::get_solution(sol, y[j])          # data frame com j e value
rota    <- ompr::get_solution(sol, w[c])
```

Três notas de versão, e é melhor conferi-las na versão travada no `renv` do que descobrir na
véspera:

- `sum_over()` é o nome atual; versões antigas do `ompr` expõem `sum_expr()`. Se a sua travada for
  antiga, troque — o comportamento é o mesmo.
- `add_variable(y[j], type = tipo_y)` com `tipo_y` vindo de uma variável do R funciona porque o
  `ompr` avalia o argumento normalmente; o que ele trata como expressão simbólica é só o índice.
- `y[cj[c]]` também funciona: `cj[c]` é avaliado com `c` ligado ao quantificador e devolve um
  inteiro, que é um índice válido. Se a sua versão reclamar, a saída é a Rota B — e a Rota B é
  para onde a instância real provavelmente vai de qualquer forma.

#### 2.2 ALERTA CRÍTICO — o `ompr` não escala

`ompr` constrói o modelo em **R puro**, expandindo restrição por restrição, e fica muito lento
acima de ~$10^5$ variáveis. Na instância real deste projeto, o número de colunas $w$ é exatamente
dessa ordem — a estimativa do plano é $4\times10^4$ a $2\times10^5$, e por isso o número medido em
T22 decide qual rota usar.

O sintoma não é um erro: é o `add_constraint` levando minutos e a memória subindo. E o pior modo
de falha é o mais provável: funciona no protótipo com 10 candidatos, funciona no
teste-brinquedo, e trava na véspera do encontro, na instância completa.

**Regra prática:** se `medir_instancia()$soma_Pq` passar de $5\times10^4$, vá direto para a Rota B.
O custo de escrever a Rota B é uma tarde; o custo de descobrir que precisava dela é uma semana.

Mantenha as duas. A Rota A é legível e é a que se mostra no relatório e na arguição; a Rota B é a
que roda. Mantê-las coerentes é o que o teste de equivalência da §4.4 garante.

#### 2.3 Rota B — matriz esparsa e `highs_solve()` direto

O modelo tem duas famílias de colunas e quatro blocos de linhas. Fixe o **leiaute** e escreva-o
num comentário, porque tudo depois depende dele:

```
colunas:  [ 1 .. nC ]            = w, na ordem de col_id da tabela
          [ nC+1 .. nC+nJ ]      = y, na ordem de candidatos$id

linhas:   [ 1 .. nQ ]                          sum_{P_q} w <= 1
          [ nQ+1 .. nQ+nC ]                    w - y_j <= 0
          [ nQ+nC+1 .. nQ+2nC ]                w - y_k <= 0
          [ nQ+2nC+1 ]                         sum_j y <= p
```

```r
# app/R/montar_matriz_p1.R
# @produz    (objeto de modelo, sem alvo proprio)
# @consome   outputs/colunas_p1.rds
# @tarefa    tarefa:T23

#' Monta P1 como matriz esparsa, no formato que highs::highs_solve() consome.
#'
#' Existe porque o ompr constroi o modelo em R puro e fica muito lento acima de
#' ~1e5 variaveis, que e a ordem de grandeza desta instancia. Toda a matriz sai
#' de vetores construidos de uma vez sobre a tabela de colunas: nao ha loop
#' sobre q, j ou k em lugar nenhum, e e por isso que a montagem leva segundos.
#'
#' @param colunas saida de construir_colunas(), com col_id em 1..nrow
#' @param candidatos data frame com a coluna id
#' @param p cardinalidade maxima
#' @param relaxado TRUE devolve y continuo, para a relaxacao linear e os duais
#' @return lista com A, lhs, rhs, lower, upper, types, objective, offset, maximum
montar_matriz_p1 <- function(colunas, candidatos, p, relaxado = FALSE) {

  stopifnot(identical(colunas$col_id, seq_len(nrow(colunas))))

  idx <- stats::setNames(seq_len(nrow(candidatos)), candidatos$id)
  cj  <- unname(idx[colunas$j])
  ck  <- unname(idx[colunas$k])
  nC  <- nrow(colunas)
  nJ  <- nrow(candidatos)

  q_lin <- as.integer(factor(colunas$q_id))    # linha do bloco 1 de cada coluna
  nQ    <- max(q_lin)
  n_lin <- nQ + 2L * nC + 1L

  lin <- c(q_lin,                                 # bloco 1: w
           nQ + seq_len(nC),                      # bloco 2: +w
           nQ + seq_len(nC),                      # bloco 2: -y_j
           nQ + nC + seq_len(nC),                 # bloco 3: +w
           nQ + nC + seq_len(nC),                 # bloco 3: -y_k
           rep.int(n_lin, nJ))                    # bloco 4: y

  col <- c(seq_len(nC),
           seq_len(nC), nC + cj,
           seq_len(nC), nC + ck,
           nC + seq_len(nJ))

  val <- c(rep.int( 1, nC),
           rep.int( 1, nC), rep.int(-1, nC),
           rep.int( 1, nC), rep.int(-1, nC),
           rep.int( 1, nJ))

  A <- Matrix::sparseMatrix(i = lin, j = col, x = val,
                            dims = c(n_lin, nC + nJ))

  list(
    A         = A,
    lhs       = rep.int(-Inf, n_lin),
    rhs       = c(rep.int(1, nQ), rep.int(0, 2L * nC), p),
    lower     = rep.int(0, nC + nJ),
    upper     = rep.int(1, nC + nJ),
    types     = c(rep.int("C", nC),
                  rep.int(if (relaxado) "C" else "I", nJ)),
    objective = c(colunas$coef, rep.int(0, nJ)),
    offset    = 0,
    maximum   = TRUE
  )
}

#' Resolve o modelo montado por montar_matriz_p1() com HiGHS.
#'
#' @param mp lista devolvida por montar_matriz_p1()
#' @param control lista de opcoes do HiGHS
#' @return o objeto de solucao do pacote highs
resolver_highs <- function(mp, control = list(time_limit = 600, mip_rel_gap = 0)) {
  highs::highs_solve(L       = mp$objective,
                     lower   = mp$lower,
                     upper   = mp$upper,
                     A       = mp$A,
                     lhs     = mp$lhs,
                     rhs     = mp$rhs,
                     types   = mp$types,
                     maximum = mp$maximum,
                     offset  = mp$offset,
                     control = control)
}
```

Quatro pontos sobre a Rota B:

**`y` inteiro com cotas $[0,1]$ é binário.** Não existe tipo "binário" separado; é `"I"` com
`lower = 0`, `upper = 1`.

**Confira a assinatura antes de rodar.** O nome do argumento do vetor de custos e a codificação de
`types` (caractere `"C"`/`"I"` ou inteiro) variaram entre versões do pacote `highs`. Rode
`args(highs::highs_solve)` e `?highs_solve` na versão travada no `renv` e ajuste **uma vez**. Isso
não é ressalva de estilo: passar `types` na codificação errada pode ser aceito silenciosamente e
resolver o LP em vez do MILP — resultado plausível, fracionário e errado.

**Duais só saem do LP.** Para T31, resolva com `relaxado = TRUE` e leia os duais das linhas. O
dual de interesse principal é o da **última linha** (`n_lin`), que é $\pi$. Confira o sinal contra
o caso conhecido — $\pi\ge 0$, porque mais vertiportos nunca pioram — e registre a convenção. Se
a extração de duais na sua versão do `highs` não for direta, o caminho alternativo é resolver a
relaxação pela Rota A e usar `ROI::solution(sol, "dual")`, que é o que a revisão de literatura
recomenda.

**Guarde `nQ`, `nC`, `nJ` junto com o modelo.** Sem eles não se sabe qual linha é qual dual. Um
campo `mp$blocos <- list(nQ = nQ, nC = nC, nJ = nJ)` custa nada e evita contagem de dedo em
setembro.

#### 2.4 Como indexar $w_{qjk}$ de forma vetorizada

A regra é uma só: **um data frame de índices com uma coluna `col_id`, e o modelo montado por
`join` e por agregação, nunca por loop.**

O padrão que se repete em todo o pacote:

```r
# o vetor de linha de cada coluna, para um bloco de restricoes agrupado por X:
linha <- as.integer(factor(colunas$X))

# a soma de uma quantidade por par OD (usada na FO, na cobertura, no baseline):
por_q <- tapply(colunas$coef, colunas$q_id, max)

# o fluxo que passa por um candidato (usado na extensao de capacidade):
carga <- tapply(colunas$f_q, colunas$j, sum)
```

`as.integer(factor(x))` é o idioma central: ele converte um identificador arbitrário — id de par
OD, id de candidato — no índice consecutivo de linha ou coluna que a matriz esparsa exige, de uma
vez, sem loop e sem `which()`. Use sempre `levels = ` explícito quando os níveis possíveis forem
conhecidos (como em `factor(cj, levels = seq_len(nJ))`), senão um candidato que não aparece em
coluna nenhuma some da numeração e desloca todos os outros.

---

### 3. A armadilha da indexação

Este é o insight de implementação que economiza dias, e ele é anterior a qualquer linha de código.

A variável é $w_{qjk}$: **três índices**. O reflexo é declarar um array `w[nQ, nJ, nJ]` e trabalhar
com ele. Isso é impossível aqui, por dois motivos:

**O array é denso e a estrutura é esparsa.** Com $|Q|\approx 3.000$ e $|J|=50$, o array 3D teria
$3.000\times50\times50=7{,}5$ milhões de posições para representar algo entre $4\times10^4$ e
$2\times10^5$ colunas reais. É de 40 a 200 vezes mais memória para guardar quase só zeros.

**E, o que é decisivo: $P_q$ é irregular.** Nem todo par $(j,k)$ existe para todo $q$ — essa é a
definição de $P_q$. Num array 3D, "não existe" e "existe com valor zero" ocupam a mesma célula e
são indistinguíveis. O modelo passaria a ter colunas que não deveriam existir, com $\Delta$
indefinido; qualquer valor que se pusesse ali (zero, `NA`, um número negativo) produziria um
comportamento errado diferente.

**A estrutura certa é a tabela esparsa** `(q_id, j, k, col_id, delta)` da §1.1. Tudo o mais é
agregação sobre ela:

| Elemento do modelo | Como sai da tabela |
| --- | --- |
| Função objetivo | o vetor `colunas$coef`, na ordem de `col_id` |
| Restrição (1), por par | agrupar `col_id` por `q_id` |
| Restrição (2), origem | uma linha por `col_id`, com $-1$ na coluna `nC + idx[j]` |
| Restrição (3), destino | idem, com `idx[k]` |
| Restrição (4), cardinalidade | uma linha, todas as colunas `y` |
| Carga do vertiporto $j$ (ext. 9.1) | `tapply(f_q, j, sum)` mais `tapply(f_q, k, sum)` |
| Avaliação de um conjunto aberto | `max` por `q_id` sobre as linhas com `j` e `k` abertos |
| Cobertura em viagens/dia | soma de `f_q` sobre os `q_id` servidos |

Uma consequência que só aparece depois e vale antecipar: como a tabela carrega `zona_o`, `zona_d`,
`j` e `k` **como identificadores de texto**, todo mapa, toda tabela de resultado e toda
verificação saem dela por `join`, sem passar por posição. É o mesmo princípio dos `dimnames` das
matrizes de tempo (G05 §6), aplicado às colunas do modelo.

---

### 4. T24 — validar com instância-brinquedo

#### 4.1 Por que isto não é opcional

Um modelo que roda mas está errado é pior que um modelo que não roda. Num modelo de otimização o
resultado errado é **plausível**: sai um número, saem coordenadas, sai um mapa bonito, e nada no
resultado denuncia que a restrição de bilateralidade foi montada com o índice trocado. O erro só
apareceria na arguição, se aparecer.

E há um agravante específico deste modelo: as restrições (2) e (3) são simétricas na aparência e
diferentes no efeito. Trocar `ck` por `cj` numa delas produz um modelo que exige **duas vezes o
vertiporto de origem** e nunca o de destino — isto é, um modelo unilateral disfarçado. Ele resolve
mais rápido, dá cobertura maior, e a curva de implantação sai côncava desde $p=1$. O grupo
concluiria que a previsão da curva em S falhou. Esse cenário é inteiramente realista, e é
exatamente o que o teste-brinquedo pega em dois segundos.

#### 4.2 A instância-brinquedo A — 5 zonas, 3 candidatos

**Todos os números abaixo são sintéticos**, escolhidos à mão para que o ótimo seja verificável sem
solver. Não são dado de São Paulo e não devem ser citados como tal em lugar nenhum.

Parâmetros: $\tau_{\text{emb}}=\tau_{\text{des}}=5$ min, $\bar t=15$ min, $\theta=10$ min.

**Tempos de acesso** `t_acesso[zona, candidato]`, em minutos — e, deliberadamente,
`t_egresso = t(t_acesso)`, para que a conferência à mão seja possível (no modelo real as duas
matrizes são calculadas separadamente, G05 §0):

| | V1 | V2 | V3 |
| --- | --- | --- | --- |
| **Z1** | **5** | 40 | 45 |
| **Z2** | **10** | 38 | 50 |
| **Z3** | 42 | **6** | 40 |
| **Z4** | 45 | **12** | **13** |
| **Z5** | 30 | 30 | **8** |

Em negrito, os valores $\le\bar t=15$. Vizinhanças resultantes:
$N_{Z1}=\{V1\}$, $N_{Z2}=\{V1\}$, $N_{Z3}=\{V2\}$, $N_{Z4}=\{V2,V3\}$, $N_{Z5}=\{V3\}$.

**Tempos de voo** `t_voo`, em minutos: $V1\!-\!V2=12$, $V1\!-\!V3=15$, $V2\!-\!V3=10$, diagonal 0.

**Pares OD elegíveis** $Q$ (dirigidos), com fluxo e tempo terrestre:

| $q$ | par | $f_q$ [viagens/dia] | $T^{\text{ter}}_q$ [min] |
| --- | --- | --- | --- |
| q1 | Z1 → Z3 | 100 | 75 |
| q2 | Z1 → Z4 | 60 | 80 |
| q3 | Z2 → Z3 | 40 | 70 |
| q4 | Z3 → Z5 | 30 | 55 |
| q5 | Z1 → Z5 | 20 | 45 |

**As colunas, uma a uma.** $T^{\text{uam}}=t^{\text{acc}}+5+t^{\text{voo}}+5+t^{\text{egr}}$ e
$\Delta=T^{\text{ter}}-T^{\text{uam}}$:

| $q$ | $(j,k)$ | conta de $T^{\text{uam}}$ | $T^{\text{uam}}$ | $\Delta$ | entra? | $\text{coef}=f_q\Delta$ |
| --- | --- | --- | --- | --- | --- | --- |
| q1 | (V1,V2) | 5+5+12+5+6 | 33 | **42** | sim | **4200** |
| q2 | (V1,V2) | 5+5+12+5+12 | 39 | **41** | sim | **2460** |
| q2 | (V1,V3) | 5+5+15+5+13 | 43 | **37** | sim | **2220** |
| q3 | (V1,V2) | 10+5+12+5+6 | 38 | **32** | sim | **1280** |
| q4 | (V2,V3) | 6+5+10+5+8 | 34 | **21** | sim | **630** |
| q5 | (V1,V3) | 5+5+15+5+8 | 38 | 7 | **não** — $7<\theta$ | — |

Portanto: $|Q|=5$, mas $|Q_{\text{com opção}}|=4$; $\sum_q|P_q|=5$ colunas $w$; 3 binárias.
$P_{q5}=\emptyset$ — o par é elegível pela demanda e **não é servível por rota nenhuma**. Ele tem
de aparecer no denominador da cobertura e não pode aparecer na tabela de colunas. É um caso de
teste por si só.

#### 4.3 O ótimo, resolvido à mão

Pela Proposição de G06 §4, o valor de um conjunto aberto $S$ é a soma, sobre os pares, do melhor
`coef` disponível:

| $S$ | q1 | q2 | q3 | q4 | $Z(S)$ |
| --- | --- | --- | --- | --- | --- |
| $\{V1\}$, $\{V2\}$, $\{V3\}$ | — | — | — | — | **0** |
| $\{V1,V2\}$ | 4200 | 2460 | 1280 | — | **7940** |
| $\{V1,V3\}$ | — | 2220 | — | — | 2220 |
| $\{V2,V3\}$ | — | — | — | 630 | 630 |
| $\{V1,V2,V3\}$ | 4200 | 2460 | 1280 | 630 | **8570** |

$$
Z^*(1)=0,\qquad Z^*(2)=7940,\qquad Z^*(3)=8570
$$

Duas coisas para notar, e as duas são o teste:

**$Z^*(1)=0$ testa a bilateralidade diretamente.** Se o modelo devolver qualquer coisa diferente de
zero com $p=1$, uma das restrições (2)/(3) está errada. É o teste mais barato e mais informativo
do pacote inteiro.

**As primeiras diferenças são $0$, $7940$, $630$.** Crescente e depois decrescente: a
instância-brinquedo **exibe a curva em S em miniatura**. Ela não prova nada sobre São Paulo, mas
prova que o modelo é capaz de produzir o formato — o que já elimina a hipótese de um S ausente ser
bug de implementação.

#### 4.4 A instância-brinquedo B — o gap de integralidade

Três candidatos $A,B,C$; três pares OD, cada um com $P_q$ de um único elemento e
$f_q\Delta_q=1$: $q_1\!\to\!(A,B)$, $q_2\!\to\!(B,C)$, $q_3\!\to\!(C,A)$. Com $p=1$:

- **Inteiro:** qualquer vertiporto único fecha um dos lados de todos os pares. $Z_{IP}=0$.
- **Relaxação:** $y_A=y_B=y_C=\tfrac13$ satisfaz $\sum y\le 1$, e $w_{q}=\tfrac13$ para cada par
  satisfaz as duas vinculações. $Z_{LP}=1$.

E $Z_{LP}=1$ é o ótimo exato da relaxação: somando as seis desigualdades de vinculação,
$2\sum_q w_q\le 2\sum_j y_j\le 2$.

Um *gap* de integralidade **infinito** numa instância de três variáveis binárias. É a demonstração
mínima de que a bilateralidade quebra a quase-integralidade do MCLP (G06 §5), ela roda em
milissegundos, e é material direto do `tarefa:T30`.

#### 4.5 Como teste automatizado, com `testthat`

```r
# tests/testthat/helper-brinquedo.R
# @tarefa    tarefa:T24

#' Instancia-brinquedo A: 5 zonas, 3 candidatos, otimo conhecido.
#'
#' Numeros sinteticos, escolhidos a mao. Nao sao dado de Sao Paulo.
#' t_egresso e a transposta do acesso de proposito: no modelo real as duas
#' matrizes sao calculadas separadamente (G05 §0), mas aqui a simetria e o que
#' torna o otimo conferivel a mao.
brinquedo_a <- function() {
  zonas <- c("Z1", "Z2", "Z3", "Z4", "Z5")
  cand  <- c("V1", "V2", "V3")

  t_acesso <- matrix(c( 5, 40, 45,
                       10, 38, 50,
                       42,  6, 40,
                       45, 12, 13,
                       30, 30,  8),
                     nrow = 5, byrow = TRUE, dimnames = list(zonas, cand))

  t_voo <- matrix(c( 0, 12, 15,
                    12,  0, 10,
                    15, 10,  0),
                  nrow = 3, byrow = TRUE, dimnames = list(cand, cand))

  T_ter <- matrix(0, nrow = 5, ncol = 5, dimnames = list(zonas, zonas))
  T_ter["Z1", "Z3"] <- 75; T_ter["Z1", "Z4"] <- 80; T_ter["Z2", "Z3"] <- 70
  T_ter["Z3", "Z5"] <- 55; T_ter["Z1", "Z5"] <- 45

  list(
    od = data.frame(
      zona_o      = c("Z1", "Z1", "Z2", "Z3", "Z1"),
      zona_d      = c("Z3", "Z4", "Z3", "Z5", "Z5"),
      viagens_dia = c(100,   60,   40,   30,   20),
      stringsAsFactors = FALSE
    ),
    matrizes = list(t_acesso    = t_acesso,
                    t_egresso   = t(t_acesso),
                    t_voo       = t_voo,
                    T_terrestre = T_ter),
    candidatos = data.frame(id = cand, stringsAsFactors = FALSE)
  )
}

#' Instancia-brinquedo B: ciclo de tres candidatos, gap de integralidade infinito.
brinquedo_b <- function() {
  data.frame(
    col_id = 1:3,
    q_id   = 1:3,
    zona_o = c("Za", "Zb", "Zc"),
    zona_d = c("Zb", "Zc", "Za"),
    j      = c("A", "B", "C"),
    k      = c("B", "C", "A"),
    f_q    = c(1, 1, 1),
    delta  = c(1, 1, 1),
    coef   = c(1, 1, 1),
    stringsAsFactors = FALSE
  )
}
```

```r
# tests/testthat/test-p1.R
# @tarefa    tarefa:T24

b <- brinquedo_a()
colunas <- construir_colunas(b$od, b$matrizes,
                             t_barra_min = 15, theta_min = 10,
                             tau_emb_min = 5, tau_des_min = 5)

test_that("o pre-processamento produz exatamente as colunas esperadas", {
  expect_equal(nrow(colunas), 5L)
  expect_setequal(colunas$q_id, 1:4)             # q5 nao gera coluna: P_q vazio
  expect_true(all(colunas$j != colunas$k))
  expect_gte(min(colunas$delta), 10)
})

test_that("os coeficientes conferem com a conta feita a mao", {
  chave <- paste(colunas$q_id, colunas$j, colunas$k, sep = "|")
  esperado <- c("1|V1|V2" = 4200, "2|V1|V2" = 2460, "2|V1|V3" = 2220,
                "3|V1|V2" = 1280, "4|V2|V3" =  630)
  expect_equal(stats::setNames(colunas$coef, chave)[names(esperado)], esperado)
})

test_that("a avaliacao direta reproduz a tabela resolvida a mao", {
  expect_equal(avaliar_solucao(colunas, c("V1")),             0)
  expect_equal(avaliar_solucao(colunas, c("V1", "V2")),    7940)
  expect_equal(avaliar_solucao(colunas, c("V1", "V3")),    2220)
  expect_equal(avaliar_solucao(colunas, c("V2", "V3")),     630)
  expect_equal(avaliar_solucao(colunas, c("V1","V2","V3")),8570)
})

test_that("com p = 1 o otimo e ZERO - este teste e a bilateralidade", {
  mp  <- montar_matriz_p1(colunas, b$candidatos, p = 1)
  sol <- resolver_highs(mp)
  expect_equal(valor_objetivo(sol), 0, tolerance = 1e-6)
})

test_that("com p = 2 o otimo e 7940, em {V1, V2}", {
  mp  <- montar_matriz_p1(colunas, b$candidatos, p = 2)
  sol <- resolver_highs(mp)
  expect_equal(valor_objetivo(sol), 7940, tolerance = 1e-6)
  expect_setequal(vertiportos_abertos(sol, colunas, b$candidatos), c("V1", "V2"))
})

test_that("com p = 3 o otimo e 8570 e a curva comeca convexa", {
  z <- vapply(1:3, function(p) {
    valor_objetivo(resolver_highs(montar_matriz_p1(colunas, b$candidatos, p = p)))
  }, numeric(1))
  expect_equal(z, c(0, 7940, 8570), tolerance = 1e-6)
  expect_gt(z[2] - z[1], z[1])          # primeira diferenca cresce: convexa no inicio
  expect_lt(z[3] - z[2], z[2] - z[1])   # e decresce depois: concava no fim
})

test_that("as duas rotas de implementacao dao o mesmo otimo", {
  z_b <- valor_objetivo(resolver_highs(montar_matriz_p1(colunas, b$candidatos, p = 2)))
  z_a <- ompr::objective_value(ompr::solve_model(
    montar_p1_ompr(colunas, b$candidatos, p = 2),
    ompr.roi::with_ROI(solver = "highs")))
  expect_equal(z_a, z_b, tolerance = 1e-6)
})

test_that("a bilateralidade quebra a quase-integralidade do MCLP", {
  cb   <- brinquedo_b()
  cand <- data.frame(id = c("A", "B", "C"), stringsAsFactors = FALSE)
  z_ip <- valor_objetivo(resolver_highs(montar_matriz_p1(cb, cand, p = 1)))
  z_lp <- valor_objetivo(resolver_highs(montar_matriz_p1(cb, cand, p = 1, relaxado = TRUE)))
  expect_equal(z_ip, 0, tolerance = 1e-6)
  expect_equal(z_lp, 1, tolerance = 1e-6)
})
```

`valor_objetivo()` e `vertiportos_abertos()` são dois adaptadores de três linhas sobre o objeto de
solução do `highs`; escreva-os assim que confirmar os nomes dos campos com `str(sol)`, e
concentre neles **toda** a dependência de versão do pacote. É a mesma disciplina do §2.3: a
fronteira com a biblioteca externa fica num lugar só.

A função de avaliação, que é a Proposição de G06 §4 em código, e é o que torna o teste
independente do solver:

```r
# app/R/avaliar_solucao.R
# @tarefa    tarefa:T24

#' Valor otimo de P1 dado um conjunto de vertiportos abertos, sem chamar solver.
#'
#' E a proposicao de G06 §4 em codigo: com y fixo, o subproblema em w separa-se
#' por par OD e o otimo e o melhor coeficiente disponivel. Serve para tres
#' coisas: conferir a instancia-brinquedo, avaliar a solucao do baseline
#' unilateral com a regua bilateral (T25), e dar cota inferior inicial ao B&B.
#'
#' @param colunas saida de construir_colunas()
#' @param abertos vetor de ids de candidatos abertos
#' @return valor da funcao objetivo, em pax*min/dia
avaliar_solucao <- function(colunas, abertos) {
  stopifnot(is.data.frame(colunas), is.character(abertos) || is.factor(abertos))
  sel <- colunas[colunas$j %in% abertos & colunas$k %in% abertos, , drop = FALSE]
  if (nrow(sel) == 0L) return(0)
  sum(tapply(sel$coef, sel$q_id, max))
}
```

---

### 5. T25 — o baseline CFLP unilateral

#### 5.1 O que é, e por que serve para duas coisas

Uma réplica adaptada de Volakakis & Mahmassani (2025) — a‑CFLP e a‑MCLP capacitado — na versão
**unilateral**: alocação zona → vertiporto, sem par OD, sem os dois lados. É a família que a
literatura aplicada de vertiportos efetivamente usa, e é por isso que ela é o baseline certo:
comparar contra ela é comparar contra o estado da prática, não contra um espantalho.

Serve para duas coisas, e é importante que as duas apareçam:

1. **Comparar as soluções** — quais vertiportos cada modelo escolhe, e por quê. A hipótese, a
   registrar antes de rodar: o unilateral escolhe onde há **origem** de demanda (dispersa, seguindo
   população) e o bilateral escolhe onde há **par** de demanda (concentrado, seguindo corredores).
   Se isso se confirmar, é uma figura de mapa com dois conjuntos de pontos e é autoexplicativa.
2. **Produzir a segunda curva de implantação**, que sobreposta à bilateral é a **figura central do
   trabalho**: uma côncava desde $p=1$, outra em S partindo de zero.

#### 5.2 A formulação

O baseline implementável é o **a‑MCLP unilateral**, com o mesmo eixo $p$ do P1 — o que torna as
duas curvas diretamente sobreponíveis. Com $h_i=\sum_{d:(i,d)\in Q}f_{(i,d)}$ as viagens
originadas na zona $i$ dentro do mesmo $Q$, e $N_i=\{j\in J: t^{\text{acc}}_{ij}\le\bar t\}$ a
mesma vizinhança do P1:

$$
\begin{aligned}
\max\quad & Z^{\text{uni}}=\sum_{i\in I} h_i\,z_i && \text{[viagens/dia]}\\
\text{s.a.}\quad & z_i\ \le\ \sum_{j\in N_i} y_j && \forall i\in I && (\alpha^{\text{uni}}_i)\\
& \sum_{j\in J} y_j\ \le\ p && && (\pi^{\text{uni}})\\
& z_i\in[0,1],\quad y_j\in\{0,1\}
\end{aligned}
$$

A versão a‑CFLP, com custo fixo e capacidade, para o relatório e para a comparação de famílias:

$$
\begin{aligned}
\min\quad & \sum_{j\in J} f^{\text{fix}}_j\,y_j\ +\ \sum_{i\in I}\sum_{j\in N_i} h_i\,
t^{\text{acc}}_{ij}\,x_{ij}\\
\text{s.a.}\quad & \sum_{j\in N_i} x_{ij}=1\ \ \forall i;\qquad x_{ij}\le y_j;\qquad
\sum_{i} h_i x_{ij}\le C_j y_j\ \ (\gamma_j);\qquad \sum_j f^{\text{fix}}_j y_j\le B\ \ (\beta)
\end{aligned}
$$

**Implemente a a‑MCLP, não a a‑CFLP.** A a‑CFLP exige $f^{\text{fix}}_j$ e $C_j$, os dois
`[A CONFIRMAR]` na tabela de parâmetros do G06 §2. Um baseline construído sobre dois parâmetros sem
fonte não é um baseline — é uma segunda fonte de erro. A a‑CFLP fica no relatório como formulação
de referência, com a nota de por que não foi instanciada.

#### 5.3 O problema da unidade, e a solução

$Z$ está em **pax·min/dia**; $Z^{\text{uni}}$ está em **viagens/dia**. Sobrepor as duas curvas num
gráfico com um eixo $y$ só é errado, e num relatório de PO é o tipo de erro que apaga o resultado.
Três saídas, e as três valem a pena:

1. **Normalizar cada curva pelo próprio máximo** — $Z^*(p)/Z^*(|J|)$. Compara **formato**, que é o
   que interessa: côncava desde o início contra S. É a figura central.
2. **Avaliar a solução unilateral com a régua bilateral.** Pegue o conjunto $S_{\text{uni}}(p)$
   escolhido pelo modelo unilateral e calcule `avaliar_solucao(colunas, S_uni(p))`. Isso dá um
   valor em pax·min/dia diretamente comparável com $Z^*(p)$, e a diferença é **o custo de ter
   modelado a cobertura como unilateral** — em unidade de benefício, para a mesma verba. É a
   comparação mais forte que este trabalho pode fazer, e custa uma chamada de função.
3. **Reportar os dois indicadores para as duas soluções**: pax·min/dia e viagens/dia. O §6.3 do
   enunciado pede os dois de qualquer forma.

```r
# app/R/resolver_mclp_unilateral.R
# @produz    outputs/sol_baseline.rds
# @consome   outputs/od_capturavel.rds
# @consome   outputs/matrizes_tempo.rds
# @tarefa    tarefa:T25

#' Resolve o a-MCLP unilateral (baseline) sobre EXATAMENTE o mesmo dado do P1.
#'
#' A la Volakakis & Mahmassani (2025). E o estado da pratica da literatura
#' aplicada de vertiportos, e serve para duas coisas: comparar quais sitios cada
#' modelo escolhe, e produzir a segunda curva de implantacao. Usa o mesmo Q e o
#' mesmo t_barra do P1 de proposito - se os dados divergirem, a comparacao
#' mede a diferenca de dado e nao a diferenca de formulacao.
#'
#' @param od_capturavel data frame com zona_o, zona_d, viagens_dia
#' @param t_acesso matriz zonas x candidatos, em minutos, com dimnames
#' @param candidatos data frame com a coluna id
#' @param p cardinalidade maxima
#' @param t_barra_min mesmo limiar usado em construir_colunas()
#' @return lista com obj (viagens/dia) e abertos (vetor de ids)
resolver_mclp_unilateral <- function(od_capturavel, t_acesso, candidatos,
                                     p, t_barra_min = 15) {
  stopifnot(is.matrix(t_acesso), !is.null(rownames(t_acesso)), p >= 1)

  h <- tapply(od_capturavel$viagens_dia, od_capturavel$zona_o, sum)
  h <- h[names(h) %in% rownames(t_acesso)]
  zonas <- names(h)

  cobre <- t_acesso[zonas, candidatos$id, drop = FALSE] <= t_barra_min
  nI <- length(zonas); nJ <- nrow(candidatos)

  m <- ompr::MIPModel() |>
    ompr::add_variable(y[j], j = 1:nJ, type = "binary") |>
    ompr::add_variable(z[i], i = 1:nI, type = "continuous", lb = 0, ub = 1) |>
    ompr::set_objective(ompr::sum_over(as.numeric(h)[i] * z[i], i = 1:nI), "max") |>
    ompr::add_constraint(
      z[i] - ompr::sum_over(y[j], j = 1:nJ, cobre[i, j]) <= 0, i = 1:nI) |>
    ompr::add_constraint(ompr::sum_over(y[j], j = 1:nJ) <= p)

  sol <- ompr::solve_model(m, ompr.roi::with_ROI(solver = "highs"))
  ys  <- ompr::get_solution(sol, y[j])

  list(obj     = ompr::objective_value(sol),
       abertos = candidatos$id[ys$j[ys$value > 0.5]])
}
```

O baseline é pequeno — $|I|$ variáveis contínuas e $|J|$ binárias, na casa das centenas — e por
isso a Rota A do `ompr` basta aqui, sem necessidade de matriz esparsa.

---

### 6. Registro de experimento

Toda rodada é um nó `experimento`, com hipótese, parâmetros, commit, valor da FO, gap, segundos e
conclusão (`convencoes.md` §9). A regra do enunciado é literal: *"o que não estiver no banco, não
aconteceu"*, e o indicador comum do §6.3 — valor da FO, tamanho da instância, tempo de solução — é
lido do banco.

O problema prático é que registrar depende de disciplina, e disciplina falha exatamente nas
semanas em que mais se roda. A solução é gerar o YAML a partir do resultado do solver.

**Duas restrições do repositório que moldam a solução.** Primeira: funções em `app/R/` não escrevem
arquivo (`convencoes.md` §2.2) — quem escreve é o `targets`. Segunda: as ferramentas de governança
são em Python (`CLAUDE.md` §8), e escrever no grafo é editar YAML e commitar, nunca escrever no
banco. A saída que respeita as duas é: **a função em R é pura e devolve o texto YAML**; um alvo do
`targets` grava; o humano preenche a conclusão e commita.

```r
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
```

Uso, dentro do pipeline:

```r
tempo <- system.time(sol <- resolver_highs(mp))["elapsed"]
r     <- resumo_solver(sol, tempo)

texto <- yaml_experimento(
  id         = "experimento:E01",
  titulo     = "P1 bilateral, p=12, t_barra=15min, theta=10min",
  parametros = list(p = 12, t_barra_min = 15, theta_min = 10,
                    tau_emb_min = 5, tau_des_min = 5,
                    fator_congestionamento = 1, formulacao = "desagregada"),
  obj = r$obj, gap = r$gap, segundos = r$segundos,
  commit    = commit_atual,      # passado pelo alvo, nunca por system() aqui dentro
  hipotese  = "Com t_barra folgado a solucao migra para a periferia.",
  conclusao = "PREENCHER DEPOIS DE OLHAR O MAPA - nao commitar com este texto.",
  arestas   = list(list(rel = "USA",          dst = "fonte:od2017"),
                   list(rel = "EXECUTA",      dst = "arquivo:app-R-resolver-p1-ompr"),
                   list(rel = "ASSINADA_POR", dst = "pessoa:henri"))
)
```

Três observações:

**A hipótese é escrita antes de rodar.** Se ela for redigida depois, com o resultado à vista, ela
sempre "se confirma" — e o registro perde exatamente o valor que tinha. Escreva a hipótese no
mesmo commit em que muda o parâmetro, e rode depois.

**O `commit` entra como argumento.** Chamar `system("git rev-parse --short HEAD")` dentro da
função a tornaria impura e faria o valor depender de quando ela roda, e não do que ela recebeu. O
alvo do `targets` obtém o hash (por exemplo com `gert::git_log(max = 1)$commit`) e o passa.

**A numeração `E<nn>` não é automática.** Gerar id por contagem de arquivos cria colisão quando duas
pessoas rodam em branches diferentes — e ids nunca mudam depois de criados (`convencoes.md` §4.1).
Escolha o id à mão, no momento de commitar.

---

### 7. Reprodutibilidade

**Seed fixa.** Declarada no `_targets.R`, não espalhada pelo código. Nada em P1 é estocástico, mas
o `renv`, a ordem de empate do solver e qualquer heurística de partida podem ser — e um empate
resolvido de forma diferente muda **quais** vertiportos aparecem no mapa sem mudar o valor da FO.
Se isso acontecer, é um achado a registrar (soluções alternativas ótimas são informação: significa
que a recomendação tem folga), não um bug a esconder.

**`renv` com `snapshot()` a cada dependência nova**, e o `renv.lock` commitado. "Qualquer pessoa
deve conseguir rodar o projeto do zero" é exigência textual do enunciado, e sem o lock ela é
falsa.

**O alvo que amarra tudo:**

```r
# fragmento de _targets.R
library(targets)
tar_option_set(
  packages = c("dplyr", "sf", "Matrix", "ompr", "ompr.roi",
               "ROI", "ROI.plugin.highs", "highs", "yaml"),
  seed = 20260824
)
tar_source("R")

list(
  # --- parametros do modelo, como ALVOS: mudar um invalida so o que depende dele
  tar_target(t_barra_min, 15),
  tar_target(theta_min,   10),
  tar_target(tau_emb_min,  5),
  tar_target(tau_des_min,  5),

  # --- T22: pre-processar e MEDIR
  tar_target(colunas_p1, construir_colunas(od_capturavel, matrizes_tempo,
                                           t_barra_min, theta_min,
                                           tau_emb_min, tau_des_min),
             format = "rds"),
  tar_target(instancia_medida, medir_instancia(colunas_p1, od_capturavel, candidatos)),
  tar_target(portao_tamanho,   checar_tamanho(instancia_medida, limite = 2e5)),

  # --- T23: resolver, para um p de referencia
  tar_target(modelo_p1, montar_matriz_p1(colunas_p1, candidatos, p = 12)),
  tar_target(sol_p1,    resolver_highs(modelo_p1), format = "rds"),

  # --- relaxacao linear, de onde saem os duais (T30, T31)
  tar_target(modelo_lp, montar_matriz_p1(colunas_p1, candidatos, p = 12, relaxado = TRUE)),
  tar_target(sol_lp,    resolver_highs(modelo_lp), format = "rds"),

  # --- curva de implantacao: ramificacao dinamica sobre p (T33/T34)
  tar_target(grade_p, 1:25),
  tar_target(sol_por_p,
             resolver_highs(montar_matriz_p1(colunas_p1, candidatos, p = grade_p)),
             pattern = map(grade_p), iteration = "list"),
  tar_target(curva_bilateral, montar_curva(sol_por_p, grade_p)),

  # --- T25: baseline unilateral no MESMO dado
  tar_target(sol_uni_por_p,
             resolver_mclp_unilateral(od_capturavel, matrizes_tempo$t_acesso,
                                      candidatos, p = grade_p, t_barra_min),
             pattern = map(grade_p), iteration = "list"),
  tar_target(curva_unilateral, montar_curva_uni(sol_uni_por_p, grade_p)),

  # --- a comparacao justa: a solucao unilateral, medida com a regua bilateral
  tar_target(curva_uni_na_regua_bilateral,
             vapply(sol_uni_por_p, function(s) avaliar_solucao(colunas_p1, s$abertos),
                    numeric(1)))
)
```

Dois detalhes que fazem diferença:

**Os parâmetros são alvos, não argumentos literais.** Assim `tar_outdated()` sabe que mudar
`theta_min` invalida `colunas_p1` e tudo a jusante — inclusive as figuras do relatório. É o
mecanismo que responde à pergunta 4 do §7 do `G00`: *quais conclusões dependem de um resultado que
já mudou.*

**A curva sai de ramificação dinâmica**, não de um `for`. Cada $p$ vira um ramo com cache próprio:
reprocessar apenas $p=13$ depois de um ajuste não recalcula os outros 24.

---

### 8. Diagnóstico quando não converge

#### 8.1 O gap não fecha

Sintoma: o HiGHS roda, o *incumbent* estaciona, e o *bound* não desce.

**Relaxação fraca — o suspeito número um.** Confirme antes de qualquer outra coisa: você montou a
formulação **agregada** sem querer? Rode `montar_matriz_p1()` com `relaxado = TRUE` e compare
$Z_{LP}$ com o melhor inteiro conhecido. Se $Z_{LP}$ estiver muito acima, é a relaxação. Na
desagregada isso é esperado em alguma medida — a bilateralidade quebra a quase-integralidade
(G06 §5) —, e essa é a razão de a comparação de T30 existir.

**Simetria entre candidatos.** Dois candidatos com tempos de acesso e de voo praticamente idênticos
— dois helipontos no mesmo quarteirão, o que em São Paulo é literalmente o caso — geram soluções
equivalentes que o B&B explora uma a uma. Diagnóstico: procure linhas duplicadas em `t_acesso` e
em `t_voo`. Tratamento correto: **fundir os candidatos quase-idênticos no pré-processamento**, com
a decisão registrada (é um agrupamento de dado, e muda a instância). Tratamento errado: adicionar
uma restrição de ordenação lexicográfica $y_1\ge y_2\ge\dots$, que só é válida entre candidatos
**exatamente** intercambiáveis e, aplicada a candidatos apenas parecidos, corta o ótimo.

**Cota inferior ruim no início.** O B&B começa sem incumbent e demora a achar um. Use o guloso
sobre `avaliar_solucao()` — ele é exato dado $y$, roda em milissegundos e dá uma solução viável
imediata:

```r
guloso <- function(colunas, candidatos, p) {
  abertos <- character(0)
  for (passo in seq_len(p)) {
    restantes <- setdiff(candidatos$id, abertos)
    ganhos <- vapply(restantes,
                     function(v) avaliar_solucao(colunas, c(abertos, v)),
                     numeric(1))
    abertos <- c(abertos, restantes[which.max(ganhos)])
  }
  abertos
}
```

Note que o guloso **não** tem garantia de $1-1/e$ aqui: essa garantia depende de submodularidade,
que a bilateralidade quebra (G06 §8.3). Ele serve como cota inferior e como aquecimento, jamais
como resultado. E há uma sutileza deliciosa: o guloso escolhe o **primeiro** vertiporto com ganho
zero — todos empatam em zero, porque um vertiporto sozinho não serve par nenhum. Se o guloso
sempre abrir o mesmo primeiro candidato por ordem alfabética, o passo 2 fica preso. Comece pelo
melhor **par**, não pelo melhor elemento.

**Cotas superiores.** $\overline Z=\sum_q\max_{(j,k)\in P_q}f_q\Delta_{qjk}$ é uma cota trivial e
válida (servir todo par pela melhor rota). Se o *bound* do solver estiver acima dela, há erro de
montagem.

**Se nada disso resolver**, afrouxe explicitamente: `mip_rel_gap = 0.01` e `time_limit`. E
**registre o gap no experimento** — o campo existe no esquema. Reportar "ótimo" quando o gap é 1%
é falsear o indicador do §6.3.

#### 8.2 O resultado é implausível

O checklist abaixo cobre os erros que produzem resultado plausível e errado, que são os perigosos.
Rode `checar_instancia()` sempre; ele custa nada.

| Sintoma | Causa provável | Como confirmar |
| --- | --- | --- |
| Cobertura perto de 100% | **erro de unidade**: `T_terrestre` em segundos, tratado como minutos ⇒ $\Delta$ 60× maior, todo par viável | `summary(colunas$delta)` — economias de centenas de minutos numa cidade não existem |
| $\Delta$ enorme e vertiportos em lugares estranhos | **$j=k$ não excluído** ⇒ "voo" de duração zero | `all(colunas$j != colunas$k)` |
| $\sum|P_q|$ **cresce** quando $\bar t$ diminui | **filtro invertido** (`>=` em vez de `<=`) | rode `medir_instancia()` para $\bar t\in\{10,15,20\}$ e confira a monotonicidade |
| Colunas com $\Delta<0$ | `theta_min` negativo, ou a subtração invertida ($T^{\text{uam}}-T^{\text{ter}}$) | `min(colunas$delta) >= theta_min` |
| $Z^*(1)>0$ | **bilateralidade quebrada**: `ck` trocado por `cj` num dos blocos | o teste de §4.5 |
| Curva côncava desde $p=1$ | idem — é o sintoma mais enganoso, porque *parece* um resultado | idem |
| Solução ótima com $\sum y_j<p$ e $Z$ baixo | pares OD sem opção dominando $Q$ | `medir_instancia()$Q_sem_opcao` |
| $Z$ muda ao reordenar `candidatos` | indexação por **posição** em algum ponto | `set.seed(1); candidatos[sample(nrow(candidatos)), ]` e re-resolva: `obj` tem de ser idêntico |
| Fluxo total servido maior que a demanda | `f_q` sem fator de expansão, ou pares OD duplicados | compare `sum(od_capturavel$viagens_dia)` com o total de T12 |

```r
# app/R/checar_instancia.R
# @tarefa    tarefa:T22

#' Bateria de verificacoes sobre a tabela de colunas, antes de resolver.
#'
#' Falhar cedo e alto e melhor que produzir resultado silenciosamente errado -
#' e num modelo de otimizacao o resultado errado e plausivel e ninguem percebe
#' (convencoes.md §2.2).
#'
#' @param colunas saida de construir_colunas()
#' @param theta_min limiar usado na construcao
#' @param maximo_delta_min maior economia considerada plausivel, em minutos
#' @return colunas, invisivelmente
checar_instancia <- function(colunas, theta_min, maximo_delta_min = 300) {
  stopifnot(
    nrow(colunas) > 0L,
    identical(colunas$col_id, seq_len(nrow(colunas))),
    all(colunas$j != colunas$k),
    min(colunas$delta) >= theta_min,
    max(colunas$delta) <= maximo_delta_min,   # unidade: minutos, nao segundos
    all(colunas$f_q > 0),
    all(is.finite(colunas$coef)),
    !anyDuplicated(colunas[, c("q_id", "j", "k")])
  )
  invisible(colunas)
}
```

O teto de `maximo_delta_min = 300` não é um dado: é um **detector de erro de unidade**. Cinco horas
economizadas numa viagem urbana é impossível, e se o `stopifnot` disparar, quase certamente há
segundos tratados como minutos em algum ponto da cadeia. Se disparar legitimamente, o valor é
parâmetro e se ajusta — com nota registrada.

---

## Critério de pronto

- [ ] `outputs/colunas_p1.rds` existe, com `col_id` em `1..nrow` e sem `NA`.
- [ ] `medir_instancia()` rodou e os números estão **numa nota da `tarefa:T22`**, com a data:
      `Q_elegiveis`, `Q_com_opcao`, `Q_sem_opcao`, `soma_Pq`, `Pq_medio`, `Pq_p95`, `var_w`,
      `var_y`, `linhas_desagr`, `nao_zeros`.
- [ ] Os números medidos estão **comparados** com as estimativas do plano ($|Q|$ 2.000–4.000,
      $|P_q|$ 20–60, $w$ $4\times10^4$–$2\times10^5$), e a divergência está comentada.
- [ ] Se `soma_Pq > 2e5`, existe `decisao:` registrando qual saída foi tomada e as descartadas.
- [ ] `checar_instancia()` passa.
- [ ] Os testes de T24 passam: instância-brinquedo A ($Z^*=0/7940/8570$), instância-brinquedo B
      ($Z_{IP}=0$, $Z_{LP}=1$), e a equivalência entre as duas rotas de implementação.
- [ ] P1 resolve na instância real, com **gap registrado** (zero, ou o valor efetivo).
- [ ] A relaxação LP resolve e os duais saem, com a **convenção de sinal verificada** ($\pi\ge 0$).
- [ ] O baseline unilateral resolve **sobre o mesmo `od_capturavel`, o mesmo `t_acesso` e o mesmo
      $\bar t$**.
- [ ] As três séries existem: $Z^*(p)$ bilateral, $Z^{\text{uni}*}(p)$, e
      `avaliar_solucao(colunas, S_uni(p))`.
- [ ] Toda rodada tem nó `experimento` com hipótese **e** conclusão preenchidas — nenhuma com
      "PREENCHER".
- [ ] `renv.lock` commitado; `targets::tar_make()` roda do zero em máquina limpa.
- [ ] `targets::tar_outdated()` sai vazio; o validador do grafo passa.
- [ ] A divergência de atribuição de T24/T25 (ver "Tarefas no grafo") está resolvida numa das duas
      direções, com nota.

---

## Armadilhas conhecidas

**Indexar $w$ por array 3D.** Ver §3. É a armadilha que custa dias, e ela não se manifesta como
erro: manifesta-se como um dia inteiro escrevendo laços aninhados que depois não escalam.

**`which(cols$q_id == q)` dentro do `add_constraint`.** Parece natural e é quadrático: a expressão
é avaliada uma vez por quantificador, varrendo as $10^5$ linhas a cada uma das $10^3$ vezes.
Pré-compute `idx_q <- split(seq_len(nC), factor(colunas$q_id))` **fora** e indexe. A diferença é
entre segundos e uma hora.

**Colisão de nome entre a matriz e a coluna.** Dentro de `mutate()`, `T_terrestre` como nome de
objeto e como nome de coluna se confundem, e a máscara de dados do `dplyr` vence. Por isso o
código da §1.2 chama a matriz de `m_ter` e a coluna de `t_ter`, e usa `.data$` nas referências. Não
é preciosismo: é a categoria de bug que produz resultado plausível.

**`relationship = "many-to-many"` omitido.** Versões recentes do `dplyr` avisam; versões antigas
não. O join **é** muitos-para-muitos por natureza (uma zona tem vários candidatos próximos), e
declarar isso explicitamente documenta a intenção e desliga um aviso que, ignorado, treina o grupo
a ignorar avisos.

**Filtrar a tabela de colunas depois de atribuir `col_id`.** Quebra a correspondência com a matriz
esparsa, silenciosamente. Se precisar filtrar, reconstrua.

**`types` na codificação errada em `highs_solve()`.** Pode ser aceito e resolver o LP em vez do
MILP. Sintoma: $y$ fracionário na solução. Sempre confira
`all(sol_y %in% c(0,1))` antes de acreditar no resultado.

**Ler dual de MIP.** Não existe (G06 §1.5). Resolva a relaxação.

**Comparar as duas curvas em unidades diferentes no mesmo eixo.** Ver §5.3.

**Rodar a curva $p=1..25$ antes de o modelo estar validado.** São 25 execuções do modelo errado, e
o gráfico resultante parece perfeitamente respeitável. T24 vem antes de T33.

**Ajustar $\bar t$ ou $\theta$ até a curva ficar bonita.** O histórico de experimentos é público no
site, com carimbo de data. Se a hipótese não se confirmar, o achado é esse.

**Deixar a conclusão do experimento como "PREENCHER".** O esquema aceita a string; a arguição não.
Um experimento sem conclusão é uma rodada, e o §9 das convenções diz isso literalmente.

**Confiar que o `ompr` vai escalar porque escalou no brinquedo.** Ver §2.2. O brinquedo tem cinco
colunas.

---

## O que registrar

**Decisões**

- **Valores de $\bar t$ e $\theta$ efetivamente usados** na primeira rodada — se ainda não houver
  a decisão do G06, ela nasce aqui, com responsável.
- **Rota de implementação** — `ompr` ou matriz esparsa —, com o número medido de `soma_Pq` como
  justificativa. É uma decisão de engenharia com efeito sobre reprodutibilidade e legibilidade, e
  o enunciado pede a redução da instância documentada (§4.5).
- **O que foi feito se `soma_Pq` estourou o limite**, com as quatro alternativas do §1.3 e o motivo
  específico de cada rejeição.
- **Fusão de candidatos quase-idênticos**, se houver (§8.1) — muda a instância.
- **Baseline como a‑MCLP unilateral e não a‑CFLP**, com o motivo: $f^{\text{fix}}_j$ e $C_j$ são
  `[A CONFIRMAR]`, e baseline sobre parâmetro sem fonte é uma segunda fonte de erro.
- **Tratamento de soluções ótimas alternativas**, se aparecerem.

**Experimentos** — um nó por rodada. No mínimo: a primeira rodada de P1 na instância real; a
relaxação LP correspondente; a rodada da formulação agregada (para T30); as 25 rodadas da curva
(que podem virar **um** nó com `parametros: {p: "1..25"}` e a série anexa, se registrar 25 nós for
ruído); e as rodadas do baseline. Cada um com **hipótese escrita antes**.

**Fontes** — nenhuma nova neste pacote. Se o baseline consumir algum dado que o P1 não consome, aí
sim.

**Pendências**

- `pendencia:` se a assinatura do `highs_solve()` na versão travada divergir do que este guia
  assume — e a correção do guia no mesmo commit (`G00` §3.2).
- `pendencia:` se `Q_sem_opcao` for grande. Muitos pares elegíveis sem rota nenhuma significa que
  $\bar t$ ou $\theta$ estão apertados demais para a geografia dos candidatos, e isso é um achado
  sobre a viabilidade da UAM em São Paulo — não um defeito do código.

**Arquivos** — `arquivo:app-R-construir-colunas`, `arquivo:app-R-medir-instancia`,
`arquivo:app-R-montar-matriz-p1`, `arquivo:app-R-resolver-p1-ompr`,
`arquivo:app-R-avaliar-solucao`, `arquivo:app-R-resolver-mclp-unilateral`,
`arquivo:app-R-yaml-experimento`, com as arestas `PRODUZ` correspondentes.

**Notas em tarefa** — em `tarefa:T22`, a medição completa da instância, datada. Ela é o insumo do
indicador "tamanho da instância" do §6.3 e é a correção pública de uma estimativa que este projeto
declarou como estimativa desde 24/08. Em `tarefa:T24`, o registro de que a instância-brinquedo
exibiu a curva em S em miniatura — ou de que não exibiu, se não exibir.

**Interação de IA** — `critica_humana` não vazia. Candidatos honestos a crítica neste pacote:

- Os números da instância-brinquedo são **sintéticos**, escolhidos por quem escreveu o guia para
  que o ótimo fosse conferível à mão. Eles validam a **implementação**, não o **modelo**: um
  modelo conceitualmente errado que fosse implementado corretamente passaria em todos os testes.
- A afirmação de que `ompr` "fica muito lento acima de ~$10^5$ variáveis" vem da revisão de
  literatura e **não foi medida por nós**. O limiar de $5\times10^4$ para trocar de rota, na §2.2,
  é ainda mais frouxo — é uma margem de segurança escolhida, não um número.
- Os nomes de argumento de `highs::highs_solve()` e os campos do objeto de solução foram escritos
  a partir de conhecimento de biblioteca e **precisam ser conferidos na versão travada**. Este
  guia diz isso em dois lugares, mas quem executar precisa fazê-lo, e não presumir.
- A previsão de que o modelo unilateral escolherá sítios dispersos e o bilateral, sítios
  concentrados em corredores (§5.1) é **hipótese**, escrita antes de qualquer rodada. Se o
  resultado for o contrário, é resultado.

---

## Como isso vira relatório

**Seção de metodologia — pré-processamento.** A §1 é a subseção de "redução da instância", que o
§4.5 do enunciado pede documentada. O par de números (estimativa do plano × medição de T22) é uma
tabela pequena e de valor desproporcional: mostra um grupo que estimou, mediu e corrigiu, que é
exatamente o comportamento que a Camada B avalia.

**Seção de implementação.** As duas rotas, com o critério de escolha entre elas, e o leiaute de
colunas e linhas da §2.3. Este é o trecho que responde à pergunta "vocês entenderam o modelo ou
chamaram uma biblioteca?" — quem sabe dizer qual linha da matriz é o dual $\pi$ sabe o que está
resolvendo.

**Seção de validação.** A instância-brinquedo inteira, com a tabela de $\Delta$ e o ótimo à mão. É
raro um trabalho de graduação mostrar validação; mostrá-la com números que o leitor consegue
refazer no papel é mais forte que qualquer afirmação de correção. E o fato de $Z^*(1)=0$ ser o
teste da bilateralidade liga a validação diretamente à contribuição do trabalho.

**Seção de resultados — desempenho computacional.** O indicador comum do §6.3, direto dos nós
`experimento`: valor da FO, tamanho da instância, tempo de solução, gap. Sai por consulta ao
grafo, não por reconstrução de memória na véspera — que é a razão de o registro automático da §6
existir.

**Seção de resultados — a figura central.** As duas curvas de implantação sobrepostas: a bilateral
partindo de $Z^*(1)=0$ e a unilateral côncava desde o primeiro vertiporto, mais a terceira série —
a solução unilateral medida com a régua bilateral. A distância vertical entre a primeira e a
terceira é **o custo, em pax·min/dia, de ter modelado a cobertura como unilateral**, que é a
lacuna L1 quantificada. Essa figura é o trabalho inteiro em um gráfico.

**Arguição.** A pergunta provável aqui é *"como vocês sabem que o modelo está certo?"*. A resposta
boa não é "conferimos" — é: "resolvemos à mão uma instância de 5 zonas e 3 candidatos, o ótimo é
7940 pax·min/dia com dois vertiportos e zero com um, e isso é um teste automatizado que roda a
cada `tar_make()`; a segunda instância mostra a relaxação valendo 1 onde o inteiro vale 0". Uma
pergunta que costuma ser desconfortável vira o momento de mostrar profundidade.
