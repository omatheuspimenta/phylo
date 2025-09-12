# Load required libraries
library(ape)
library(ggtree)
library(ggplot2)
library(dplyr)
library(RColorBrewer)
library(optparse)
library(phangorn)

# Parse command line arguments
option_list <- list(
  make_option(c("-t", "--tree"), type = "character", default = NULL,
              help = "Path to the Newick tree file", metavar = "character"),
  make_option(c("-a", "--annotation"), type = "character", default = NULL,
              help = "Path to the annotation CSV file", metavar = "character"),
  make_option(c("-o", "--output"), type = "character", default = ".",
              help = "Path to save the phylogenetic trees", metavar = "character"),
  make_option(c("-s", "--subsample"), type = "integer", default = NULL,
              help = "Number of sequences to subsample per subtype", metavar = "integer"),
  make_option(c("--width"), type = "integer", default = 20,
              help = "Plot width in inches", metavar = "integer"),
  make_option(c("--height"), type = "integer", default = 30,
              help = "Plot height in inches", metavar = "integer"),
  make_option(c("--confidence"), type = "character", default = "color",
              help = "How to display confidence values: 'color', 'selective', 'major', 'none'", metavar = "character"),
  make_option(c("--conf_threshold"), type = "numeric", default = 70,
              help = "Confidence threshold for 'selective' or 'major' display", metavar = "numeric")
)

opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# Read data
filename <- opt$tree
annotation_file <- opt$annotation
output_path <- opt$output
subsample_n <- opt$subsample
plot_width <- opt$width
plot_height <- opt$height
confidence_mode <- opt$confidence
conf_threshold <- opt$conf_threshold

cat("Reading annotation file...\n")
annotation <- read.csv(annotation_file, sep = ';', header = TRUE, stringsAsFactors = FALSE)

cat("Reading tree file...\n")
tree <- ape::read.tree(filename)

cat("Original tree has", length(tree$tip.label), "tips\n")

# OPTIONAL: Subsample sequences if dataset is too large
if (!is.null(subsample_n)) {
  cat("Subsampling", subsample_n, "sequences per subtype...\n")
  
  # Create tip annotation mapping
  tip_annotation <- data.frame(
    label = tree$tip.label,
    stringsAsFactors = FALSE
  )
  tip_annotation <- merge(tip_annotation, annotation, by.x = "label", by.y = "name", all.x = TRUE)
  
  # Subsample by subtype
  sampled_tips <- tip_annotation %>%
    group_by(subtype) %>%
    slice_sample(n = min(subsample_n, n())) %>%
    pull(label)
  
  # Prune tree to keep only sampled tips
  tree <- keep.tip(tree, sampled_tips)
  cat("Subsampled tree has", length(tree$tip.label), "tips\n")
}

# Convert tree to ultrametric format with progress indication
cat("Converting to ultrametric tree...\n")
tree_ultra <- if (!is.null(tree$edge.length)) {
  if (length(tree$tip.label) > 1000) {
    cat("Large tree detected. Using faster ultrametric conversion...\n")
    make.ultrametric(tree, method = "nnls")
  } else {
    chronos(tree, lambda = 1, model = "correlated")
  }
} else {
  tree
}

cat("Ultrametric conversion complete\n")

# Match tip labels with annotation data
tip_data <- data.frame(
  label = tree_ultra$tip.label,
  stringsAsFactors = FALSE
)
tip_data <- merge(tip_data, annotation, by.x = "label", by.y = "name", all.x = TRUE)

# Create color palette for subtypes
unique_subtypes <- unique(tip_data$subtype[!is.na(tip_data$subtype)])
n_subtypes <- length(unique_subtypes)
cat("Found", n_subtypes, "subtypes:", paste(unique_subtypes, collapse = ", "), "\n")

if (n_subtypes <= 8) {
  colors <- RColorBrewer::brewer.pal(max(3, min(n_subtypes, 9)), "Set1")
} else {
  colors <- rainbow(n_subtypes, s = 0.8, v = 0.8)
}
subtype_colors <- setNames(colors[1:n_subtypes], unique_subtypes)
tip_data$color <- subtype_colors[tip_data$subtype]
tip_data$color[is.na(tip_data$color)] <- "gray50"

# Create ggtree plot optimized for large datasets
cat("Creating phylogenetic tree plot...\n")
n_tips <- length(tree_ultra$tip.label)
show_tip_labels <- n_tips <= 500
tip_size <- max(0.5, 3 - log10(n_tips))
branch_size <- max(0.1, 0.8 - log10(n_tips) * 0.1)

p <- ggtree(tree_ultra,
            color = "gray40",
            size = branch_size,
            layout = "rectangular") %<+% tip_data

p2 <- p +
  geom_tippoint(aes(color = subtype),
                size = tip_size,
                alpha = 0.8)

