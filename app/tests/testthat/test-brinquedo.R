# Instância-brinquedo com ótimo conhecido, resolvida à mão no G07 §4.3.
# Um modelo que roda mas está errado é pior que um que não roda: em
# otimização o resultado errado é plausível e ninguém percebe.

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
