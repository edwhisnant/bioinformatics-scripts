# make_ultrametric.R
library(ape)

args <- commandArgs(trailingOnly = TRUE)
input_tree <- args[1]
output_tree <- args[2]

tree <- read.tree(input_tree)

# Check if ultrametric
if (!is.ultrametric(tree)) {
  cat("Tree is not ultrametric. Converting with chronos...\n")
  ultra_tree <- chronos(tree)
  write.tree(ultra_tree, file=output_tree)
} else {
  cat("Tree is already ultrametric. Copying original tree.\n")
  write.tree(tree, file=output_tree)
}
