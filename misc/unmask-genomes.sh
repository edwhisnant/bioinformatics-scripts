#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G   # Memory per CPU
#SBATCH -c 1               # Number of threads per process
#SBATCH --output=/work/edw36/comp-genomics/funannotate2/logs/lecanoromyctes_%a.out
#SBATCH --error=/work/edw36/comp-genomics/funannotate2/logs/lecanoromycetes_%a.err
#SBATCH --partition=scavenger
#SBATCH -t 14:00:00
#SBATCH --array=0-290 # Array range (change after quality control step)

################################################################################################
#############                   RUNNING FUNANNOTATE2 PIPELINE                       ############
################################################################################################

# === Set variables
THREADS=16
COMP_GENOMICS=/hpc/group/bio1/ewhisnant/comp-genomics  # Base directory for outputs for comp-genomics
GENOMES=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/ascomycota/select_pezizomycotina_25.09.24/raw # Directory containing genome files
UNMASKED=/work/edw36/comp-genomics/genomes/ascomycota/select_pezizomycotina_25.09.24/unmasked # Sending to work

mkdir -p ${UNMASKED}

# === Build gemome file list
GENOME_FILES=($(ls ${GENOMES}/*.fa)) #List of genome files to process
GFILE=${GENOME_FILES[$SLURM_ARRAY_TASK_ID]} # Create the index for the array job
BASENAME=$(basename "${GFILE}" .fa) # Extract the base name of the genome file

################################################################################################
#############                    RUNNING A FILE CHECKPOINT                          ############
################################################################################################
# RUN THE CHECKPOINT

# VALIDATE GFILE
if [ -z "${GFILE}" ]; then
    echo "Error: No genome file found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}. Exiting."
    exit 1
fi

# VALIDATE BASENAME
if [ -z "${BASENAME}" ]; then
    echo "Error: BASENAME is empty. Exiting."
    exit 1
fi


###############################################################################################
echo "# 1. Pre-processing genome: ${BASENAME}"
################################################################################################
############          PRE-PROCESSING: UNMASK GENOME & REMOVE MITO CONTIGS           ############
################################################################################################
## NOTE: NCBI genomes are pre-soft masked, so to ensure they are properly processed, we need to unmask them first

source $(conda info --base)/etc/profile.d/conda.sh
conda activate seqkit

# === Unmasking the genome
echo "=== Ensuring genome is not masked. Unmasking ${BASENAME} genome file ==="

UNMASKED_ASSEMBLY=${UNMASKED}/${BASENAME}.fasta

seqkit seq -u ${GFILE} -o ${UNMASKED_ASSEMBLY}

conda deactivate