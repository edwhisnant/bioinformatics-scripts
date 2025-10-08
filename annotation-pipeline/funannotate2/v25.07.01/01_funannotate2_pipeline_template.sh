#!/usr/bin/bash

#SBATCH --mem-per-cpu=32G   # Memory per CPU
#SBATCH -c 12               # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-logs/lecanoromycetes/lecanoromyctes_%A_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-logs/lecanoromycetes/lecanoromycetes_%A_%a.err
#SBATCH --partition=common
#SBATCH --array=1-121 # Array range (change after quality control step)

# Record the start time
START_TIME=$(date +%s)

################################################################################################
#############                   RUNNING FUNANNOTATE2 PIPELINE                       ############
################################################################################################

# SET VARIABLES
COMP_GENOMICS=/hpc/group/bio1/ewhisnant/comp-genomics  # Base directory for outputs for comp-genomics
GENOMES=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/select-lecanoromycetes-25.09.03/genomes/raw # Directory containing genome files
UNMASKED=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/select-lecanoromycetes-25.09.03/genomes/unmasked
GENOME_FILES=($(ls ${GENOMES}/*.fa)) #List of genome files to process
GFILE=${GENOME_FILES[$SLURM_ARRAY_TASK_ID]} # Create the index for the array job
BASENAME=$(basename "${GFILE}" .fa) # Extract the base name of the genome file
MASKED_DIR=${COMP_GENOMICS}/masked-genomes/lecanoromycetes/${BASENAME} # Directory for masked genomes
CLEANED_ASSEMBLY=${COMP_GENOMICS}/cleaned-genomes/lecanoromycetes/${BASENAME}_cleaned.fasta
REPEATMASKED_ASSEMBLY=${MASKED_DIR}/${BASENAME}_sorted.cleaned.masked.fasta
# Output directory for the funannotate2 pipeline
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes

################################################################################################
#############                    RUNNING A FILE CHECKPOINT                          ############
################################################################################################
# RUN THE CHECKPOINT

# HAS THE GENOME BEEN ANNOTATED ALREADY? IF SO, SKIP IT AND EXIT
if [ -f "${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.gbk" ] && \
   [ -f "${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.proteins.fa" ]; then
    echo "Genome ${BASENAME} has already been processed. Skipping."
    exit 0
fi

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

# VALIDATE OUTPUT/BASENAME BEFORE DELETION
if [ -d "${OUTPUT}/${BASENAME}" ]; then
    echo "Removing the previous output of ${BASENAME} if it exists"
    rm -r ${OUTPUT}/${BASENAME}
else
    echo "Error: ${BASENAME} output is empty. Continuing with the pipeline."
    
fi

# # Remove the previous cleaned genome if it exists
# if [ -f "${COMP_GENOMICS}/cleaned-genomes/${BASENAME}_cleaned.fasta" ]; then
#     echo "Removing the previous cleaned genome if it exists"
#     rm ${COMP_GENOMICS}/cleaned-genomes/${BASENAME}_cleaned.fasta
# else
#     echo "No previous cleaned genome found, proceeding with the pipeline."
# fi

# Remove the old masked genome if it exists
if [ -f "${MASKED_DIR}/${BASENAME}_sorted.cleaned.masked.fasta" ]; then
    echo "Removing the previous masked genome if it exists"
    rm ${MASKED_DIR}/${BASENAME}_sorted.cleaned.masked.fasta
else
    echo "No previous masked genome found, proceeding with the pipeline."
fi

###############################################################################################

echo "Processing genome: ${BASENAME}"

cd ${COMP_GENOMICS}
date 

################################################################################################
############                          UNMASK GENOME                                 ############
################################################################################################
## NOTE: NCBI genomes are pre-soft masked, so to ensure they are properly processed, we need to unmask them first

source $(conda info --base)/etc/profile.d/conda.sh
conda activate seqkit

echo "Unmasking ${BASENAME} genome file"

UNMASKED_ASSEMBLY=${UNMASKED}/${BASENAME}.fasta

seqkit seq -u ${GFILE} -o ${UNMASKED}/${BASENAME}.fasta

conda deactivate

################################################################################################
############                          CLEANING GENOME                               ############
################################################################################################
# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate2

export FUNANNOTATE2_DB=/hpc/group/bio1/ewhisnant/databases/funannotate2_db

echo "${FUNANNOTATE2_DB}"

echo "Cleaning ${BASENAME} genome file"
date

cd ${GENOMES}

# Check if the genome file exists
if [ -f ${CLEANED_ASSEMBLY} ]; then
    echo "Skipping cleaning step, cleaned genome already exists."
else
    funannotate2 clean \
    -f ${UNMASKED_ASSEMBLY} \
    -o ${CLEANED_ASSEMBLY}
fi

# Check to see that the genome was cleaned
if [ -f ${CLEANED_ASSEMBLY} ]; then
    echo "Cleaned genome file created: ${CLEANED_ASSEMBLY}"
else
    echo "Error: Cleaned genome file not found for ${BASENAME}!"
    exit 1
fi

conda deactivate

################################################################################################
############                           MASKING GENOME                               ############
################################################################################################
### === note 25.09.19: This part of the pipleline is under revision. We may need to adjust the masking parameters, as we are noticing that some genomes are beinf UNDER masked.
### For example, some genomes have ~50% of the genome as TEs (depending on the program method), but RepeatMasker is only masking 1-2% of the genome.

source $(conda info --base)/etc/profile.d/conda.sh
conda activate RepeatSuite
echo "Starting RepeatMasker pipeline"

mkdir -p ${MASKED_DIR}

RepeatMasker \
    ${CLEANED_ASSEMBLY} \
    --dir ${MASKED_DIR} \
    -pa 11 \
    --xsmall \
    --species "Fungi"

# "--xsmall" to soft-mask, rather than hardmask
# "--nolow" to ignore low complexity regions (better for the prediction of exons/introns)
# "--pa 11" to use 11 threads
# "--species Fungi" to use the Fungi library

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
############                TRAINING AB INITIO GENE PREDICTIONS                     ############
################################################################################################
# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate2

# Using a pre-masked genome from RepeatMasker
echo "Training on ${BASENAME} genome"
date

funannotate2 train \
    -f ${REPEATMASKED_ASSEMBLY} \
    --cpus 12  \
    -s ${BASENAME} \
    -o ${OUTPUT}/${BASENAME}

################################################################################################
############                        RUN GENE PREDICTION                             ############
################################################################################################
echo "Predicting genes from ${BASENAME} genome"
date

funannotate2 predict -i ${OUTPUT}/${BASENAME} --cpus 12

################################################################################################
############                        RUN GENE ANNOTATION                             ############
################################################################################################
echo "Annotating genes from ${BASENAME} genome"
date

funannotate2 annotate -i ${OUTPUT}/${BASENAME} --cpus 12

conda deactivate

################################################################################################
############             ENSURE FILES ARE RENAMED TO PROPER FORMAT                  ############
################################################################################################
echo "Renaming files in ${OUTPUT}/${BASENAME}/annotate_results"
date
TARGET_DIR=${OUTPUT}/${BASENAME}/annotate_results # Directory containing the files to rename

# Change to the target directory
cd "${TARGET_DIR}"

# Define the extensions to match
EXTENSIONS=("fasta" "gbk" "gff3" "proteins.fa" "summary.json" "tbl" "transcripts.fa")

# Loop through all files with the specified extensions
for ext in "${EXTENSIONS[@]}"; do
    for file in *."${ext}"; do
        # Check if the file exists
        if [ -e "$file" ]; then
            # Rename the file
            mv "$file" "${BASENAME}.${ext}"
            
            # Check if the rename was successful
            if [ $? -eq 0 ]; then
                echo "Renamed $file to ${BASENAME}.${ext}"
            else
                echo "Error in renaming $file. Skipping."
            fi
        fi
    done
done

# Record the end time
END_TIME=$(date +%s)

# Calculate the total runtime in seconds
RUNTIME=$(($END_TIME - $START_TIME))

cd /hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-logs/

echo "Runtime for ${BASENAME}; ${SLURM_ARRAY_TASK_ID}: $((RUNTIME / 60)) minutes and $((RUNTIME % 60)) seconds" >> runlength.txt