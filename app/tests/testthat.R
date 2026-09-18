library(testthat)
# Os testes rodam contra as funções de app/R/, carregadas direto — não há
# pacote aqui, e transformar o projeto num pacote R só para testar seria
# cerimônia sem retorno em cinco semanas.
for (f in list.files("../R", pattern = "[.]R$", full.names = TRUE)) source(f)
test_dir("testthat")
