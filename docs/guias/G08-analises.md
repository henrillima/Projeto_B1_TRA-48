# G08 — As quatro análises de Programação Linear

> Pacote de trabalho **de todos os três**. Prazo do pacote: **19/09/2026**.
> Leia `docs/guias/G00-como-trabalhar.md` e `CLAUDE.md` antes deste.
>
> **Atenção ao calendário.** A Prova B1 é **16/09** e o modelo **congela nessa data**. As
> análises deste pacote precisam rodar sobre modelo já estável entre **09/09 e 14/09**. Semana
> de prova não é semana de conserto de formulação.

---

## Objetivo

Ao fim deste pacote existem, em `app/outputs/`, os quatro objetos analíticos que o §4.4 do
enunciado exige — relaxação linear comparada, duais interpretados, sensibilidade varrida e
curva de implantação — mais **uma** extensão implementada, mais a tabela dos indicadores comuns
do §6.3, mais as figuras do relatório com especificação fechada.

E existe, no grafo, um nó `experimento` para cada rodada que produziu qualquer um deles.

O enunciado é explícito sobre por que estas quatro e não outras:

> *"O modelo pode ser inteiro-misto; o bimestre trata de Programação Linear. O vínculo com a
> matéria é obrigatório, e se dá por quatro análises."* (§4.4)

Ou seja: **estas quatro são o vínculo entre o trabalho e a disciplina**. São o coração da nota
de modelagem, e a T31 em particular é o que separa nota boa de nota máxima — o critério de
excelência diz literalmente que o grupo *"interpreta o dual e a sensibilidade em linguagem de
decisão — não apenas reporta números"*.

---

## Tarefas no grafo

| Id | Título | Responsável | Prazo | Est. | Depende de |
| --- | --- | --- | --- | --- | --- |
| `tarefa:T30` | Comparar relaxação desagregada e agregada | `pessoa:henri` | 12/09 | 5 h | `tarefa:T23` |
| `tarefa:T31` | Interpretar economicamente as variáveis duais | `pessoa:pedro` | 12/09 | 5 h | `tarefa:T23` |
| `tarefa:T32` | Rodar a análise de sensibilidade nos limiares | `pessoa:antonio` | 14/09 | 6 h | `tarefa:T23` |
| `tarefa:T33` | Levantar a curva de implantação e testar o formato em S | `pessoa:henri` | 14/09 | 6 h | `tarefa:T23`, `tarefa:T25` |
| `tarefa:T34` | Implementar UMA extensão: massa crítica ou equidade | `pessoa:antonio` | 19/09 | 8 h | `tarefa:T33` |

Todas `REALIZA meta:M3`.

Três observações sobre esta tabela, e as três importam:

**O pacote é de todos, mas cada tarefa tem dono.** O guia é lido pelos três; a assinatura de
cada análise é de uma pessoa. Isso não dispensa ninguém de saber defender qualquer uma delas na
arguição — a coluna `revisao` do kanban existe exatamente para forçar que um segundo par de
olhos entenda antes de aceitar.

**T30, T31 e T32 são paralelas.** As três dependem só de T23 e não uma da outra. Rodem em
paralelo a partir de 09/09. T33 é a que consome mais tempo de máquina (25 resoluções × 2
modelos) e deve começar primeiro, rodando em segundo plano enquanto as outras andam.

**T34 vence 19/09, depois do congelamento de 16/09 — e isso é intencional, não um erro.** A
extensão **não** altera o modelo congelado: ela é uma **variante**, registrada como experimento
próprio, comparada contra a baseline congelada. Ver §5.0 e a armadilha correspondente.

---

## Pré-requisitos

- [ ] **G07 concluído** (T22–T25), com o critério de pronto inteiro cumprido. Em particular
      **T25**: a validação contra a instância-brinquedo de 5 zonas e 3 candidatos resolvida à
      mão. Análise de sensibilidade sobre modelo não validado é a produção industrial de
      números errados — e o erro só aparece na arguição.
- [ ] `app/outputs/modelo_p1.rds` — o objeto do modelo montado, com o contrato de §0.2 abaixo.
- [ ] `app/outputs/matrizes_tempo.rds` (G05) e o `fator_congestionamento` **calibrado**. Se
      `pendencia:P__` de G05 (matriz em *free-flow*) ainda estiver aberta, ela tem aresta
      `BLOQUEIA` para T30–T34. Nenhuma conclusão sai deste pacote com essa pendência aberta.
- [ ] `app/outputs/od_capturavel.rds` (G03) com `decisao:D03` vigente.
- [ ] O **baseline unilateral** do G07 rodando no mesmo dado — é metade da figura central.
- [ ] `renv` com `highs`, `Matrix`, `dplyr`, `tidyr`, `purrr`, `ggplot2`, `sf`, `tmap`,
      `targets` no lock.
- [ ] Ter lido, em `docs/01-revisao-literatura.md`: §1.3 (MCLP e a nota sobre quase-integralidade
      da relaxação de ReVelle–Swain), §1.7 (FRLM de Kuby & Lim 2005, de onde vem a forma
      canônica da restrição de ligação) e §3 (as lacunas L1, L2 e L5, que são a justificativa
      teórica das quatro análises).

---

## Insumos

| Insumo | Onde | O que é |
| --- | --- | --- |
| Modelo P1 montado | `outputs/modelo_p1.rds` | lista com `A`, `lhs`, `rhs`, `obj`, `tipos`, `lb`, `ub`, `idx`, `linhas` |
| Arcos viáveis | `outputs/arcos.rds` | data frame `q, j, k, coef` — um por elemento de $P_q$ |
| Baseline unilateral | `outputs/modelo_mclp.rds` | MCLP unilateral do G07, mesmo dado |
| Candidatos | `outputs/candidatos.rds` | `sf`, com `id`, geometria e a marca de periferia (para T34-equidade) |
| Macrozonas | `outputs/macrozonas.rds` | `sf` em EPSG:31983 |
| Valor do tempo | `decisao:D__` | R$/h, com procedência — **não é um número deste guia** |

### Os parâmetros que este pacote varre

Todos já são parâmetros do pipeline por força da regra 8 do `CLAUDE.md`. Se algum ainda for
literal no meio do código, **pare e conserte antes**: número mágico é um experimento que não vai
poder ser rodado.

| Símbolo | Nome no código | O que varre | O que a variação mede |
| --- | --- | --- | --- |
| $p$ | `p` | 1 … 25 | a curva de implantação (T33) |
| $\bar t$ | `t_barra_min` | 10, 15, 20, 30 min | quanto a UAM depende do *first/last mile* |
| $\theta$ | `theta_min` | 0, 10, 20, 30 min | a fragilidade da proposta de valor |
| VoT | `vot_brl_h` | ±50% em torno do valor decidido | quanto a monetização carrega o resultado |
| $C_j$ | `capacidade_j` | se a extensão de capacidade for usada | o gargalo de FATO |
| $f$ | `fator_congestionamento` | 1,0 até o calibrado | **o parâmetro mais incerto de todos** (G05 §3) |

O `fator_congestionamento` merece destaque: ele multiplica $T^{\text{ter}}_q$, que entra em
$\Delta_{qjk}$ linearmente, que entra na FO linearmente. É o parâmetro com maior alavancagem
sobre o resultado **e** o de menor sustentação empírica. Varrê-lo não é zelo — é honestidade.

---

## Passo a passo

### 0. Antes de rodar qualquer coisa

#### 0.1 O congelamento de 16/09, operacionalizado

Congelar o modelo significa: a partir de 16/09, `montar_modelo()` e a formulação em LaTeX não
mudam mais. **Registre o congelamento como decisão**, com o hash do commit:

```
decisao:D__ — "Congelar a formulação P1 no commit <sha>"
```

Tudo que vier depois — inclusive a extensão de T34 — é **variante comparada contra esse commit**,
não substituição dele. Isso protege duas coisas: as conclusões já escritas continuam apoiadas em
código que ainda existe, e a auditoria não encontra `tar_outdated()` apontando figura gerada por
código que mudou.

#### 0.2 O contrato do objeto do modelo

Este guia assume que G07 entrega `montar_modelo()` devolvendo uma lista com estes campos.
**Se a interface real de G07 divergir, corrija este guia no mesmo commit** (G00 §3.2) — guia
desatualizado é pior que guia ausente.

```r
modelo <- montar_modelo(arcos, candidatos, p = 12, forma = "desagregada", binarias = TRUE)

# modelo$A       Matrix::dgCMatrix, m x n
# modelo$lhs     limite inferior de cada linha (-Inf onde não há)
# modelo$rhs     limite superior de cada linha
# modelo$obj     vetor de coeficientes da FO, comprimento n
# modelo$tipos   "C" ou "I" por coluna
# modelo$lb, modelo$ub
# modelo$idx     lista: $w = data.frame(q, j, k, col)   $y = data.frame(id, col)
# modelo$linhas  data.frame(bloco, q, j, k, linha)
#                bloco ∈ {"cobertura","liga_o","liga_d","cardinalidade","capacidade",...}
```

O campo `linhas` é o que torna a T31 possível: sem ele, o vetor de duais é um vetor de números
sem nome, e não dá para dizer qual componente é $\pi$ e qual é $\alpha_q$. **Se G07 não devolver
`linhas`, essa é a primeira coisa a acrescentar.**

#### 0.3 A função que resolve, e a que extrai dual

