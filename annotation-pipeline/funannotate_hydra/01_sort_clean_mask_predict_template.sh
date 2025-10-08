#!/usr/bin/bash

#SBATCH --mem-per-cpu=32G   # Memory per CPU
#SBATCH -c 12               # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/predictions/logs/clean_mask_pred_%A_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/predictions/logs/clean_mask_pred_%A_%a.err
#SBATCH --partition=common
#SBATCH --array=1-107%11 # Array range (change after quality control step)

################################################################################################
#############        STEP 1: SORTING, CLEANING, MASKING, GENE PREDICTION            ############
################################################################################################

COMP_GENOMICS=/hpc/group/bio1/ewhisnant/comp-genomics/  # Base directory for outputs for comp-genomics
GENOMES=${COMP_GENOMICS}/filtered-genomes/lecanoromycetes # Directory containing genome files
GENOME_FILES=($(ls ${GENOMES}/*.fa)) #List of genome files to process
GFILE=${GENOME_FILES[$SLURM_ARRAY_TASK_ID]} # Create the index for the array job
BASENAME=$(basename "${GFILE}" .fa) # Extract the base name of the genome file
MASKED_DIR=${COMP_GENOMICS}/masked-genomes/lecanoromycetes/${BASENAME} # Directory for masked genomes
SORTED_DIR=${COMP_GENOMICS}/sorted-genomes/lecanoromycetes # Directory for sorted genomes
PREDICT_DIR=${COMP_GENOMICS}/predictions/lecanoromycetes/${BASENAME}
CPUS=12
BUSCO_DB=ascomycota_odb12

rm -r ${COMP_GENOMICS}/predictions/lecanoromycetes/${BASENAME} # Remove the directory if it exists

# Create directories for sorted, masked, and predicted genomes
mkdir -p ${COMP_GENOMICS}/predictions/lecanoromycetes/
mkdir -p ${PREDICT_DIR}
mkdir -p ${MASKED_DIR}
mkdir -p ${SORTED_DIR}

SORTED_ASSEMBLY=${SORTED_DIR}/${BASENAME}_sorted.fasta
CLEANED_ASSEMBLY=${COMP_GENOMICS}/cleaned-genomes/${BASENAME}_cleaned.fasta
REPEATMASKED_ASSEMBLY=${MASKED_DIR}/${BASENAME}_sorted.cleaned.masked.fasta

echo "Processing genome: ${BASENAME}"

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate_hydra

################################################################################################
############                          SORTING GENOME                                ############
################################################################################################
# This will sort the genome file by scaffold length and rename the scaffolds with a simple name

echo "Sorting the ${BASENAME} genome file"
funannotate sort \
    -i ${GFILE} \
    -o ${SORTED_ASSEMBLY}
    
################################################################################################
############                          CLEANING GENOME                               ############
################################################################################################

echo "Cleaning the fasta file"
cd ${GENOMES}

funannotate clean \
    -i ${SORTED_ASSEMBLY} \
    -o ${CLEANED_ASSEMBLY}
echo "Genome cleaned"
conda deactivate

################################################################################################
############                           MASKING GENOME                               ############
################################################################################################

conda activate RepeatSuite
echo "Starting RepeatMasker pipeline"

RepeatMasker \
    --species "Fungi" \
    ${CLEANED_ASSEMBLY} \
    --dir ${MASKED_DIR} \
    -pa 11

# CHECK IF THE MASKED FILE EXISTS, THEN RENAME IT 
if [ -f ${MASKED_DIR}/${BASENAME}_cleaned.fasta.masked ]; then
    mv ${MASKED_DIR}/${BASENAME}_cleaned.fasta.masked ${REPEATMASKED_ASSEMBLY}
    echo "Genome soft-masked"
else
    echo "Error: Masked file not found for ${BASENAME}!"
    exit 1
fi

conda deactivate    

################################################################################################
############                         PREDICTING GENES                               ############
################################################################################################
   
# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate_hydra

echo "Predicting genes from cleaned and masked ${BASENAME} assembly"

funannotate predict \
    -i ${REPEATMASKED_ASSEMBLY} \
    -o ${PREDICT_DIR} \
    -s "${BASENAME}" \
    --cpus ${CPUS} \
    --busco_db ${BUSCO_DB} \
    --optimize_augustus   

echo "${BASENAME} processed. Script completed on: "`date`


################################################################################################
############                    MOVE ON TO STEP 2: GENE PREDICTIONS                 ############
################################################################################################