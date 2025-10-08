#!/usr/bin/bash

#SBATCH --mem-per-cpu=8G  # adjust as needed
#SBATCH -c 16 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/synteny/mmseqs.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/synteny/mmseqs.err
#SBATCH --partition=common
#SBATCH -t 7-00:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=synteny-v25.06.18-mmseqs


# Create a temporary directory for input files
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes
OUTDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/synteny/lecanoromycetes/v25.06.18/mmseqs2
mkdir -p ${OUTDIR}

TEMP_DIR=$(mktemp -d /hpc/group/bio1/ewhisnant/comp-genomics/compare/synteny/temp-dir.XXXXXX)


# Find all protein FASTA files in the specified directory and copy them to the temporary directory
echo "Copying protein FASTA files to temporary directory: ${TEMP_DIR}"
find "${IN_DIR}" -path "*/annotate_results/*.gbk" -exec cp {} ${TEMP_DIR} \;

# Ensure Lasallia pustulata is not used in the analysis
rm ${TEMP_DIR}/Lasallia_pustulata_NCBI_GCA_937840595.1*

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate pygenomeviz

pgv-mmseqs \
    ${TEMP_DIR}/*.gbk \
    --outdir ${OUTDIR} \
    --threads 16 \
    --fig_width 30 \
    --track_align_type center \
    --feature_track_ratio 0.15 \
    --dpi 300 \
    --show_scale_xticks \
    --curve \
    --formats png

conda deactivate

