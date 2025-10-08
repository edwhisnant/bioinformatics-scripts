#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G  # adjust as needed
#SBATCH -c 12 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/dbcan/lecanoromycetes-%j_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/dbcan/lecanoromycetes-%j_%a.err
#SBATCH --partition=scavenger
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=dbcan-v25.07.11
#SBATCH -t 2-00:00:00
#SBATCH --array=1 # Array range (change after quality control step)

# === dbcan is a tool for CAZyme annotation from genomic data ===
# === Define variables ===

# === Define variables ===
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/dbcan/lecanoromycetes/v25.07.11
DATABASE_DIRECTORY=/hpc/group/bio1/ewhisnant/databases/dbcan_db

# === Define the single genome to run dbcan on ===
GENOME=Acarospora_aff__strigata_NCBI_GCA_964256185.1

# === Create the index for the array job ===
PFILE=${IN_DIR}/${GENOME}/annotate_results/${GENOME}.proteins.fa


# === Do not run on Lasallia pustulata as it is not used in the analysis ==

# === Run dbcan on the proteome files ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate dbcan

echo "Annotating CAZymes on: ${PFILE}"

mkdir -p ${OUTPUT}

run_dbcan CAZyme_annotation \
    --input_raw_data ${PFILE} \
    --output_dir ${OUTPUT}/${GENOME} \
    --db_dir ${DATABASE_DIRECTORY} \
    --mode protein \
    --threads 12

conda deactivate