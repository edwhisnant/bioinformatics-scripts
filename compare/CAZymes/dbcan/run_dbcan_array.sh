#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G  # adjust as needed
#SBATCH -c 12 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/dbcan/v25.08.19/lecanoromycetes-dbcan-%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/dbcan/v25.08.19/lecanoromycetes-dbcan-%a.err
#SBATCH --partition=scavenger
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=dbcan-v25.08.19
#SBATCH -t 2-00:00:00
#SBATCH --array=0-114 # Array range (change after quality control step)

# === dbcan is a tool for CAZyme annotation from genomic data ===
# === Define variables ===

# === Define variables ===
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/dbcan/lecanoromycetes/v25.08.19
DATABASE_DIRECTORY=/hpc/group/bio1/ewhisnant/databases/dbcan_db

# === Create the index for the array job ===
PROTEOME_FILES=($(ls ${IN_DIR}/*/annotate_results/*proteins.fa))
PFILE=${PROTEOME_FILES[$SLURM_ARRAY_TASK_ID]}
BASENAME=$(basename "${PFILE}" .fa)

# === Validate input files exist ===
if [ -z "${PFILE}" ]; then
    echo "Error: No genome file found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}. Exiting."
    exit 1
fi

if [ -z "${BASENAME}" ]; then
    echo "Error: BASENAME is empty. Exiting."
    exit 1
fi

echo "dbcan2 will be run on $(ls ${IN_DIR}/*/annotate_results/*proteins.fa | wc -l) proteomes"
echo "Processing file: ${PFILE}. Proteome number: ${SLURM_ARRAY_TASK_ID}"

# === Run dbcan on the proteome files ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate dbcan

mkdir -p ${OUTPUT}

run_dbcan CAZyme_annotation \
    --input_raw_data ${PFILE} \
    --output_dir ${OUTPUT}/${BASENAME} \
    --db_dir ${DATABASE_DIRECTORY} \
    --mode protein \
    --threads 12

conda deactivate