#!/usr/bin/bash

#SBATCH --mem-per-cpu=64G  # Memory per CPU
#SBATCH -c 10               # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control/logs/busco_%A_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control/logs/busco_%A_%a.err
#SBATCH --partition=common
#SBATCH --array=1 # Array range

GENOMES=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/lecanoromycetes
GENOMES_DB=/hpc/group/bio1/ewhisnant/comp-genomics/genomes-database
25x_BUSCO_FILTERED_TSV=/hpc/group/bio1/ewhisnant/comp-genomics/genomes-database/filtered-coverage-25x.tsv
QUALITY_CONTROL_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control
SMASH_DIR=${QUALITY_CONTROL_DIR}/smash
SMASH_SIGS=${SMASH_DIR}/smash_sigs

mkdir -p ${SMASH_DIR}
mkdir -p ${SMASH_SIGS}

################################################################################################
#############                        RUN SOURMASH ANALYSIS                          ############
################################################################################################

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate smash


cd ${GENOMES}

# Create list of genome files to anlalyze
cut -f 1 ${25x_BUSCO_FILTERED_TSV} | tail -n +2 > ${GENOMES_DB}/smash_basenames.txt


# list of genome files
GENOME_FILES=($(ls ${GENOMES}/*.fa))
BASE_NAME=$(basename "$GENOME_FILES" .fa)


## This should search in the filtered file with the new list of genomes to analyze
## Check if the genome file is in the filtered list
if [ ${BASENAME} in $(cat ${GENOMES_DB}/smash_basenames.txt) ]; then
    
    GENOME_2_ANALYZE=${BASE_NAME}.fa # Genome file for this array task
    FILE=${GENOME_2_ANALYZE[$SLURM_ARRAY_TASK_ID]}
    BASE_NAME=$(basename "$FILE" .fa)
    
else
    skip
fi



################################################################################################
#############                       REMOVE TEMPORARY FILES                          ############
################################################################################################

rm ${GENOMES_DB}/smash_basenames.txt























