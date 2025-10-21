#!/usr/bin/bash

#SBATCH --mem-per-cpu=2G  # adjust as needed
#SBATCH -c 16 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/seqkit/genomestats.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/seqkit/genomestats.err
#SBATCH --partition=common

# Define variables
LECAN_IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/lecanoromycetes
PEZIZO_IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/pezizomycotina
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/seqkit

mkdir -p ${OUTPUT}

# Create a temporary directory for input files
mkdir -p /work/edw36/comp-genomics/compare/seqkit/ # Ensure base dir exists

TEMP_DIR_1=$(mktemp -d /work/edw36/comp-genomics/compare/seqkit/temp-dir.XXXXXX)
TEMP_DIR_2=$(mktemp -d /work/edw36/comp-genomics/compare/seqkit/temp-dir.XXXXXX)

# Find all transcript FASTA files in the specified directory and copy them to the temporary directory
echo "Copying protein FASTA files to temporary directory: ${TEMP_DIR_1}"
find "${LECANO_IN_DIR}" -path "*/annotate_results/*nuclear.fasta" -exec cp {} ${TEMP_DIR_1} \; # Create the Lecanoromycetes input
find "${PEZIZO_IN_DIR}" -path "*/annotate_results/*nuclear.fasta" -exec cp {} ${TEMP_DIR_2} \; # Create the Pezizomycotina input


# === Use SeqKit to get genome stats ===
# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate seqkit

# === Collect for the Lecanoromycetes ===
cd ${TEMP_DIR_1}
mkdir -p ${OUTPUT}/Lecanoromycetes

seqkit stats \
    *.fasta \
    --all \
    -j 20 \
    --basename \
    -T \
    > ${OUTPUT}/Lecanoromycetes/lecanoromycetes-genome-stats.txt

# Check if the output file was created successfully
if [ -s ${OUTPUT}/Lecanoromycetes/lecanoromycetes-genome-stats.txt ]; then
    echo "Lecanoromycetes genome stats file created successfully."
else
    echo "[Error]: Lecanoromycetes genome stats file is empty or was not created."
fi

# === Collect for Pezizomycotina ===
cd ${TEMP_DIR_2}
mkdir -p ${OUTPUT}/Pezizomycotina

seqkit stats \
    *.fasta \
    --all \
    -j 20 \
    --basename \
    -T \
    > ${OUTPUT}/Pezizomycotina/pezizomycotina-genome-stats.txt

conda deactivate

if [ -s ${OUTPUT}/Pezizomycotina/pezizomycotina-genome-stats.txt ]; then
    echo "Pezizomycotina genome stats file created successfully."
else
    echo "[Error]: Pezizomycotina genome stats file is empty or was not created."
fi