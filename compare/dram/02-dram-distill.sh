#!/usr/bin/bash

#SBATCH --mem-per-cpu=32G  # adjust as needed
#SBATCH -c 20 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/dram/lecanoromycetes.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/dram/lecanoromycetes.err
#SBATCH --partition=common

################################################################################################

IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes

# Find all protein FASTA files in the specified directory and copy them to the temporary directory
TEMP_DIR=$(mktemp -d /hpc/group/bio1/ewhisnant/comp-genomics/compare/dram/temp-dir.XXXXXX)

echo "Copying protein FASTA files to temporary directory: ${TEMP_DIR}"
find "${IN_DIR}" -path "*/annotate_results/*.fasta" -exec cp {} ${TEMP_DIR} \; # Copy files to a temporary directory


OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/dram/lecanoromycetes

################################################################################################
############                               DRAM                                     ############
################################################################################################

source $(conda info --base)/etc/profile.d/conda.sh
conda activate DRAM

echo "Starting DRAM pipeline"
echo `date`

DRAM.py distill \
    -i ${OUTPUT}/annotations.tsv \
    -o ${OUTPUT}/genome_summaries \
    --trna_path ${OUTPUT}/trnas.tsv \
    --rrna_path ${OUTPUT}/rrnas.tsv

conda deactivate
