# Define o mirror CRAN manualmente
options(repos = c(CRAN = "https://cran-r.c3sl.ufpr.br"))

# Instala o BiocManager, se necessário
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

# Instala pacote do Bioconductor
BiocManager::install("ggtree", ask = FALSE)

# Instala pacotes do CRAN
install.packages("Rcpp")
install.packages("getopt")      # Corrigido nome do pacote
install.packages("optparse")
install.packages("digest")
install.packages("jsonlite")
install.packages("ape")
install.packages("ggplot2")
install.packages("dplyr")
install.packages("RColorBrewer")
install.packages("phangorn")

