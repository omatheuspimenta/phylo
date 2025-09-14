# Install packages in R env
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("ggtree")

install.packages("Rcpp", repos="https://cloud.r-project.org/")
install.packages("getopte", repos="https://cloud.r-project.org/")
install.packages("optparse", repos="https://cloud.r-project.org/")
install.packages("digest", repos="https://cloud.r-project.org/")
install.packages("jsonlite", repos="https://cloud.r-project.org/")
install.packages("ape", repos="https://cloud.r-project.org/")
install.packages("ggplot2", repos="https://cloud.r-project.org/")
install.packages("dplyr", repos="https://cloud.r-project.org/")
install.packages("RColorBrewer", repos="https://cloud.r-project.org/")
install.packages("phangorn", repos="https://cloud.r-project.org/")