```r
# app/R/resolver.R
# @produz    outputs/solucao_*.rds
# @consome   outputs/modelo_p1.rds
# @decisao   decisao:[a registrar - congelamento da formulacao]
# @tarefa    tarefa:T30

#' Resolve uma instância do P1, inteira ou relaxada, e devolve tudo que as
#' análises do G08 precisam.
#'
#' Existe com o argumento `inteiro` em vez de duas funções porque a comparação
#' entre Z_IP e Z_LP é o objeto de T30: as duas resoluções têm que ser
#' garantidamente a MESMA matriz, e a única forma de garantir isso é não ter
#' dois caminhos de construção.
#'
#' @param modelo lista no contrato de G07 (ver G08 §0.2)
#' @param inteiro TRUE resolve o MIP; FALSE relaxa as binárias para [0,1]
#' @param tempo_max_s limite de tempo do solver, em segundos
#' @return lista com z, x, duais, status, segundos, n_linhas, n_colunas, n_nz
resolver <- function(modelo, inteiro = TRUE, tempo_max_s = 600) {
  stopifnot(is.list(modelo), inherits(modelo$A, "Matrix"),
            is.logical(inteiro), length(inteiro) == 1,
            length(modelo$obj) == ncol(modelo$A))

  tipos <- if (inteiro) modelo$tipos else rep("C", length(modelo$obj))

  cron <- system.time(
    res <- highs::highs_solve(
      L       = modelo$obj,
      lower   = modelo$lb,
      upper   = modelo$ub,
      A       = modelo$A,
      lhs     = modelo$lhs,
      rhs     = modelo$rhs,
      types   = tipos,
      maximum = TRUE,
      control = highs::highs_control(time_limit = tempo_max_s)
    )
  )

  list(
    z         = res$objective_value,
    x         = res$primal_solution,
    duais     = if (inteiro) NULL else extrair_duais(res),
    status    = res$status_message,
    segundos  = as.numeric(cron[["elapsed"]]),
    n_linhas  = nrow(modelo$A),
    n_colunas = ncol(modelo$A),
    n_nz      = Matrix::nnzero(modelo$A)
  )
}

#' Extrai o vetor de duais de linha do retorno do HiGHS.
#'
#' Encapsulado porque a posição desse vetor no objeto de retorno já mudou entre
#' versões do pacote `highs`. Um `str(res)` uma vez, aqui, evita descobrir a
#' mudança no meio da varredura de sensibilidade.
extrair_duais <- function(res) {
  d <- res$solver_msg$row_dual        # [A CONFIRMAR na versão do renv.lock]
  if (is.null(d)) d <- res$dual
  if (is.null(d)) return(NULL)
  as.numeric(d)
}
```

**Confirme o nome do campo uma vez, com `str(res)`, e registre em nota na T30.** Não deixe isso
para a hora da varredura: o sintoma de errar aqui é `duais = NULL` silencioso, e o efeito é uma
seção inteira do relatório vazia na véspera.

Note também: **`duais` é `NULL` quando `inteiro = TRUE`, e isso é correto, não é bug.** A razão
está em §2.1.

---

### 1. T30 — Relaxação linear

#### 1.1 O que exatamente se compara

Não é "o modelo relaxado contra o modelo inteiro" — isso é só um número. É **duas formulações
diferentes do mesmo problema**, cada uma com sua relaxação, para mostrar que a força da
relaxação é uma escolha de modelagem e não uma propriedade do problema.

**Forma desagregada** — a do P1, uma linha por arco e por lado:

$$w_{qjk} \le y_j \quad\text{e}\quad w_{qjk} \le y_k \qquad \forall q,\ (j,k)\in P_q$$

Linhas: $2\sum_q |P_q|$. Muitas. Relaxação forte.

**Forma agregada** — uma linha por par de vertiportos e por lado:

$$\sum_{q\,:\,(j,k)\in P_q} w_{qjk} \le |Q_{jk}|\, y_j \quad\text{e}\quad \sum_{q\,:\,(j,k)\in P_q} w_{qjk} \le |Q_{jk}|\, y_k$$

onde $|Q_{jk}| = |\{q : (j,k)\in P_q\}|$ é o *big-M* mais justo possível para aquele par.
Linhas: no máximo $2|J|^2$. Poucas. Relaxação fraca.

**Forma média** — uma linha por arco, com a média dos dois lados:

$$w_{qjk} \le \tfrac{1}{2}\,(y_j + y_k)$$

Metade das linhas da desagregada, e mais fraca que ela: admite $y_j = 1$, $y_k = 0$ com
$w_{qjk} = 0{,}5$, isto é, meia viagem pousando em lugar nenhum.

> A revisão de literatura (§4, Caminho 1) escreve a forma média como
> $\sum_{(j,k)\in P_q} w_{qjk} \le \frac{1}{2}(y_j+y_k)$, o que não fecha dimensionalmente —
> $j$ e $k$ variam dentro do somatório. A leitura acima, por arco, é **a nossa interpretação** e
> merece uma linha de decisão registrada dizendo isso. Não corrija a fonte em silêncio.

Este é o trade-off clássico de formulação forte × compacta, o mesmo do UFLP desagregado contra o
agregado. A graça de reportá-lo aqui é que ele **não é folclore: é medível na nossa instância**,
e a medição é barata.

#### 1.2 A teoria que precisa estar escrita no relatório

A relaxação LP do MCLP puro é notoriamente quase-integral — a revisão registra isso em §1.3, e a
observação remonta à formulação de ReVelle–Swain. A razão intuitiva: com uma única restrição de
ligação $z_i \le \sum_{j \in N_i} y_j$, comprar "meia cobertura" exige meio vertiporto, e o
custo em orçamento é proporcional ao benefício. Não há arbitragem: fracionar não rende nada, e
o LP tende a devolver vértices inteiros.

**A bilateralidade quebra essa propriedade, e o mecanismo é exato.** Com

$$w_{qjk} \le y_j \quad\text{e}\quad w_{qjk} \le y_k,$$

fazer $y_j = y_k = \tfrac12$ permite $w_{qjk} = \tfrac12$. Isto é: **meia cobertura de um par
custou um vertiporto inteiro de orçamento** ($\tfrac12 + \tfrac12$) — mas esse mesmo meio
vertiporto em $j$ serve simultaneamente como "meia origem" para *todos* os pares que passam por
$j$. O LP compra frações de vertiporto e as reutiliza em todos os arcos ao mesmo tempo, o que a
solução inteira não pode fazer. É exatamente a superaditividade da FO, vista pelo outro lado: a
FO deixa de ser submodular, e a relaxação deixa de ser justa.

Esta é a mesma estrutura da restrição $v_h \le y_k$ do FRLM (Kuby & Lim, 2005), citada em §1.7
da revisão — e é a razão de o FRLM também ter relaxação fraca.

#### 1.3 O exemplo mínimo que exibe o fenômeno

**Construa-o e resolva-o com o solver.** Ele vira uma caixa de meia página no relatório e uma
resposta de dez segundos na arguição, e é a prova de que o grupo entendeu o mecanismo em vez de
ter observado um número.

**Instância A — a menor possível.** $J = \{1,2\}$, um único par $q$ com $P_q = \{(1,2)\}$,
$f_q\Delta_q = 1$, e $p = 1$.

| | $y_1$ | $y_2$ | $w$ | $Z$ |
| --- | --- | --- | --- | --- |
| Inteiro | 1 | 0 | 0 | **0** |
| Relaxado | 0,5 | 0,5 | 0,5 | **0,5** |

Com um vertiporto de orçamento não se serve par nenhum: $Z_{IP} = 0$. O LP serve metade.
O gap relativo nem sequer é definido (divisão por zero) — reporte o gap **absoluto** e diga por
quê. Uma instância em que $Z_{IP}=0$ e $Z_{LP}>0$ já é o argumento inteiro.

**Instância B — a que dá um gap com razão finita e escala.** $J = \{1,2,3\}$, três pares, cada um
viável por exatamente um par de vertiportos: $P_{q_1}=\{(1,2)\}$, $P_{q_2}=\{(1,3)\}$,
$P_{q_3}=\{(2,3)\}$, todos com $f_q\Delta_q = 1$, e $p = 2$.

- **Inteiro:** abrir dois quaisquer cobre exatamente um par. $Z_{IP} = 1$.
- **Relaxado:** $y_1=y_2=y_3=\tfrac23$ (soma $=2=p$), $w_q = \tfrac23$ para os três.
  $Z_{LP} = 3 \times \tfrac23 = 2$.
- **Gap de integralidade:** $(2-1)/2 = 50\%$.

E ele **cresce sem limite**: com $|J| = n$ candidatos, todos os $\binom{n}{2}$ pares presentes e
$p = 2$, o LP faz $y_j = 2/n$ para todo $j$ e obtém $Z_{LP} = \binom{n}{2}\cdot\frac{2}{n} = n-1$,
enquanto $Z_{IP} = 1$. **A razão $Z_{LP}/Z_{IP}$ é $n-1$.** Nenhum MCLP unilateral tem esse
comportamento.

> Os números acima são **aritmética sobre instâncias de brinquedo construídas à mão**, não
> resultados da instância de São Paulo. Rode as duas no `resolver()` e confirme antes de
> escrever — se o solver discordar da conta, o erro está no montador, e é melhor descobrir isso
> num modelo de três variáveis do que num de duzentas mil.

Codifique as duas instâncias como um teste, não como um script:

```r
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
```

#### 1.4 O montador com as três formas

