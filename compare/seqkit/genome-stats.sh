#!/usr/bin/bash

#SBATCH --mem-per-cpu=2G  # adjust as needed
#SBATCH -c 20 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/seqkit/lecanoromycetes-genomestats.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/seqkit/lecanoromycetes-genomestats.err
#SBATCH --partition=common

# Define variables
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/seqkit/lecanoromycetes/

mkdir -p ${OUTPUT}/genome-stats

# Create a temporary directory for input files
TEMP_DIR=$(mktemp -d /hpc/group/bio1/ewhisnant/comp-genomics/compare/seqkit/temp-dir.XXXXXX)

# Find all transcript FASTA files in the specified directory and copy them to the temporary directory
echo "Copying protein FASTA files to temporary directory: ${TEMP_DIR}"
find "${IN_DIR}" -path "*/annotate_results/*nuclear.fa" -exec cp {} ${TEMP_DIR} \;


# === Use SeqKit to get genome stats ===
# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate seqkit

cd ${TEMP_DIR}

seqkit stats \
    *.fa \
    --all \
    -j 20 \
    --basename \
    -T \
    > ${OUTPUT}/genome-stats/lecanoromycetes-genome-stats.txt

conda deactivate