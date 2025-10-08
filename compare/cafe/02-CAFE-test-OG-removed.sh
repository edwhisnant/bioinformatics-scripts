#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G
#SBATCH -c 32
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/cafe/lecanoromycetes-top%a-G2.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/cafe/lecanoromycetes-top%a-G2.err
#SBATCH --partition=common
#SBATCH -t 7-00:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=cafe5-v25.06.18
#SBATCH --array=81-100  # ← this loops over the specified number of OGs removed

# === Define base variables ===
GAMMA=2
NUM_HOGS_REMOVED=${SLURM_ARRAY_TASK_ID} # EDIT NUMBER OF HOGS TO REMOVE HERE
ITER=300
VERSION=v25.08.19
RESULTS_DIR=Results_Aug22
OG_COPY_COUNT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS_DIR}/CAFE/OGs_rm_top${NUM_HOGS_REMOVED}filtered.tsv
UM_TREE=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS_DIR}/Species_Tree/SpeciesTree_rooted_ultrametric.txt
CAFE_OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/cafe/lecanoromycetes/${VERSION}/${RESULTS_DIR}/${NUM_HOGS_REMOVED}filtered-G${GAMMA}

# === Define Python script for summarizing results ===
# If CAFE completes successfully, this script will summarize the Gamma results
SUMMARIZE_GAMMA_PY=/hpc/group/bio1/ewhisnant/comp-genomics/scripts/compare/cafe/misc/summarize_cafe_gamma_results.py

# === Activate conda environment ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate cafe5

# === Create output directory and run ===
mkdir -p ${CAFE_OUTPUT}
cd ${CAFE_OUTPUT}

dos2unix ${OG_COPY_COUNT}  # Ensure the file is in Unix format

echo "Starting CAFE5 analysis"

echo "Running CAFE5 using: ${GAMMA} Gamma categories, 300 iterations, p-value threshold of 0.05, and a Poisson distribution for gene family size changes."

echo "Running CAFE5 after removing the top ${NUM_HOGS_REMOVED} HOGs with the most copy number variation"

cafe5 \
    --infile ${OG_COPY_COUNT} \
    --tree ${UM_TREE} \
    --cores 32 \
    --n_gamma_cats ${GAMMA} \
    -p \
    -I ${ITER} \
    --pvalue 0.05 \
    --output_prefix CAFE

conda deactivate

# === Summarize the Gamma results if CAFE ran successfully ===
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