O que muda entre as três é **só o bloco de linhas de ligação**. Escreva-o como uma função
separada, e não como três montadores:

```r
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
```

**Use `|Q_jk|` e não `|Q|` como big-M.** São dois números muito diferentes, e o big-M frouxo
piora a relaxação de graça. Se a comparação for feita com `|Q|`, ela superestima a diferença
entre as formas e a conclusão fica inflada — o que é o mesmo defeito de reportar um resultado
bom por engano.

#### 1.5 A tabela que sai de T30

```r
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
```

A coluna `y_frac_lp` — quantos $y_j$ saíram fracionários na relaxação — é a que transforma a
tabela em argumento. Se ela for zero na desagregada e alta na agregada, a frase do relatório
escreve-se sozinha. Se ela for **alta na desagregada também**, isso é o achado, e o relatório
diz exatamente isso: a bilateralidade fraciona mesmo a formulação forte.

**O que reportar, na ordem:** (1) a tabela; (2) o exemplo mínimo de §1.3; (3) uma leitura do gap
em linguagem de decisão — *"o limite superior que o LP dá para a demanda atendível está X% acima
do que se consegue de fato com p vertiportos inteiros; quem usar o LP como estimativa de
viabilidade vai superestimar o sistema nessa margem"*; (4) o custo computacional das duas formas.

---

### 2. T31 — Interpretação econômica do dual

> **Esta é a análise que o G00 §4.3 lista como uma das três coisas que não se delegam.** O Claude
> pode montar o código de extração; a frase de interpretação é assinada por uma pessoa, e essa
> pessoa vai ser arguida sobre ela. Leia esta seção inteira antes de rodar qualquer coisa.

#### 2.1 A sutileza que precisa estar explicada no relatório

**Programas inteiros não têm duais.** A dualidade forte da PL não se estende a MIP: não existe um
vetor de preços-sombra que certifique a otimalidade de uma solução inteira, porque o conjunto
viável não é um poliedro sobre o qual a dualidade valha. O que existe são três coisas
diferentes, e confundi-las é erro de conceito, não de código:

| Objeto | De onde vem | O que significa | Onde usamos |
| --- | --- | --- | --- |
| **Dual da relaxação LP** | resolver o LP do modelo inteiro | preço-sombra do **problema relaxado**; limita o marginal do inteiro por cima | $\pi_{LP}$, comparação |
| **Dual do LP restrito** | fixar $y$ no ótimo inteiro e re-resolver em $w$ | preço-sombra **condicionado à rede escolhida** — é o economicamente interpretável | $\alpha_q$, $\gamma_j$ |
| **Diferença finita** | $Z^*(p+1) - Z^*(p)$ da curva de T33 | o valor marginal **verdadeiro** de um vertiporto a mais | $\pi$ para a recomendação |

A leitura correta e defensável: **$\pi_{LP}$ é a inclinação da envoltória côncava da curva de
implantação; a diferença finita é a inclinação da curva de verdade.** Quando as duas divergem,
a divergência *é* o gap de integralidade visto pela derivada — e ela vai ser maior justamente no
trecho convexo do S, onde a curva inteira cresce mais rápido do que qualquer função côncava
poderia. Isto amarra T30, T31 e T33 numa frase só, e é o tipo de amarração que a arguição
recompensa.

#### 2.2 Como obter cada dual, na prática

**O LP relaxado inteiro** já sai de `resolver(m, inteiro = FALSE)`. Dele vem $\pi_{LP}$.

**O LP restrito** é o passo que quase todo grupo esquece. Fixe as binárias no ótimo e
re-resolva:

```r
# app/R/duais.R
# @produz    outputs/duais.rds
# @consome   outputs/modelo_p1.rds
# @tarefa    tarefa:T31

#' Fixa as binárias na solução inteira ótima e re-resolve o LP restante.
#'
#' Existe porque o MIP não devolve dual algum, e o dual do LP relaxado responde
#' a outra pergunta (o preço-sombra de uma rede fracionária, que não existe).
#' Com y fixo, o que sobra é um LP em w cujos duais têm leitura direta:
#' o valor de servir cada par, dada a rede que efetivamente vamos construir.
#'
#' @param modelo lista no contrato de G07
#' @param y_otimo vetor nomeado 0/1 por id de candidato, do ótimo inteiro
#' @return o mesmo retorno de `resolver()`, com duais não nulos
resolver_restrito <- function(modelo, y_otimo) {
  stopifnot(!is.null(modelo$idx$y), all(modelo$idx$y$id %in% names(y_otimo)))

  m <- modelo
  cols <- m$idx$y$col
  val  <- as.numeric(y_otimo[m$idx$y$id])
  m$lb[cols]    <- val
  m$ub[cols]    <- val
  m$tipos[cols] <- "C"          # já fixas; deixar inteiras só atrapalharia

  resolver(m, inteiro = FALSE)
}

#' Nomeia o vetor de duais usando o mapa de linhas do modelo.
#'
#' Sem isto, o dual é um vetor de números sem endereço. O mapa `modelo$linhas`
#' é o que permite dizer qual componente é pi, qual é alpha_q e qual é gamma_j —
#' e é por isso que ele é parte do contrato do montador, e não um extra.
#'
#' @param modelo lista no contrato de G07
#' @param sol retorno de `resolver()` com duais
#' @return lista com pi (escalar), alpha (data frame q, valor), gamma (data frame j, valor)
nomear_duais <- function(modelo, sol) {
  stopifnot(!is.null(sol$duais), nrow(modelo$linhas) == length(sol$duais))
  d <- data.frame(modelo$linhas, dual = sol$duais)

  list(
    pi    = d$dual[d$bloco == "cardinalidade"],
    alpha = d[d$bloco == "cobertura",  c("q", "dual")],
    gamma = d[d$bloco == "capacidade", c("j", "dual")],
    mu    = d[d$bloco %in% c("liga_o", "liga_d"), c("bloco", "q", "j", "k", "dual")]
  )
}
```

**Um detalhe conceitual que vale uma frase no relatório e provavelmente uma pergunta na
arguição:** no LP restrito, a restrição de cardinalidade $\sum_j y_j \le p$ está com todas as
variáveis fixas e portanto tem dual **zero ou indefinido**. Isso não é falha da extração — é
consequência de a pergunta "quanto vale um vertiporto a mais?" não fazer sentido depois de a
rede já ter sido escolhida. **$\pi$ não vem do LP restrito. Vem do LP relaxado, e a leitura
econômica vem da diferença finita de T33.** Quem reportar um $\pi$ tirado do LP restrito está
reportando um zero e chamando de preço-sombra.

#### 2.3 $\pi$ — e a verificação numérica da identidade

$\pi$ é o dual de $\sum_j y_j \le p$. Unidade: **pax·min/dia por vertiporto** — a FO é
$\sum f_q \Delta_{qjk} w_{qjk}$, com $f_q$ em viagens/dia e $\Delta$ em minutos, e $\pi$ é
$\partial Z/\partial p$.

A identidade a verificar:

$$\pi_{LP}(p) \;\approx\; Z^*_{LP}(p+1) - Z^*_{LP}(p) \qquad\text{(exata, para o LP)}$$
$$\pi_{LP}(p) \;\ge\; Z^*_{IP}(p+1) - Z^*_{IP}(p) \quad\text{?}\qquad\text{(a verificar — e é o interessante)}$$

A primeira é teorema: $Z_{LP}(p)$ é côncava e linear por partes em $p$, e $\pi$ é a inclinação
do segmento. **Verifique-a numericamente mesmo assim** — é o teste que pega erro de sinal, de
escala e de mapeamento de linhas, os três erros mais comuns desta tarefa.

A segunda é a pergunta boa. Se a curva inteira tiver trecho convexo, existe $p$ em que
$Z_{IP}(p+1)-Z_{IP}(p) > Z_{IP}(p)-Z_{IP}(p-1)$ — marginal **crescente**, o que nenhuma função
côncava faz. Reporte esse $p$: ele é a assinatura numérica da massa crítica lida pela derivada.

```r
# app/R/verificar_pi.R
# @produz    outputs/verificacao_pi.rds
# @consome   outputs/curva_implantacao.rds
# @tarefa    tarefa:T31

#' Confronta o dual da cardinalidade com a diferença finita da curva Z*(p).
#'
#' É o teste de sanidade mais barato de toda a T31: se pi e a diferença finita
#' do LP não baterem, o erro está na extração do dual, e todo o resto da seção
#' econômica estaria sendo escrito sobre um número errado.
#'
#' @param arcos data frame de arcos viáveis
#' @param candidatos vetor de ids
#' @param ps vetor de valores de p a testar
#' @return data frame com p, pi_lp, dif_lp, dif_ip e o erro relativo
verificar_pi <- function(arcos, candidatos, ps = 2:20) {
  stopifnot(length(ps) >= 2, all(diff(ps) == 1))

  z <- purrr::map_dfr(ps, function(p) {
    m  <- montar_modelo(arcos, candidatos, p = p, forma = "desagregada")
    lp <- resolver(m, inteiro = FALSE)
    ip <- resolver(m, inteiro = TRUE)
    data.frame(p = p, z_lp = lp$z, z_ip = ip$z,
               pi_lp = nomear_duais(m, lp)$pi)
  })

  z$dif_lp <- c(diff(z$z_lp), NA_real_)
  z$dif_ip <- c(diff(z$z_ip), NA_real_)
  z$erro_rel <- abs(z$pi_lp - z$dif_lp) / pmax(abs(z$dif_lp), 1e-9)
  z
}
```

