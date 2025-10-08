#!/usr/bin/bash

#SBATCH --mem-per-cpu=1G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/lecanoromycetes-remove-Lp.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/lecanoromycetes-remove-Lp.err
#SBATCH --partition=common

# === Define variables ===
PREV_OF_RUN=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/proteins/Results_May28/WorkingDirectory
PHYLING_TREE=/hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/lecanoromycetes/tree-cons1000/final_tree.nw

################################################################################################
############                          RUN ORTHOFINDER                               ############
################################################################################################
# There is currently an error with IQtree and OrthoFinder - use fasttree instead

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate orthofinder

cd /hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/proteins

orthofinder \
    -b ${PREV_OF_RUN} \
    -t 32 \
    -a 4 \
    -og

# Remove the temporary directory
# rm -r ${TEMP_DIR}

conda deactivate