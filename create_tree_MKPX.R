# Load required libraries
library(ape)
library(ggtree)
library(ggplot2)
library(dplyr)
library(RColorBrewer)
library(optparse)

# Parse command line arguments
option_list <- list(
  make_option(c("-t", "--tree"), type = "character", default = NULL,
              help = "Path to the Newick tree file", metavar = "character"),
  make_option(c("-a", "--annotation"), type = "character", default = NULL,
              help = "Path to the annotation CSV file", metavar = "character"),
  make_option(c("-o", "--output"), type = "character", default = ".",
              help = "Path to save the phylogenetic trees", metavar = "character")
)

opt_parser <- OptionParser(option_list = option_list)
# Read data
filename <- parse_args(opt_parser)$tree
annotation_file <- parse_args(opt_parser)$annotation
output_path <- parse_args(opt_parser)$output

annotation <- read.csv2(annotation_file, sep = ',', header = TRUE)
tree <- ape::read.tree(filename)

# Convert tree to ultrametric format (this is just an example, in practice, use appropriate method)
tree_ultra <- if (!is.null(tree$edge.length)) {
  chronos(tree, lambda = 1, model = "correlated")
} else {
  tree
}



# Alternative methods for converting to ultrametric:
# Method 1: Using chronos (recommended for molecular data)
# tree_ultra <- chronos(tree, lambda = 1, model = "correlated")

# Method 2: Using compute.brlen for equal branch lengths
# tree_ultra <- compute.brlen(tree, method = "Grafen")

# Method 3: Using make.ultrametric (simple approach)
# tree_ultra <- make.ultrametric(tree, method = "nnls")

# Verify the tree is ultrametric

# Match tip labels with annotation data
# Create a data frame for tip colors
tip_data <- data.frame(
  label = tree_ultra$tip.label,
  stringsAsFactors = FALSE
)

# Merge with annotation data
tip_data <- merge(tip_data, annotation, by.x = "label", by.y = "name", all.x = TRUE)

# Create color palette for subtypes
unique_subtypes <- unique(tip_data$subtype[!is.na(tip_data$subtype)])
n_subtypes <- length(unique_subtypes)

# Generate colors
if (n_subtypes <= 8) {
  colors <- RColorBrewer::brewer.pal(max(3, n_subtypes), "Set2")
} else {
  colors <- rainbow(n_subtypes)
}

# Create named color vector
subtype_colors <- setNames(colors[1:n_subtypes], unique_subtypes)

# Assign colors to tips
tip_data$color <- subtype_colors[tip_data$subtype]
tip_data$color[is.na(tip_data$color)] <- "gray50"  # Color for missing data

# Method 1: Using ggtree with ultrametric tree
library(ggtree)

# Create ggtree object with ultrametric tree
p <- ggtree(tree_ultra, color = "gray30", size = 0.8) %<+% tip_data

# Add elements step by step
p2 <- p + 
  geom_tippoint(aes(color = subtype), size = 3, alpha = 0.8) +
  geom_tiplab(aes(color = subtype), 
              size = 3, 
              offset = 0.0002,  # CLOSER to tips
              hjust = 0) +
  geom_nodepoint(color = "white", size = 0.1) +  # Small white points at nodes
  geom_text2(aes(subset = !isTip, label = label),  # Node labels at INTERNAL nodes
             size = 2.5,
             color = "red",
             fontface = "bold",
             hjust = -0.1,
             vjust = -0.3) +
  scale_color_manual(values = subtype_colors, 
                     name = "Subtype",
                     na.value = "gray50") +
  theme_tree2() +
  theme(legend.position = "right",
        legend.title = element_text(size = 12, face = "bold"),
        legend.text = element_text(size = 10),
        plot.title = element_text(size = 14, face = "bold", hjust = 0.5)) +
  ggtitle("Ultrametric Phylogenetic Tree - MKPX")

if (!is.null(tree_ultra$edge.length)) {
  p2 <- p2 + xlim(0, max(node.depth.edgelength(tree_ultra)) * 1.25)  # Adjusted space
}

# Save the ggtree plot - same prefix as input file
outfile_name <- paste(tools::file_path_sans_ext(basename(filename)), "phylo_tree.png", sep = "_")
outpath_tree_ggtree <- file.path(output_path, outfile_name)
ggsave(outpath_tree_ggtree, p2, width = 12, height = 8, dpi = 300)

# Display the ggtree plot
# print(p2)

cat("ggTree:", outpath_tree_ggtree, "\n")