**Critério de aceitação:** `erro_rel` desprezível em todo `p` onde o LP não estiver degenerado.
Onde não for, olhe caso a caso antes de escrever qualquer coisa — ver a armadilha sobre
degenerescência.

#### 2.4 $\alpha_q$ — o ranking de corredores

$\alpha_q$ é o dual de $\sum_{(j,k)\in P_q} w_{qjk} \le 1$: o valor de servir integralmente o
par $q$, em **pax·min/dia**. Ordenado decrescentemente, é o **ranking de corredores
prioritários** — e essa é a saída de T31 que mais interessa a quem lê o relatório sem saber PL.

No LP restrito há um atalho que serve de conferência: com $y$ fixo, o problema separa por $q$, e
o ótimo escolhe o melhor arco disponível. Logo

$$\alpha_q \;=\; \max\{\, f_q\Delta_{qjk} \;:\; (j,k)\in P_q,\ y_j = y_k = 1 \,\}$$

(e $0$ se nenhum arco de $P_q$ estiver com as duas pontas abertas). **Calcule esse máximo em
`dplyr` e compare com o dual extraído.** Baterem é a confirmação de que o mapa de linhas está
certo. Não baterem, quando há capacidade ativa, é esperado — a capacidade reduz $\alpha_q$
abaixo do máximo, e a diferença é justamente o que a capacidade custa naquele corredor.

Reporte **duas listas, não uma**:

- **Corredores servidos, ordenados por $\alpha_q$** — onde o benefício efetivamente aparece.
- **Corredores de alto $f_q\Delta$ com $\alpha_q = 0$** — demanda grande que a rede escolhida
  não atende. Esta segunda lista é a mais interessante do relatório: ela é a agenda da próxima
  fase de expansão, dita pelo modelo.

#### 2.5 $\gamma_j$ — o preço-sombra da capacidade

Só existe se a extensão de capacidade estiver ativa:

$$\sum_q \sum_k f_q\,(w_{qjk} + w_{qkj}) \;\le\; C_j\, y_j \qquad (\gamma_j)$$

$\gamma_j$ é a economia adicional de tempo-passageiro obtida por **uma unidade a mais de
capacidade** no vertiporto $j$. Unidade: pax·min/dia por (unidade de $C_j$). Se $C_j$ estiver em
movimentos/hora derivados do número de FATOs, $\gamma_j$ multiplicado pelos movimentos que um
FATO acrescenta é **a justificativa econômica de construir um FATO adicional em $j$**.

Monetizado pelo valor do tempo:

$$\gamma_j^{\,\text{R\$}} \;=\; \gamma_j \;[\text{pax}\cdot\text{min/dia}] \times \frac{\text{VoT}\,[\text{R\$/h}]}{60} \times \text{dias úteis/ano}$$

**Escreva os três fatores explicitamente e cite a decisão de onde vem o VoT.** Um número em reais
sem a cadeia de conversão visível é o tipo de número que a arguição pede para reconstruir no
quadro. E declare a hipótese embutida: isso é benefício de tempo, não receita, e não desconta
custo operacional nem tarifa.

#### 2.6 Frases-modelo de interpretação

Estas são gabaritos, não texto pronto — troquem os colchetes pelos números medidos, e **cortem
qualquer uma cuja lógica vocês não conseguirem defender em voz alta**.

**Sobre $\pi$:**

> *"Em $p = [\,\cdot\,]$, um vertiporto adicional acrescenta $[\,\cdot\,]$ pax·min/dia de
> economia de tempo — equivalente a $[\,\cdot\,]$ horas de deslocamento poupadas por dia útil, ou
> R\$ $[\,\cdot\,]$/ano ao valor do tempo de `decisao:D__`. Esse é o teto de benefício contra o
> qual o custo de implantar um vertiporto deve ser comparado; abaixo de $p = [\,\cdot\,]$ o
> marginal ainda está subindo, o que significa que interromper a implantação nessa faixa
> desperdiça o investimento já feito."*

**Sobre $\alpha_q$:**

> *"O corredor $[o] \to [d]$ vale $[\,\cdot\,]$ pax·min/dia na rede escolhida — $[\,\cdot\,]$ vezes
> o corredor mediano. Se a operação tiver de começar por um subconjunto de rotas, é por ele.
> Em contraste, o par $[o'] \to [d']$ tem $f_q\Delta$ entre os dez maiores e $\alpha_q = 0$: a
> rede de $p = [\,\cdot\,]$ não o atende, e ele é o primeiro candidato a justificar o vertiporto
> $[\,\cdot\,]$ na fase seguinte."*

**Sobre $\gamma_j$:**

> *"A capacidade de $[j]$ está ativa: $\gamma_j = [\,\cdot\,]$. Cada FATO adicional em $[j]$
> libera $[\,\cdot\,]$ pax·min/dia, ou R\$ $[\,\cdot\,]$/ano. Enquanto o custo anualizado de um
> FATO ficar abaixo disso, ampliar $[j]$ domina abrir um vertiporto novo — o que é uma
> recomendação de investimento diferente da que o modelo daria olhando só $\pi$."*

**Sobre o que o dual NÃO diz** — e esta frase precisa estar no relatório:

> *"Todos os preços-sombra acima são locais e válidos apenas dentro do intervalo em que a base
> ótima não muda. Não são elasticidades, não valem para variações grandes, e em um problema
> degenerado como este não são necessariamente únicos. A leitura de longo alcance é a curva de
> implantação da §[\,\cdot\,], não o dual."*

---

### 3. T32 — Análise de sensibilidade

#### 3.1 O que cada varredura mede

Não varra por varrer. Cada parâmetro responde a uma pergunta de decisão, e é a pergunta que vai
para o relatório:

**$\bar t$ — raio máximo de acesso (10, 15, 20, 30 min).** Mede **quanto a UAM depende do
first/last mile**. Se $Z^*$ despencar entre 20 e 15 min, a proposta de valor está inteiramente
condicionada a acesso terrestre rápido ao vertiporto, e a recomendação de política muda: o
investimento crítico não é o vertiporto, é a conexão até ele. Se $Z^*$ for quase plano, a rede é
robusta ao acesso e o gargalo está noutro lugar.

**$\theta$ — economia mínima aceita (0, 10, 20, 30 min).** Mede **a fragilidade da proposta de
valor**. $\theta = 0$ aceita qualquer par em que a UAM não seja pior que o carro; $\theta = 30$
exige meia hora de ganho. A queda de $Z^*$ ao longo dessa varredura é a resposta a *"e se o
usuário só migrar quando o ganho for grande?"* — que é a pergunta que substitui o logit que a
`decisao:D03` descartou. **Diga isso explicitamente:** a varredura de $\theta$ é o substituto
declarado da elasticidade de demanda, e é uma resposta mais fraca que um logit calibrado, e
é honesto reconhecê-lo.

**VoT — valor do tempo.** Não muda a solução do P1 na forma em minutos (é multiplicador escalar
da FO), mas **muda tudo que for reportado em reais**. Varra ±50% e mostre a faixa. Se alguma
recomendação monetária mudar de sinal dentro da faixa, ela não é uma recomendação.

**$C_j$ — capacidade.** Se a extensão estiver ativa: onde a capacidade morde, a solução deixa de
concentrar e passa a espalhar. É a varredura que responde *"quantos FATOs o sistema precisa?"*.

**$f$ — fator de congestionamento (G05).** O parâmetro mais incerto de todos. Ele multiplica
$T^{\text{ter}}_q$, portanto entra em $\Delta$ linearmente, portanto entra na FO linearmente —
**e também muda $P_q$**, porque $\Delta \ge \theta$ é filtro. Ou seja: ele altera o valor *e* a
estrutura do problema. Varra pelo menos $f = 1$ (free-flow, conservador contra a UAM) e o valor
calibrado, e reporte a diferença de $Z^*$ **e** a diferença no conjunto escolhido.

#### 3.2 A grade, e quanto ela custa

A grade principal é $\bar t \times \theta = 4 \times 4 = 16$ instâncias. Somadas as varreduras
unidimensionais de VoT, $C_j$ e $f$, e a curva de T33 (25 × 2), o pacote inteiro fica na casa de
**80 a 120 resoluções**. Com as poucas binárias que o P1 tem, isso é viável — mas **meça uma
rodada antes de disparar a grade**, e se o tempo por rodada for de minutos, planeje a grade para
rodar de madrugada, não às 23h de 14/09.

O ponto de atenção não é o solver: é o **pré-processamento**. Mudar $\bar t$ ou $\theta$ muda
$P_q$, portanto muda `arcos`, portanto obriga a reconstruir o modelo inteiro. O custo dominante
da grade é montar 16 modelos, não resolver 16 modelos. Estruture assim:

```r
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
```

O caso `nrow(a) == 0` não é defensivo por educação: com $\bar t = 10$ e $\theta = 30$
simultâneos, é perfeitamente possível que **nenhum arco sobreviva**. Isso é um resultado, não um
erro — e a célula vazia no canto do mapa de calor é informativa. Se o código quebrar ali, a
varredura morre no meio e você perde a grade inteira.

#### 3.3 A análise de estabilidade da solução — e por que ela vale mais que a do valor

Quase todo grupo vai reportar $Z^*(\bar t)$ e $Z^*(\theta)$. Poucos vão reportar **qual solução**
sobrevive à varredura. É essa a análise que produz a recomendação defensável.