if (show_tip_labels) {
  p2 <- p2 +
    geom_tiplab(aes(color = subtype),
                size = max(1.5, 3 - log10(n_tips) * 0.5),
                offset = max(0.0001, 0.0002 - log10(n_tips) * 0.00005),
                hjust = 0,
                show.legend = FALSE)
}

# Check if the tree has node labels (confidence values) to display
if (!is.null(tree_ultra$node.label) && confidence_mode != "none") {
  
  cat("Applying confidence visualization mode:", confidence_mode, "\n")
  
  # Option 1: Color nodes by confidence value
  if (confidence_mode == "color") {
    p2 <- p2 + 
      geom_nodepoint(aes(subset = !isTip, fill = as.numeric(label)), # FIX HERE
                     shape = 21, # Circle with outline
                     size = tip_size * 2.5, # change here
                     na.rm = TRUE) +
      scale_fill_viridis_c(name = "Confidence", 
                           na.value = "transparent", 
                           direction = -1, 
                           option = "D")
  } 
  
  # Option 2: Show text labels for nodes above a threshold
  else if (confidence_mode == "selective") {
    p2 <- p2 + 
      geom_text2(aes(subset = !isTip & as.numeric(label) >= conf_threshold, # FIX HERE
                     label = round(as.numeric(label), 0)), # AND HERE
                 size = tip_size * 0.7, 
                 color = "black",
                 fontface = "bold",
                 hjust = 1.3, 
                 vjust = -0.4,
                 na.rm = TRUE)
  } 
  
  # Option 3: Highlight major, well-supported nodes with points
  else if (confidence_mode == "major") {
    p2 <- p2 + 
      geom_nodepoint(aes(subset = !isTip & as.numeric(label) >= conf_threshold), # FIX HERE
                     color = "firebrick", 
                     size = tip_size,
                     na.rm = TRUE)
  }
  
} else {
  cat("Skipping confidence value visualization (mode is 'none' or no node labels found).\n")
}

# Add consistent styling
p2 <- p2 +
  scale_color_manual(values = subtype_colors,
                     name = "Subtype",
                     na.value = "gray50") +
  theme_tree2() +
  theme(legend.position = "right",
        legend.title = element_text(size = 14, face = "bold"),
        legend.text = element_text(size = 12),
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.margin = margin(20, 20, 20, 20)) +
  ggtitle(paste("Phylogenetic Tree (", n_tips, "sequences,", n_subtypes, "subtypes)"))

# Adjust x-axis limits for better visualization
if (!is.null(tree_ultra$edge.length)) {
  max_depth <- max(node.depth.edgelength(tree_ultra))
  expansion_factor <- if (show_tip_labels) 1.4 else 1.1
  p2 <- p2 + xlim(0, max_depth * expansion_factor)
}

# Save with adaptive dimensions
cat("Saving plot...\n")
outfile_name <- paste(tools::file_path_sans_ext(basename(filename)),
                      "phylo_tree_large.png", sep = "_")
outpath_tree_ggtree <- file.path(output_path, outfile_name)

final_width <- max(plot_width, ceiling(n_tips / 100) * 2)
final_height <- max(plot_height, ceiling(n_tips / 50))

ggsave(outpath_tree_ggtree, p2,
       width = final_width,
       height = final_height,
       dpi = 300,
       limitsize = FALSE)

outfile_pdf <- paste(tools::file_path_sans_ext(basename(filename)),
                     "phylo_tree_large.pdf", sep = "_")
outpath_tree_pdf <- file.path(output_path, outfile_pdf)

ggsave(outpath_tree_pdf, p2,
       width = final_width,
       height = final_height,
       limitsize = FALSE)

cat("Tree visualization complete!\n")
cat("PNG saved to:", outpath_tree_ggtree, "\n")
cat("PDF saved to:", outpath_tree_pdf, "\n")
cat("Final plot dimensions:", final_width, "x", final_height, "inches\n")
cat("Confidence display mode:", confidence_mode, "\n")

# Print summary statistics
cat("\n=== TREE SUMMARY ===\n")
cat("Total sequences:", n_tips, "\n")
cat("Number of subtypes:", n_subtypes, "\n")
cat("Subtypes found:", paste(unique_subtypes, collapse = ", "), "\n")
if (!is.null(tree_ultra$edge.length)) {
  cat("Tree depth:", round(max(node.depth.edgelength(tree_ultra)), 6), "\n")
}
if (!is.null(tree_ultra$node.label) && confidence_mode != "none") {
  conf_vals <- as.numeric(tree_ultra$node.label)
  cat("Confidence values: min =", min(conf_vals, na.rm = TRUE),
      "max =", max(conf_vals, na.rm = TRUE), "\n")
  cat("High confidence nodes (>", conf_threshold, "):",
      sum(conf_vals >= conf_threshold, na.rm = TRUE), "\n")
}
cat("Tip labels shown:", show_tip_labels, "\n")