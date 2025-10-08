#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/cafe/v25.07.11/lecanoromycetes-top91-G%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/cafe/v25.07.11/lecanoromycetes-top91-G%a.err
#SBATCH --partition=common
#SBATCH -t 10-00:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=cafe5-91filtered-G%a
#SBATCH --array=3,4,5  # Adjust based on the number of gamma categories you want to test

# === Define variables ===

NUM_HOGS_REMOVED="91" # EDIT NUMBER OF HOGS TO REMOVE HERE
OF_JUL11=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/proteins/Results_Jul11
OG_COPY_COUNT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.07.11/Results_Jul11/CAFE/OGs_rm_top${NUM_HOGS_REMOVED}filtered.tsv
UM_TREE=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.07.11/Results_Jul11/Species_Tree/SpeciesTree_rooted_ultrametric.txt
CAFE_OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/cafe/lecanoromycetes/v25.07.11/${NUM_HOGS_REMOVED}filtered-G${SLURM_ARRAY_TASK_ID}

# === Define Python script for summarizing results ===
# If CAFE completes successfully, this script will summarize the Gamma results
SUMMARIZE_GAMMA_PY=/hpc/group/bio1/ewhisnant/comp-genomics/scripts/compare/cafe/misc/summarize_cafe_gamma_results.py


# === What does CAFE do? ===
# CAFE is a software that provides a statistical foundation for evolutionary inferences about changes in gene family size.
#  The program employs a birth and death process to model gene gain and loss across a user-specified phylogenetic tree,
#  thus accounting for the species phylogenetic history. The distribution of family sizes generated under this model can
#  provide a basis for assessing the significance of the observed family size differences among taxa.

# === NOTES ===
# 1. The tree must be rooted and ultrametric
# 2. The input file must be a tab-delimited file with the first column as the gene family descripttion, second is the gene family, and the rest are the species

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate cafe5

# === 2. Run CAFE on HOGs using the ultrametric tree===
mkdir -p ${CAFE_OUTPUT}
cd ${CAFE_OUTPUT}

dos2unix ${OG_COPY_COUNT}  # Ensure the file is in Unix format

echo "Starting CAFE5 analysis"

echo "Running CAFE5 using: ${SLURM_ARRAY_TASK_ID} Gamma categories, 300 iterations, p-value threshold of 0.05, and a Poisson distribution for gene family size changes."

echo "Running CAFE5 after removing the top ${NUM_HOGS_REMOVED} HOGs with the most copy number variation"

cafe5 \
    --infile ${OG_COPY_COUNT} \
    --tree ${UM_TREE} \
    --cores 32 \
    --n_gamma_cats ${SLURM_ARRAY_TASK_ID} \
    -p \
    -I 300 \
    --pvalue 0.05 \
    --output_prefix CAFE

conda deactivate

echo "Summarizing the Gamma report"

if [ ! -f ${CAFE_OUTPUT}/CAFE/Gamma_results.txt ]; then
    echo "Gamma results file not found: ${CAFE_OUTPUT}/CAFE/Gamma_results.txt"
    echo "CAFE likely failed to initialize results on ${NUM_HOGS_REMOVED} filtered OGs. Check the error logs."
    echo "Exiting..."
    exit 1
else
    echo "Gamma results file found, proceeding with summarization."    
    python3 ${SUMMARIZE_GAMMA_PY} \
        ${CAFE_OUTPUT}/CAFE/Gamma_results.txt \
        ${CAFE_OUTPUT}/CAFE/Gamma_summary.tsv

fi

# === Provide a last check to see if the Python script ran successfully ===
if [ -f ${CAFE_OUTPUT}/CAFE/Gamma_summary.tsv ]; then
    echo "✅ Gamma summary written and CAFE analysis completed successfully."
else
    echo "❌ Failed to create Gamma summary table."
    exit 1
fi