A ideia: para cada candidato $j$, conte em quantas das $N$ células da grade ele foi escolhido.

- **Núcleo robusto** — escolhido em **todas** as células. Este subconjunto é a recomendação mais
  forte do trabalho: *"estes vertiportos aparecem no ótimo sob qualquer combinação de limiares
  que testamos; a decisão de construí-los não depende de acertar $\bar t$ nem $\theta$."*
- **Periferia de decisão** — escolhido em algumas. São os candidatos cuja inclusão depende de
  hipótese, e a hipótese precisa estar nomeada ao lado de cada um.
- **Nunca escolhido** — e vale olhar por quê: candidato dominado por outro próximo? Sem demanda
  no raio? A resposta costuma render uma frase boa sobre a geografia da cidade.

```r
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
```

Acrescente também o **índice de Jaccard** entre a solução de cada célula e a solução do cenário
central: $J = |A \cap B| / |A \cup B|$. Ele dá, num número por célula, quanto a solução se
deslocou — e serve de segundo mapa de calor sobreposto ao de $Z^*$. Uma célula com $Z^*$ parecido
e Jaccard baixo é o achado mais interessante possível: **mesmo benefício, rede completamente
diferente**, o que significa que o valor ótimo é insensível mas a decisão não é. Se isso
aparecer, é seção própria do relatório.

---

### 4. T33 — Curva de implantação e o teste do S

#### 4.1 O que se roda

$p = 1,\dots,25$, para **dois modelos no mesmo dado**:

1. **Bilateral (P1)** — o modelo do trabalho.
2. **Unilateral (baseline do G07)** — MCLP em que a zona está coberta se houver vertiporto
   perto, sem exigir a ponta de destino.

As duas curvas **sobrepostas no mesmo eixo** são a figura central do trabalho. É ela que sustenta
a resposta que o §4.4 do enunciado pede: *a partir de quantos vertiportos o retorno deixa de
compensar?*

**Cuidado com a comparabilidade das duas curvas.** Elas só podem ir no mesmo eixo se a unidade da
FO for a mesma. Se o baseline unilateral maximizar viagens/dia cobertas e o bilateral maximizar
pax·min/dia, os eixos são incomparáveis e a figura mente. Duas saídas: (a) rodar o unilateral
com a mesma FO em pax·min, usando como $\Delta$ o melhor $\Delta_{qjk}$ com apenas a ponta de
origem exigida; ou (b) normalizar as duas por seus respectivos $Z^*(25)$ e plotar em percentual,
declarando a normalização na legenda. **A opção (a) é mais defensável; a (b) é aceitável se
declarada.** Registre qual foi como decisão.

```r
# app/R/curva_implantacao.R
# @produz    outputs/curva_implantacao.rds
# @consome   outputs/arcos.rds
# @tarefa    tarefa:T33

#' Levanta Z*(p) para p = 1..p_max, em um dos dois modelos.
#'
#' Devolve também os abertos de cada p porque a curva sozinha não responde à
#' pergunta que o leitor faz em seguida — "e quais são?" — e porque a sequência
#' de conjuntos ao longo de p diz se a implantação é aninhada (cada passo
#' acrescenta sem remover) ou não. Ela não precisa ser, e quando não é, isso é
#' uma restrição prática de faseamento que o relatório precisa mencionar.
#'
#' @param arcos data frame de arcos viáveis
#' @param candidatos vetor de ids
#' @param p_max maior orçamento a testar
#' @param montar função montadora: `montar_modelo` ou `montar_mclp_unilateral`
#' @return data frame com p, z, segundos, gap, abertos
curva_implantacao <- function(arcos, candidatos, p_max = 25, montar = montar_modelo) {
  stopifnot(p_max >= 2, is.function(montar))

  purrr::map_dfr(seq_len(p_max), function(p) {
    m   <- montar(arcos, candidatos, p = p)
    sol <- resolver(m, inteiro = TRUE)
    data.frame(p = p, z = sol$z, segundos = sol$segundos, status = sol$status,
               abertos = I(list(m$idx$y$id[sol$x[m$idx$y$col] > 0.5])))
  })
}
```

#### 4.2 A previsão teórica, escrita como previsão

O relatório deve apresentar isto **antes** dos resultados, como hipótese, e depois confrontar.
Essa ordem não é estilo: é o que distingue um achado de uma racionalização.

> **Previsão.** Com cobertura unilateral a FO é submodular, logo $Z^*(p)$ é côncava desde
> $p=1$ — retornos decrescentes desde o primeiro vertiporto. Com cobertura bilateral,
> $Z^*(1) = 0$, porque um vertiporto sozinho não serve par nenhum; e o benefício é superaditivo
> no início, porque cada vertiporto novo se combina com **todos** os já abertos. Logo a curva é
> **convexa e depois côncava — um S**.

$Z^*(1) = 0$ é a primeira coisa a verificar, e ela é verificação de **corretude do modelo**, não
de teoria: se o bilateral devolver $Z^*(1) > 0$, existe arco com $j = k$ em $P_q$, ou uma das
duas restrições de ligação não está entrando. **Coloque isso como asserção no pipeline.**

#### 4.3 Detectar a inflexão numericamente

O ponto de inflexão é onde a **segunda diferença** muda de sinal:

$$\Delta^2 Z^*(p) \;=\; Z^*(p+1) - 2Z^*(p) + Z^*(p-1)$$

Convexo: $\Delta^2 > 0$. Côncavo: $\Delta^2 < 0$. A inflexão é a última troca de sinal de $+$
para $-$.

```r
#' Testa o formato em S da curva de implantação.
#'
#' Reporta a inflexão e a saturação, mas devolve também o vetor inteiro de
#' segundas diferenças: um S de verdade tem um bloco contíguo de sinal positivo,
#' e não um sinal positivo isolado no meio do ruído. A distinção entre as duas
#' coisas é o que separa achado de artefato, e ela não cabe num único número.
#'
#' @param curva saída de `curva_implantacao()`
#' @param tol tolerância absoluta para considerar a segunda diferença nula
#' @param frac_sat fração de Z*(p_max) que define a saturação
#' @return lista com d2, p_inflexao, p_massa_critica, p_saturacao e o veredito
testar_s <- function(curva, tol = 1e-6, frac_sat = 0.95) {
  stopifnot(all(c("p", "z") %in% names(curva)), nrow(curva) >= 5)
  z  <- curva$z[order(curva$p)]
  d1 <- diff(z)
  d2 <- diff(d1)

  sinal <- ifelse(d2 >  tol,  1L, ifelse(d2 < -tol, -1L, 0L))
  pos   <- which(sinal ==  1L)
  neg   <- which(sinal == -1L)

  list(
    d2              = d2,
    marginal        = d1,
    p_massa_critica = if (any(z > tol)) curva$p[which(z > tol)[1]] else NA_integer_,
    p_inflexao      = if (length(pos) && length(neg) && min(pos) < max(neg))
                        curva$p[max(pos[pos < max(neg)]) + 1L] else NA_integer_,
    p_saturacao     = curva$p[which(z >= frac_sat * max(z))[1]],
    tem_bloco_convexo = length(pos) > 0 && all(diff(pos) == 1),
    veredito        = if (length(pos) == 0) "sem trecho convexo — curva côncava"
                      else if (all(diff(pos) == 1)) "S consistente"
                      else "convexidade não contígua — investigar antes de afirmar S"
  )
}
```

**Três parâmetros dessa função são convenção e precisam estar declarados no relatório:** `tol`
(o que conta como segunda diferença nula), `frac_sat` (95% do máximo como definição de
saturação) e `p_max` (25). Nenhum dos três é dado; os três são escolha do grupo.

#### 4.4 A leitura em linguagem de decisão — as duas metades

A curva em S dá uma resposta com **duas partes**, e é isso que nenhum modelo unilateral produz:

**Primeira metade — a massa crítica.** *"Abaixo de $p = [\,\cdot\,]$ a rede não entrega benefício
material: os vertiportos existem mas não formam pares úteis. Um programa de implantação que
pare nessa faixa desperdiça integralmente o investimento — não entrega um sistema pequeno,
entrega um sistema que não funciona."* Este é o argumento contra o projeto-piloto de dois ou três
vertiportos, e é uma recomendação com consequência real de política pública.

**Segunda metade — a saturação.** *"Acima de $p = [\,\cdot\,]$ o marginal cai para
$[\,\cdot\,]$ pax·min/dia por vertiporto, abaixo do custo de implantação estimado; a partir daí
os vertiportos adicionais servem pares cada vez mais marginais."*

E a frase que amarra as duas: *"a faixa recomendada é $[\,p_{\min}, p_{\text{sat}}\,]$, e a
existência de um piso — não só de um teto — é consequência direta de modelar a cobertura como
bilateral. Um MCLP unilateral rodado no mesmo dado (curva tracejada da figura) só produz o
teto."*

#### 4.5 E se o S não aparecer

**Este é o cenário para o qual o grupo precisa estar preparado, e ele não é fracasso.** O
critério de excelência do enunciado inclui literalmente *"mostra o que não funcionou, e por
quê"*. Uma curva côncava reportada com diagnóstico honesto vale mais que um S forçado.

O mecanismo pelo qual o S desaparece é conhecido e tem que estar escrito:

**Se $P_q$ for muito denso, o S some.** A superaditividade vem da escassez de pares viáveis: se
cada par OD só puder ser servido por poucas combinações $(j,k)$, abrir o segundo vertiporto certo
vale muito mais que o primeiro. Mas se $|P_q|$ for grande — dezenas de combinações viáveis por
par — então quase qualquer par de vertiportos abertos já serve muitos $q$, o efeito de rede
satura quase imediatamente, e a curva volta a parecer côncava a partir de $p = 2$ ou $3$. O
trecho convexo continua existindo em teoria (entre $p=1$ e $p=2$), mas é curto demais para ser
visível na figura.

**Como diagnosticar, e o número a reportar:** a distribuição de $|P_q|$. Reporte média, mediana e
o percentil 90. Se a mediana estiver na casa das dezenas, escreva:

> *"O formato em S previsto teoricamente não se materializa nesta instância. A razão é a
> densidade de $P_q$: com $|P_q|$ mediano de $[\,\cdot\,]$, cada par OD elegível é servível por
> muitas combinações de vertiportos, e a rede atinge conectividade útil já em $p = [\,\cdot\,]$.
> A superaditividade existe — $Z^*(1) = 0$ e $Z^*(2) > 0$ é a sua manifestação mínima — mas se
> concentra num intervalo curto demais para produzir um trecho convexo mensurável. A previsão
> teórica de §[\,\cdot\,] é correta em mecanismo e insuficiente em magnitude para esta
> instância."*

E acrescente a verificação que fecha o argumento: **rode a curva com $\bar t$ apertado** (10 min),
que reduz $|P_q|$, e mostre se o S reaparece. Se reaparecer, você não só explicou a ausência —
demonstrou o mecanismo. Essa é uma seção de relatório melhor do que o S ter aparecido de
primeira.

---

### 5. T34 — A extensão

#### 5.0 Como a extensão convive com o congelamento

A extensão é **variante**, não substituição. Operacionalmente:

- A baseline congelada em 16/09 continua sendo a solução recomendada do trabalho.
- A extensão roda como `experimento` próprio, com o mesmo dado e os mesmos $p$, $\bar t$,
  $\theta$.
- O relatório apresenta as duas e discute a diferença. Se a extensão mudar a recomendação, isso é
  o resultado da seção — não motivo para reescrever a baseline.

#### 5.1 Escolham UMA

O aviso é do próprio YAML da T34 e vale repetir: **uma extensão bem feita vale mais que duas pela
metade.** "Pela metade" tem sintomas identificáveis: formulação escrita mas não rodada; rodada
mas sem varredura do parâmetro novo; varrida mas sem leitura de decisão. Se qualquer um desses
faltar, a extensão não está pronta e é melhor ter uma só.

Critério para escolher: **massa crítica** amarra melhor com a narrativa do trabalho (é a lacuna
L2 da revisão, é o mesmo fenômeno da curva em S visto por outro ângulo). **Equidade** amarra
melhor com o contexto de São Paulo e com a crítica política que o painel comparativo quase
certamente vai levantar. As duas são defensáveis; escolham por qual vocês conseguem discutir
melhor, não por qual é mais fácil de codar.

#### 5.2 Extensão A — massa crítica por vertiporto

$$\sum_{q}\sum_{k} f_q\,(w_{qjk} + w_{qkj}) \;\ge\; m\, y_j \qquad \forall j \in J$$

**O que ela diz:** um vertiporto só abre se movimentar pelo menos $m$ passageiros/dia. Abaixo
disso, não abre — porque um vertiporto com meia dúzia de movimentos diários não tem viabilidade
operacional, e um modelo que o abre está otimizando um número que a realidade não paga.

**O que muda no resultado, e o que verificar:**

- A solução **concentra**. Candidatos periféricos de baixa demanda deixam de ser viáveis.
- Pode haver $p$ em que o modelo **não usa todo o orçamento** — abrir o $p$-ésimo vertiporto
  violaria a massa crítica dele. Verifique `sum(y) < p` e reporte: é um resultado forte, porque
  significa que o número de vertiportos economicamente viáveis é menor que o orçamento.
- **A curva de implantação muda de forma.** Rode a curva de novo com a extensão e sobreponha às
  duas anteriores: a figura vira três curvas e fica mais rica.

**A armadilha específica desta extensão:** a restrição é do tipo "se abrir, então movimente", e
$m\,y_j$ com $y_j = 0$ dá $0 \ge 0$, que é sempre viável — está correto. Mas confira o **sinal**:
com `lhs`/`rhs` do HiGHS, isso é linha com `lhs = 0` e `rhs = Inf` sobre
$\sum f_q(w+w) - m\,y_j$. Errar o sentido produz um modelo que força movimento **mesmo em
vertiporto fechado**, o que é infactível e o solver reporta `INFEASIBLE` — sintoma fácil. O
sintoma difícil é errar para o lado frouxo e a restrição virar inócua: **teste com $m$ absurdo
(maior que a demanda total) e confirme que a solução vira $y = 0$ e $Z = 0$.**

**Como reportar:** varra $m$ (pelo menos quatro valores, incluindo $m=0$ que reproduz a baseline)
e plote $Z^*(m)$ junto com o número de vertiportos efetivamente abertos. A leitura: *"exigir
throughput mínimo de $m$ passageiros/dia custa $[\,\cdot\,]$% do benefício e reduz a rede
viável de $[\,\cdot\,]$ para $[\,\cdot\,]$ vertiportos"*.

#### 5.3 Extensão B — equidade

$$\sum_{j \in J_{\text{periferia}}} y_j \;\ge\; \lceil \rho\, p \rceil$$

**O que ela diz:** pelo menos uma fração $\rho$ dos vertiportos fica fora do centro expandido.
Responde à crítica política óbvia — e correta — de que UAM em São Paulo tende a virar
infraestrutura do quadrilátero Itaim–Faria Lima. A revisão registra em L6 que a literatura trata
equidade quase sempre *ex post*; internalizá-la como restrição é a diferença.

**A decisão difícil não é a restrição, é `J_periferia`.** Ela é uma **definição**, e definição é
decisão registrada com alternativas descartadas. Opções, em ordem crescente de defensabilidade:

1. Distância ao marco zero acima de um limiar — simples, e arbitrária.
2. Fora das subprefeituras centrais — usa recorte administrativo existente, mas não tem relação
   com renda.
3. Abaixo de um percentil de renda média domiciliar da macrozona, na própria OD — **usa dado do
   projeto, alinha equidade com a variável que a `decisao:D03` usou para filtrar demanda, e é a
   que se defende melhor**. A ironia é produtiva e vale ser dita no relatório: o filtro de
   captura seleciona renda alta, e a restrição de equidade puxa na direção oposta. Explicitar
   essa tensão é melhor que escondê-la.

**Não use "periferia" como palavra sem definição operacional em lugar nenhum do relatório.** Ela
é politicamente carregada e a arguição vai perguntar.

**O que muda no resultado:** $Z^*$ cai — necessariamente, porque a restrição só pode restringir.
A pergunta interessante é **quanto**, e a resposta é o **preço da equidade**:

$$\text{preço da equidade}(\rho) \;=\; \frac{Z^*(\rho = 0) - Z^*(\rho)}{Z^*(\rho = 0)}$$

**Como reportar:** varra $\rho \in \{0; 0{,}2; 0{,}3; 0{,}5\}$ e plote a fronteira
eficiência × equidade — $Z^*$ no eixo vertical, $\rho$ no horizontal. É uma fronteira de
$\varepsilon$-restrição, e nomeá-la assim liga a extensão à teoria de otimização multiobjetivo
sem precisar implementar multiobjetivo. Acrescente, em cada ponto, quantas viagens de macrozonas
de renda baixa passam a ser servidas: *"a $\rho = 0{,}3$, o sistema perde $[\,\cdot\,]$% de
benefício total e passa a atender $[\,\cdot\,]$ viagens/dia originadas fora do centro expandido"*.
Custo e contrapartida na mesma frase — é assim que se defende uma restrição de equidade.

---

### 6. Os indicadores comuns a todos os grupos (§6.3)

Estes quatro são exigidos de **todos os grupos** para o painel comparativo final do §6.3. Eles
não são opcionais e não são "o que sobrou": são a linha do grupo na tabela que todo mundo vai
olhar lado a lado.

| Indicador | O que é | Cuidado |
| --- | --- | --- |
| **Número de vertiportos e localização** | $p$ e a lista de $j$ com $y_j = 1$, com nome e coordenada | Nome do sítio, não só o id interno |
| **Demanda diária atendida** e **participação na demanda capturável** | viagens/dia servidas ÷ viagens/dia em $Q$ | O denominador é a **capturável** (saída de G03), não a demanda total da cidade |
| **Benefício na métrica própria, com unidade explicitada** | $Z^*$ em **pax·min/dia** | A unidade é exigência textual. Escreva-a em toda menção |
| **Desempenho computacional** | $Z^*$, tamanho da instância, tempo de solução | Tamanho = linhas × colunas × não-zeros **e** $\vert Q\vert$, $\vert J\vert$, $\Sigma_q\vert P_q\vert$ |

O denominador do segundo indicador é onde os grupos vão divergir mais no painel, e é bom estar
preparado: uma participação de 80% sobre uma demanda capturável estreita e uma de 20% sobre uma
capturável larga podem representar o mesmo número absoluto de viagens. **Reporte sempre o
absoluto ao lado do percentual**, e diga qual filtro define o denominador.

```r
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
```

O argumento `experimento` é obrigatório de propósito: **a tabela de indicadores não existe
desacoplada do nó de experimento que a gerou.** Isso é o que responde, no painel, à pergunta
"de qual rodada é esse número?".

