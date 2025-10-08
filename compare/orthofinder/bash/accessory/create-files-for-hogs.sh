#!/usr/bin/bash

#SBATCH --mem 32G  # adjust as needed
#SBATCH -c 8 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/lecanoromycetes-createHOGfasta.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/lecanoromycetes-createHOGfasta.err
#SBATCH --partition=common
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=orthofinder-create.HOG.fasta

# === Use to create FASTA files for HOGs ===

CREATE_FILES_FOR_HOGS=/hpc/group/bio1/ewhisnant/miniconda3/envs/orthofinder/bin/create_files_for_hogs.py
OF_RESULTS_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.06.18/fasttree/Results_Jun18
OUTDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.06.18/fasttree/Results_Jun18
NODE=N0

echo "Creating FASTA files for HOGs in directory: ${OUTDIR}"

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate orthofinder

python3 ${CREATE_FILES_FOR_HOGS} \
    ${OF_RESULTS_DIR} \
    ${OUTDIR} \
    ${NODE}

conda deactivate