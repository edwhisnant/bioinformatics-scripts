#!/usr/bin/bash

#SBATCH --mem-per-cpu=2G  # Memory per CPU
#SBATCH -c 16               # Number of threads per process
#SBATCH --output=/work/edw36/comp-genomics/quality-control/logs/busco/busco_%a.out
#SBATCH --error=/work/edw36/comp-genomics/quality-control/logs/busco/busco_%a.err
#SBATCH --partition=scavenger
#SBATCH -t 07:00:00      
#SBATCH --array=0-289 # Array range

GENOMES=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/ascomycota/select_pezizomycotina_25.09.24/raw

# Send output to work directory
OUTPUT=/work/edw36/comp-genomics/quality-control/busco

# Activate the conda environment
source $(conda info --base)/etc/profile.d/conda.sh
conda activate busco

cd ${OUTPUT}

# list of genome files
GENOME_FILES=($(ls ${GENOMES}/*.fa))

# genome file for this array task
FILE=${GENOME_FILES[$SLURM_ARRAY_TASK_ID]}
BASENAME=$(basename "$FILE" .fa)

# Create output directory for this genome

mkdir -p ${OUTPUT}/pezizomycotina/${BASENAME}

cd ${OUTPUT}/pezizomycotina

echo "Running BUSCO for $BASENAME"

# Run BUSCO
busco -i "${FILE}" \
      -o "${BASENAME}" \
      -l ascomycota_odb12 \
      -m genome \
      -f \
      -c 16

# Copy the summary file to the BUSCO summary directory
mkdir -p ${OUTPUT}/BUSCO_summary
cp ${OUTPUT}/${BASENAME}/short_summary.*.txt ${OUTPUT}/BUSCO_summary/

echo "BUSCO analysis for ${BASENAME} completed"
echo "Next step is the run the BUSCO summary script. The results from the raw BUSCO results are found in ${OUTPUT}/BUSCO_summary/"

conda deactivate
