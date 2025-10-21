#!/usr/bin/bash

################################################################################################
# Define variables
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/lecanoromycetes/v25.08.19
RF_DIS_TSV=${OUTPUT}/rf_distance/rf_distance.tsv

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate phyling

################################################################################################
# === Use PHYkit to test the RF distance between consecutive trees ===

# Create an array of the trees based on the number of gene models used to build the tree
# The models are based on the SLURM_ARRAY_TASK_ID from the previous filtering step
models=(200 400 600 800 1000 1200 1400 1600 1800 2000 2200 2400 2600 2807)

# Loop through the models and calculate the RF distance between each consecutive model
# The first model is compared to the second, the second to the third, and so on

mkdir -p ${OUTPUT}/rf_distance
touch ${RF_DIS_TSV}  # Create the file if it doesn't exist
echo -e "model_comparison\tRF_Distance\tNormalized_RF_Distance" > ${RF_DIS_TSV}  # Header for the TSV file

for ((i=1; i<${#models[@]}; i++)); do
    prev=${models[$((i-1))]}
    curr=${models[$i]}
    if [[ ! -f ${OUTPUT}/consensus/${prev}-models/final_tree.nw ]] || [[ ! -f ${OUTPUT}/consensus/${curr}-models/final_tree.nw ]]; then
        echo "Skipping comparison for ${prev}-models or ${curr}-models as one of the files does not exist."
        continue
    fi
    echo "Comparing ${curr}-models to ${prev}-models"
    phykit robinson_foulds_distance \
        ${OUTPUT}/consensus/${prev}-models/final_tree.nw \
        ${OUTPUT}/consensus/${curr}-models/final_tree.nw | \
        awk -v cmp="${prev}_vs_${curr}" '{print cmp"\t"$1"\t"$2}' >> ${RF_DIS_TSV}
done

################################################################################################
# === Compare each model to the MAX reference tree ===
if [[ ! -f ${OUTPUT}/consensus/2807-models/final_tree.nw ]]; then
    echo "Maximum reference tree (2807-models) does not exist. Skipping comparison to reference."
    exit 1
fi

REF_MAX=${OUTPUT}/consensus/2807-models/final_tree.nw
REF_MAX_TSV=${OUTPUT}/rf_distance/rf_vs_max_reference.tsv

echo -e "model\tRF_Distance\tNormalized_RF_Distance" > $REF_MAX_TSV
for m in "${models[@]}"; do
    TREE=${OUTPUT}/consensus/${m}-models/final_tree.nw
    echo "Comparing ${m}-models to MAX reference tree"
    if [[ -f $TREE ]]; then
        phykit robinson_foulds_distance $REF_MAX $TREE | \
        awk -v model=$m '{print model"\t"$1"\t"$2}' >> $REF_MAX_TSV
    fi
done

################################################################################################
# === Compare each model to the MIN reference tree ===
if [[ ! -f ${OUTPUT}/consensus/200-models/final_tree.nw ]]; then
    echo "Minimum reference tree (200-models) does not exist. Skipping comparison to reference."
    exit 1
fi

REF_200=${OUTPUT}/consensus/200-models/final_tree.nw
REF_MIN_TSV=${OUTPUT}/rf_distance/rf_vs_min_reference.tsv

echo -e "model\tRF_Distance\tNormalized_RF_Distance" > $REF_MIN_TSV
for m in "${models[@]}"; do
    TREE=${OUTPUT}/consensus/${m}-models/final_tree.nw
    echo "Comparing ${m}-models to MIN reference tree"
    if [[ -f $TREE ]]; then
        phykit robinson_foulds_distance $REF_200 $TREE | \
        awk -v model=$m '{print model"\t"$1"\t"$2}' >> $REF_MIN_TSV
    fi
done

################################################################################################
# Check if the RF distance calculations were successful
if [[ -f ${RF_DIS_TSV} && -f ${REF_MAX_TSV} && -f ${REF_MIN_TSV} ]]; then
    echo "RF distance calculations completed."
    echo "RF Distance per model saved to: ${RF_DIS_TSV}"
    echo "RF Distance compared to max reference saved to: ${REF_MAX_TSV}"
    echo "RF Distance compared to min reference saved to: ${REF_MIN_TSV}"
else
    echo "RF distance calculations failed or no results were generated. Check code or input files for issues."
fi

conda deactivate
## SEE BELOW FOR OPTIONS AND HELP FOR # phykit robinson_foulds_distance
################################################################################################
# phykit robinson_foulds_distance -h
#  _____  _           _  _______ _______ 
# |  __ \| |         | |/ /_   _|__   __|
# | |__) | |__  _   _| ' /  | |    | |   
# |  ___/| '_ \| | | |  <   | |    | |   
# | |    | | | | |_| | . \ _| |_   | |   
# |_|    |_| |_|\__, |_|\_\_____|  |_|   
#                __/ |                   
#               |___/   

# Version: 2.0.1
# Citation: Steenwyk et al. 2021, Bioinformatics. doi: 10.1093/bioinformatics/btab096
# Documentation link: https://jlsteenwyk.com/PhyKIT
# Publication link: https://academic.oup.com/bioinformatics/article-abstract/37/16/2325/6131675

# Calculate Robinson-Foulds (RF) distance between two trees.

# Low RF distances reflect greater similarity between two phylogenies. 
# This function prints out two values, the plain RF value and the
# normalized RF value, which are separated by a tab. Normalized RF values
# are calculated by taking the plain RF value and dividing it by 2(n-3)
# where n is the number of tips in the phylogeny. Prior to calculating
# an RF value, PhyKIT will first determine the number of shared tips
# between the two input phylogenies and prune them to a common set of
# tips. Thus, users can input trees with different topologies and 
# infer an RF value among subtrees with shared tips.

# PhyKIT will print out 
# col 1; the plain RF distance and 
# col 2: the normalized RF distance.

# RF distances are calculated following Robinson & Foulds, Mathematical 
# Biosciences (1981), doi: 10.1016/0025-5564(81)90043-2.

# Aliases:
#   robinson_foulds_distance, rf_distance, rf_dist, rf
# Command line interfaces: 
#   pk_robinson_foulds_distance, pk_rf_distance, pk_rf_dist, pk_rf

# Usage:
# phykit robinson_foulds_distance <tree_file_zero> <tree_file_one>

# Options
# =====================================================
# <tree_file_zero>            first argument after 
#                             function name should be
#                             a tree file

# <tree_file_one>             second argument after 
#                             function name should be
#                             a tree file           

# options:
#   -h, --help  show this help message and exit
