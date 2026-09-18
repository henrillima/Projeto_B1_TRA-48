# O testthat carrega sozinho todo arquivo `helper-*.R` desta pasta antes de
# rodar os testes, com o diretório de trabalho já em tests/testthat/. É o
# lugar certo para o setup: deixá-lo no comando de invocação significa que o
# teste passa para quem digitou o comando certo e falha para todo mundo mais.

# As funções do projeto. Não há pacote R aqui — transformar o projeto num
# pacote só para testar seria cerimônia sem retorno em cinco semanas.
for (f in list.files(file.path("..", "..", "R"), "[.]R$", full.names = TRUE)) {
  source(f)
}

# O ROI mantém um registro de solvers que só é populado quando o pacote do
# plugin é ANEXADO — instalar não basta. Sem esta linha, `with_ROI(solver =
# "highs")` falha com "highs is not among the registered ROI solvers", que é
# uma mensagem que parece bug de modelo e não é.
#
# A rota da matriz esparsa chama `highs::highs_solve()` direto e não depende
# disto; só a rota `ompr` precisa. O teste que compara as duas é justamente o
# que quebra sem esta linha.
suppressPackageStartupMessages(library(ROI.plugin.highs))
