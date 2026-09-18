library(testthat)

# O setup — carregar app/R/ e anexar o plugin do solver ao ROI — vive em
# tests/testthat/helper-carregar.R, que o testthat lê sozinho. Aqui fica só a
# invocação, para que `Rscript tests/testthat.R` e `test_dir()` se comportem
# igual.
test_dir("testthat")
