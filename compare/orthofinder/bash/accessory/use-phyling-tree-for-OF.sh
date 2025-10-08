#!/usr/bin/bash

#SBATCH --mem=400G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/lecanoromycetes-w-phyling.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/lecanoromycetes-w-phyling.err
#SBATCH --partition=common

# === Define variables ===
PREV_OF_RUN=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/proteins/Results_May28
PHYLING_TREE=/hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/lecanoromycetes/tree-cons1000/final_tree.nw


# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate orthofinder

# === Run Orthofinder with a pre-computed phylogenetic tree ===
# Note: The -fg argument is used to specify that the analysis will start from pre-computed orthogroups.
# Note: I am using a pre-computed phylogenetic tree from Phyling, which is a consensus tree based on 1000 BUSCO hmm markers


orthofinder \
    -fg ${PREV_OF_RUN} \
    -s ${PHYLING_TREE} \
    -T iqtree_200G \
    -t 32 \
    -a 4 \
    -y \
    -M msa \
    -A mafft

conda deactivate