---

### 7. Especificação das figuras do relatório

Toda figura sai de `app/outputs/fig/<secao>_<slug>.png` (convenções §4.3) e **toda legenda cita o
id do experimento** que a gerou. Sem isso, a pergunta "qual script gerou o mapa da página 12" —
uma das quatro que o grafo tem que responder (G00 §7) — não tem resposta pela figura.

**Regras que valem para todas:**

- **Paleta segura para daltonismo.** Okabe–Ito para categorias; `viridis` para escalas
  contínuas. **Nada de arco-íris** — a escala de matiz não tem ordem perceptual e distorce
  leitura de mapa de calor.
- **Unidade no rótulo do eixo, sempre.** "Z\* (pax·min/dia)", não "Z\*".
- **Os parâmetros fixos vão na legenda**, não no corpo do texto: quem olha a figura precisa saber
  sob que $\bar t$, $\theta$, $p$ e VoT ela foi produzida.
- **Sem título dentro da imagem.** O título é a legenda do documento; título duplicado é ruído.
- **Escala de cinza legível.** Se a figura só funcionar em cor, ela não funciona impressa.

| Fig | Conteúdo | Eixo X | Eixo Y | Cores | A legenda precisa dizer |
| --- | --- | --- | --- | --- | --- |
| **F1** | **Curva de implantação, bilateral × unilateral** — a figura central | $p$ (nº de vertiportos), inteiro, 1–25 | $Z^*$ (pax·min/dia) | duas séries: bilateral sólida, unilateral tracejada; anotar $p_{\min}$ e $p_{\text{sat}}$ com linha vertical | $\bar t$, $\theta$, VoT, se há normalização, e os dois `experimento:` |
| **F2** | Segunda diferença de $Z^*(p)$ | $p$ | $\Delta^2 Z^*$ (pax·min/dia/vertiporto²) | barras; positivas e negativas em cores distintas; linha em zero | a `tol` usada e onde está a inflexão |
| **F3** | Gap de integralidade por formulação | forma (categórica) | gap relativo (%) | barras; anotar $Z_{LP}$ e $Z_{IP}$ sobre cada uma | $p$ fixo, e o nº de linhas de cada forma |
| **F4** | $Z^*(\bar t)$ e $Z^*(\theta)$ | o parâmetro (min) | $Z^*$ (pax·min/dia) | dois painéis lado a lado (`facet`), eixo Y compartilhado | o valor fixo do outro parâmetro, e $p$ |
| **F5** | Mapa de calor $\bar t \times \theta$ | $\bar t$ (min) | $\theta$ (min) | `viridis`; célula vazia em cinza explícito e nomeada na legenda | $p$, e que o valor da célula é $Z^*$ |
| **F6** | Estabilidade: frequência de seleção | mapa de SP | — | ponto por candidato; cor = frequência (`viridis`); núcleo com contorno grosso | quantos cenários compõem a frequência, e o CRS |
| **F7** | Solução recomendada | mapa de SP | — | vertiportos abertos; arcos servidos com espessura ∝ $f_q$; macrozonas em cinza claro ao fundo | $p$, $\bar t$, $\theta$, o `experimento:`, e "© OpenStreetMap contributors" se a base for OSM |
| **F8** | Ranking de corredores por $\alpha_q$ | $\alpha_q$ (pax·min/dia) | os 15 corredores no topo (categórica, ordenada) | *lollipop*; servidos e não-servidos em cores distintas | que $\alpha_q$ vem do LP restrito, e sob qual solução |
| **F9** | Extensão: fronteira do parâmetro novo | $m$ ou $\rho$ | $Z^*$ (pax·min/dia) | linha; eixo secundário ou segundo painel com nº de vertiportos abertos | o que é perdido e o que é ganho, com unidade nos dois |

**F1 e F7 são as duas que o leitor vai olhar primeiro.** Se sobrar tempo para caprichar em duas,
são essas.

---

## Critério de pronto

**T30 — relaxação**
- [ ] `outputs/tab_relaxacao.rds` com as três formas, e `linhas`, `colunas`, `nao_zeros`,
      `z_ip`, `z_lp`, `gap_abs`, `gap_rel`, `y_frac_lp`, tempos.
- [ ] As duas instâncias-brinquedo de §1.3 rodam e reproduzem 0 / 0,5 e 1 / 2.
- [ ] O big-M da forma agregada é $|Q_{jk}|$, não $|Q|$ — conferido no código.
- [ ] A explicação de por que a bilateralidade quebra a quase-integralidade está escrita em
      prosa, com o exemplo mínimo, e cabe em meia página.

**T31 — dual**
- [ ] O campo de duais do retorno do `highs` está confirmado por `str()` e registrado em nota.
- [ ] `nomear_duais()` devolve $\pi$, $\alpha$ e (se houver) $\gamma$ com os nomes certos, e
      `nrow(modelo$linhas) == length(sol$duais)`.
- [ ] `verificar_pi()` rodou e `erro_rel` é desprezível, ou toda exceção está explicada.
- [ ] $\alpha_q$ do LP restrito bate com o máximo calculado em `dplyr` (sem capacidade ativa).
- [ ] As duas listas de corredores existem: servidos, e alto-$f\Delta$-não-servidos.
- [ ] Existe pelo menos uma frase de interpretação **por dual**, escrita por uma pessoa, em
      linguagem de decisão, e as três estão no relatório.
- [ ] A ressalva sobre validade local e não-unicidade dos duais está escrita.

**T32 — sensibilidade**
- [ ] A grade $4\times4$ rodou inteira, inclusive as células vazias.
- [ ] Curvas $Z^*(\bar t)$ e $Z^*(\theta)$, e o mapa de calor, existem como figuras.
- [ ] `estabilidade()` rodou; o **núcleo robusto** está identificado e nomeado.
- [ ] Jaccard contra o cenário central calculado para toda célula.
- [ ] VoT e `fator_congestionamento` varridos, com a faixa reportada.

**T33 — curva**
- [ ] `Z*(1) == 0` no bilateral — asserção no pipeline, não conferência visual.
- [ ] As duas curvas existem no mesmo dado, com unidades comparáveis (ou a normalização
      declarada e registrada como decisão).
- [ ] `testar_s()` rodou; `p_massa_critica`, `p_inflexao` e `p_saturacao` estão registrados.
- [ ] `tol`, `frac_sat` e `p_max` estão declarados no relatório como convenções do grupo.
- [ ] Se o S **não** apareceu: a distribuição de $|P_q|$ está reportada, e a rodada com $\bar t$
      apertado foi feita.

**T34 — extensão**
- [ ] **Uma** extensão, formulada, rodada, varrida no parâmetro novo e lida em linguagem de
      decisão. As quatro coisas.
- [ ] A baseline congelada não foi alterada; a extensão é experimento próprio.
- [ ] Para equidade: `J_periferia` tem definição operacional escrita e alternativas descartadas.
- [ ] Para massa crítica: o teste com $m$ absurdo produz $y = 0$.

**Do pacote**
- [ ] `tabela_indicadores()` gerada para a solução recomendada, com o id do experimento.
- [ ] As nove figuras existem em `outputs/fig/`, com legenda citando o `experimento:`.
- [ ] Um nó `experimento` por rodada reportada. Não por rodada feita — por rodada **reportada**.
- [ ] `targets::tar_outdated()` sai vazio. O validador do grafo passa.

---

## Armadilhas conhecidas

**Pedir dual do MIP e receber `NULL` em silêncio.** `resolver()` devolve `duais = NULL` quando
`inteiro = TRUE`, e isso está certo. O erro é a seção econômica ser escrita a partir de um objeto
vazio sem ninguém perceber. `stopifnot(!is.null(sol$duais))` dentro de `nomear_duais()` é a rede.

**Duais sem endereço.** Se `modelo$linhas` não existir ou tiver comprimento diferente do vetor de
duais, você vai interpretar $\alpha_{q_{417}}$ como $\pi$. O sintoma é ausente: o número é
plausível. A defesa é a asserção de comprimento **e** a verificação de $\pi$ contra a diferença
finita — se o mapeamento estiver deslocado, `verificar_pi()` acusa.

**Degenerescência.** Este modelo tem muitos ótimos alternativos: candidatos próximos com tempos
quase iguais, e $\Delta$ com casas decimais que se repetem. Em problema degenerado **o dual não é
único**, e o valor que o HiGHS devolve depende da base final. Consequências práticas: (a) não
escreva "o preço-sombra é X" e sim "um preço-sombra ótimo é X"; (b) rode a mesma instância com
uma permutação da ordem das colunas e veja se o dual muda — se mudar muito, reporte isso, é
informação honesta e a arguição respeita; (c) para $\pi$, prefira a diferença finita, que é
única.

**Reportar $\pi$ tirado do LP restrito.** Com $y$ fixo, a cardinalidade é redundante e o dual é
zero. Alguém vai fazer isso e escrever "o vertiporto marginal não vale nada". Ver §2.2.

**Comparar $Z^*$ entre células da grade sem notar que $|Q|$ mudou.** Apertar $\theta$ não só
reduz $Z^*$: reduz o conjunto de pares elegíveis. Uma queda de $Z^*$ pode ser "cada par vale
menos" ou "há menos pares" — são conclusões diferentes. **Reporte `n_arcos` e `n_pares` ao lado
de `z` em toda célula**; `varrer_limiares()` já devolve o primeiro.

