#!/usr/bin/bash

#SBATCH --mem-per-cpu=8G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/phyling/tree/lecanoromycetes-tree-cons_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/phyling/tree/lecanoromycetes-tree-cons_%a.err
#SBATCH --partition=scavenger
#SBATCH -t 10-00:00:00
#SBATCH --job-name=phyling-tree

################################################################################################
## === PHYling Tree builiding Script ===
## This script performs the tree building step using PHYling. The input is the output directory from phyling align or phyling filter.
## This module will build a species tree using either all markers from the align step or a filtered set of markers from the filter step.
## The output will be a directory containing the final tree in Newick format and a figure of the tree.
## By default, a coalescent tree will be built using all markers from the align step. Tree is built using the LG model for peptides.
## Optionally, you can choose to concatenate the alignments and build a single tree in addition to the coalescent tree.
## Note that if you choose to concatenate the alignments, a partition file compatible with RAxML-NG and IQ-TREE will also be generated.
## Concatenated mode will use:
## 1. ModelFinder to select the best subsitution model
## 2. use best model to build tree with IQ-Tree
## 3. Calculate branch support with Ultrafast Bootstrap and site concordance by IQ-Tree.
################################################################################################

# Define variables
CONCAT=yes # Set to "yes" if you want to concatenate the alignments for tree building, otherwise "no" or anything other than "yes"

OUTPUT= # Adjust the path when ready to run
INDIR=${OUTPUT}/align
TREE_DIR=${OUTPUT}/tree
CONS_DIR=${TREE_DIR}/consensus
CONCAT_DIR=${TREE_DIR}/concat

mkdir -p ${TREE_DIR}
mkdir -p ${CONS_DIR}

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate phyling

echo "Running PHYling tree building"

# === 1. Build a coalescent tree using all markers from the align step
echo "# 1. Building a consensus tree using all markers from the align step"

phyling tree \
    -I ${INDIR} \
    -o ${CONS_DIR} \
    -M iqtree \
    -t 32 \
    -f \
    --seqtype pep

if [ "$CONCAT" = "yes" ]; then
    echo "You have chosen to concatenate the alignments for tree building"
    echo "# 2. Building a concatenated tree using all markers from the align step"

    # === 2. Build a concatenated tree using all markers from the align step
    mkdir -p ${CONCAT_DIR}

    phyling tree \
        -I ${INDIR} \
        -o ${TREE_DIR}/concat \
        -M iqtree \
        -t 32 \
        -f \
        --seqtype pep \
        -c \
        -p
fi

conda deactivate

################################################################################################
# See below for options and help for # phykit tree
################################################################################################
# phyling tree -h
# usage: phyling tree (-i file [files ...] | -I directory) [-o directory] [--seqtype {pep,dna,AUTO}] [-M {ft,raxml,iqtree}] [-c] [-p] [-f] [--seed SEED]
#                     [-t THREADS] [-v] [-h]

# Construct a phylogenetic tree by the selected multiple sequence alignment (MSA) results.

# By default the consensus tree method will be employed which use a 50% cutoff to represent the majority of all the trees. You can use the -c/--concat
# option to concatenate the MSA and build a single tree instead. Note that enable the -p/--partition option will also output a partition file that
# compatible to RAxML-NG and IQ-TREE.

# For the tree building step, the FastTree will be used as default algorithm. Users can switch to the RAxML-NG or IQ-TREE by specifying the -m/--method
# raxml/iqtree.

# Once the tree is built, an ASCII figure representing the tree will be displayed, and a treefile in Newick format will be generated as output.
# Additionally, users can choose to obtain a matplotlib-style figure using the -f/--figure option.

# Required arguments:
#   -i file [files ...], --inputs file [files ...]
#                         Multiple sequence alignment fasta of the markers
#   -I directory, --input_dir directory
#                         Directory containing multiple sequence alignment fasta of the markers

# Options:
#   -o directory, --output directory
#                         Output directory of the newick treefile (default: phyling-tree-[YYYYMMDD-HHMMSS] (UTC timestamp))
#   --seqtype {pep,dna,AUTO}
#                         Input data sequence type (default: AUTO)
#   -M {ft,raxml,iqtree}, --method {ft,raxml,iqtree}
#                         Algorithm used for tree building. (default: ft)
#                         Available options:
#                         ft: FastTree
#                         raxml: RAxML-NG
#                         iqtree: IQTree
#   -c, --concat          Concatenated alignment results
#   -p, --partition       Partitioned analysis by sequence. Only works when --concat enabled.
#   -f, --figure          Generate a matplotlib tree figure
#   --seed SEED           Seed number for stochastic elements during inferences. (default: -1 to generate randomly)
#   -t THREADS, --threads THREADS
#                         Threads for tree construction (default: 1)
#   -v, --verbose         Verbose mode for debug
#   -h, --help            show this help message and exit