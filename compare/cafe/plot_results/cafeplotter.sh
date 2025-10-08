#!/usr/bin/bash

#SBATCH --mem=64G  # adjust as needed
#SBATCH -c 12 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/cafe/cafeplotter.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/cafe/cafeplotter.err
#SBATCH -t 1-00:00:00
#SBATCH --partition=common

INDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/cafe/lecanoromycetes/v25.07.11/91filtered-G4/CAFE
OUTDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/cafe/lecanoromycetes/v25.07.11/91filtered-G4/cafeplotter

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate cafeplotter

echo "Running cafeplotter"
cafeplotter --version

# mkdir -p ${OUTDIR}

cafeplotter \
    --indir ${INDIR} \
    --outdir ${OUTDIR} \
    --format pdf \
    --fig_width 30 \
    --fig_height 0.35 \
    --count_label_size 10 \
    --innode_label_size 10 \
    --p_label_size 10 \
    --expansion_color red \
    --contraction_color blue \
    --dpi 300

conda deactivate