**Cache do `targets` mascarando a varredura.** Se `arcos` for um alvo e o filtro de $\bar t$
acontecer a montante, o `targets` pode servir a mesma versão em cache para células diferentes da
grade. O sintoma é um mapa de calor com linhas idênticas. Por isso `varrer_limiares()` recebe os
arcos **sem filtro** e filtra dentro: a dependência fica explícita.

**Curva não aninhada interpretada como bug.** A solução ótima de $p+1$ não precisa conter a de
$p$. Isso é matemática correta e uma dificuldade prática real de faseamento — merece um
parágrafo no relatório, não um conserto no código. Meça: em quantos passos de $p$ a solução
deixa de ser aninhada?

**Grade rodando na véspera.** 80 a 120 resoluções mais o pré-processamento de cada uma. Meça uma
e multiplique **antes** de 14/09.

**Confundir o denominador da participação.** Demanda atendida ÷ demanda **capturável**, e não ÷
demanda total da RMSP. Os dois números vão aparecer no painel comparativo e a diferença entre
eles é de ordem de grandeza.

**Mudar o modelo depois de 16/09 para "melhorar" um resultado.** É o defeito que a Camada B
existe para pegar, e ele é visível: `tar_outdated()` mostra figura gerada por código que já
mudou. Se algo realmente precisar mudar depois do congelamento, isso é uma decisão registrada que
supersede a `decisao` do congelamento — não um commit silencioso.

**Escrever a interpretação econômica a partir do texto deste guia.** As frases de §2.6 são
gabaritos com lacunas. Uma delas colada com os números trocados e sem a pessoa entender o que
diz é exatamente o que a arguição foi desenhada para encontrar, e o G00 §4.3 avisa disso
explicitamente.

---

## O que registrar

**Decisões**

- **Congelamento da formulação** no commit de 16/09, com o hash.
- **Forma da restrição de ligação** que vai para o modelo final — desagregada, com a tabela de
  §1.5 como justificativa e as outras duas como alternativas descartadas, cada uma com o motivo
  numérico específico (gap medido, linhas, tempo).
- **A leitura da forma "média"** como restrição por arco, divergindo da notação ambígua da
  revisão de literatura §4.
- **Comparabilidade das duas curvas** de T33: mesma FO ou normalização, com a alternativa
  descartada.
- **As convenções de `testar_s()`**: `tol`, `frac_sat`, `p_max = 25`.
- **A grade de sensibilidade** — por que estes quatro valores de $\bar t$ e de $\theta$, e não
  uma grade mais fina.
- **A extensão escolhida** em T34, com a outra registrada como descartada e o motivo (que não
  pode ser "faltou tempo" sozinho — o motivo é qual das duas o grupo consegue defender melhor,
  e por quê).
- **`J_periferia`**, se a extensão for equidade — a definição operacional e as duas alternativas
  descartadas de §5.3.
- **`m`**, se a extensão for massa crítica — de onde vem o throughput mínimo, ou a declaração de
  que é um parâmetro varrido sem âncora empírica. A segunda é aceitável e a primeira é melhor.

**Experimentos** — um nó por rodada reportada, com `parametros`, `obj`, `gap`, `segundos`,
`commit`, e `descricao` contendo **hipótese e conclusão**. O mínimo deste pacote:

| Experimento | Hipótese a escrever antes de rodar |
| --- | --- |
| relaxação, três formas | "a desagregada tem gap menor e custa linhas; a diferença é material" |
| brinquedo A e B | "o solver reproduz 0/0,5 e 1/2 — se não reproduzir, o montador está errado" |
| curva bilateral, $p=1..25$ | "$Z^*(1)=0$ e há trecho convexo" |
| curva unilateral, $p=1..25$ | "côncava desde $p=1$" |
| grade $\bar t \times \theta$ | "existe um núcleo de candidatos escolhido em todas as células" |
| VoT ±50% | "a solução não muda; só a leitura monetária" |
| $f = 1$ vs. calibrado | "free-flow subestima o benefício da UAM e muda a solução" |
| verificação de $\pi$ | "$\pi_{LP}$ = diferença finita do LP em todo $p$ não degenerado" |
| extensão, varredura do parâmetro | conforme §5.2 ou §5.3 |

**Conclusões** — este é o pacote que **produz conclusões**, e cada `conclusao` precisa de aresta
para o `experimento` que a sustenta. A consulta de conclusões sem experimento (G00 §7, quarta
pergunta) é a que mais falha aqui, porque a tentação de escrever a conclusão antes de a rodada
terminar é máxima na semana da prova.

Candidatas a `conclusao` deste pacote — todas com o valor **a preencher**:

- A faixa recomendada de $p$, com o piso e o teto.
- O núcleo robusto de vertiportos.
- O gap de integralidade da formulação escolhida, e o que ele significa para quem usar LP como
  estimativa.
- O valor marginal de um vertiporto adicional na faixa recomendada.
- O ranking dos corredores prioritários.
- O efeito da equidade ou da massa crítica sobre o benefício.
- Se o S não apareceu: a conclusão de que a superaditividade existe mas é curta, com a
  densidade de $|P_q|$ como evidência.

**Pendências** — se `pendencia` de G05 (matriz em *free-flow*) ainda estiver aberta em 09/09,
**ela bloqueia este pacote inteiro**. Registre isso explicitamente e trate como caminho crítico,
não como observação.

**Arquivos** — `arquivo:app-R-resolver`, `arquivo:app-R-duais`, `arquivo:app-R-varredura`,
`arquivo:app-R-curva-implantacao`, `arquivo:app-R-tabela-indicadores`,
`arquivo:app-R-instancias-brinquedo`, com `PRODUZ` para cada saída em `outputs/`.

**Notas em tarefa** — o campo de dual confirmado no `highs`; o tempo medido de uma rodada e a
projeção da grade; a distribuição de $|P_q|$; em quantos passos de $p$ a solução deixa de ser
aninhada; quantas células da grade ficaram vazias.

**Interação de IA** — `critica_humana` não-vazia. Candidatos honestos a crítica **neste** pacote:

- Os números das instâncias-brinquedo de §1.3 são aritmética verificável, mas a afirmação de que
  a razão $Z_{LP}/Z_{IP}$ cresce como $n-1$ vale para aquela família construída, e **não** é uma
  previsão sobre a instância de São Paulo. Confundir as duas coisas seria exatamente o erro que
  este guia manda evitar.
- A previsão do formato em S é teórica e já foi sinalizada como tal no plano de cinco semanas.
  Repetir a previsão não a torna medida.
- A escala de 80 a 120 resoluções é estimativa de contagem, não medição de tempo. O tempo real
  só se conhece depois da primeira rodada.
- O campo `res$solver_msg$row_dual` está marcado `[A CONFIRMAR]` de propósito: a API do pacote
  `highs` já mudou entre versões, e este guia não abriu a versão do `renv.lock`.
- A afirmação de que $\alpha_q$ do LP restrito iguala o máximo de $f_q\Delta_{qjk}$ vale sem
  capacidade ativa; com capacidade, não vale, e o guia diz isso — mas quem ler rápido pode
  aplicar a conferência no caso errado e concluir que o dual está bugado.

---

## Como isso vira relatório

**Seção "Resultados computacionais".** A tabela de indicadores de §6 é a abertura. O mapa da
solução recomendada (F7) e a curva de implantação (F1) são as duas figuras da seção. O
desempenho computacional — linhas, colunas, não-zeros, tempo — vem de `tabela_indicadores()` e
não de memória.

**Seção "Relaxação linear, dual e análise de sensibilidade"** — a seção que o §6.1 do enunciado
nomeia, e a que dá o vínculo com a matéria. Estrutura sugerida:

1. **Relaxação** (T30): a tabela de §1.5, o exemplo mínimo de §1.3, a explicação do mecanismo, e
   a leitura de decisão do gap. Figuras F3.
2. **Dual** (T31): a tabela dos três duais com unidade, a verificação de $\pi$ contra a diferença
   finita, as frases de interpretação, o ranking de corredores. Figura F8.
3. **Sensibilidade** (T32): as curvas, o mapa de calor, e — o trecho de maior valor — a análise
   de estabilidade com o núcleo robusto. Figuras F4, F5, F6.

**Seção "Fronteira de implantação"** (T33): a figura F1 com as duas curvas, a F2 com a segunda
diferença, e a leitura em duas metades de §4.4. Se o S não apareceu, esta seção fica **mais
longa**, não mais curta: o diagnóstico de §4.5 é conteúdo.

**Seção "Limitações do modelo e trabalhos futuros"** recebe de graça: a validade local dos duais,
a não-unicidade sob degenerescência, a ausência de segundo estágio de escolha modal (com a
varredura de $\theta$ como substituto declarado), e a incerteza do `fator_congestionamento`
quantificada pela própria varredura.

**Para o painel comparativo (§6.3)**: a tabela de indicadores, com unidade explicitada e o id do
experimento. Levem também o **núcleo robusto** — quando outro grupo apresentar uma solução
diferente, a pergunta produtiva não é "quem acertou" e sim "o candidato $j$ está no núcleo de
vocês?". Discussão sobre o núcleo é mais informativa que discussão sobre uma solução pontual, e
quem tiver a análise de estabilidade pronta conduz essa conversa.

**Para a arguição**: T31 é a análise sobre a qual a pergunta virá, e o G00 §4.3 já avisou que ela
não se delega. Cada um dos três precisa saber dizer, sem consultar nada, o que é $\pi$, em que
unidade, e por que ela é a inclinação da curva de implantação.
