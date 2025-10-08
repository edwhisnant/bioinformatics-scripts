#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/phyling/lecanoromycetes-align.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/phyling/lecanoromycetes-align.err
#SBATCH --partition=scavenger
#SBATCH -t 2-00:00:00

################################################################################################
## === PHYling Alignment Script ===
## This script performs multiple sequence alignment using PHYling. The input is a directory of protein FASTA files.

# Define variables
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/lecanoromycetes/v25.08.19

# # Create a temporary directory for input files
TEMP_DIR=$(mktemp -d /hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/temp-dir.XXXXXX)

# Find all protein FASTA files in the specified directory and copy them to the temporary directory
echo "Copying protein FASTA files to temporary directory: ${TEMP_DIR}"
find "${IN_DIR}" -path "*/annotate_results/*proteins.fa" -exec cp {} ${TEMP_DIR} \;

# === OR USE A PRE-COMPILED DIRECTORY ===
# TEMP_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/temp-dir.sT42Fz

# === PHYling requires you to have the output directory created beforehand ===
mkdir -p ${OUTPUT}/align

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate phyling

echo "Running PHYling..."

# == 1. RUN THE MSA (ALIGNMENT)
phyling align \
    -I ${TEMP_DIR} \
    -o ${OUTPUT}/align \
    -m ascomycota_odb12 \
    -M hmmalign \
    -t 32 \
    --seqtype pep

conda deactivate