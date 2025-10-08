#!/usr/bin/bash

#SBATCH --mem-per-cpu=16G   # Memory per CPU
#SBATCH -c 12               # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-logs/lecanoromycetes/clean_mask_pred_usnea.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-logs/lecanoromycetes/clean_mask_pred_usnea.err
#SBATCH --partition=common

# Record the start time
START_TIME=$(date +%s)

################################################################################################
#############                   RUNNING FUNANNOTATE2 PIPELINE                       ############
################################################################################################

# SET VARIABLES
COMP_GENOMICS=/hpc/group/bio1/ewhisnant/comp-genomics                  # Base directory for outputs for comp-genomics
GENOMES=${COMP_GENOMICS}/filtered-genomes/lecanoromycetes              # Directory containing genome files

# incertae_sedis_incertae_sedis_NCBI_GCA_964254515.1.fa 

#CHANGE ME TO FILE THAT NEEDS TO BE PROCESSED !! ALSO CHANGE THE LOG NAME ABOVE
FILE_TO_RUN_SINGLE=Usnea_florida_ATCC_18376_JGI_NA.fa

# incertae_sedis_incertae_sedis_NCBI_GCA_964254515.1.fa

# Ebollia_carnea_CBS_143170_JGI_NA.fa 
    ### Error was thrown due to the original name being outdated
# incertae_sedis_incertae_sedis_NCBI_GCA_964254515.1.fa 

GFILE=${GENOMES}/${FILE_TO_RUN_SINGLE}                                 # SET BASE GENOME FILE
BASENAME=$(basename "${GFILE}" .fa)                                    # Extract the base name of the genome file
MASKED_DIR=${COMP_GENOMICS}/masked-genomes/lecanoromycetes/${BASENAME} # Directory for masked genomes

OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes

CLEANED_ASSEMBLY=${COMP_GENOMICS}/cleaned-genomes/lecanoromycetes/${BASENAME}_cleaned.fasta
REPEATMASKED_ASSEMBLY=${MASKED_DIR}/${BASENAME}_sorted.cleaned.masked.fasta

echo "Processing genome: ${BASENAME}"

################################################################################################
#############                    RUNNING A FILE CHECKPOINT                          ############
################################################################################################

# VALIDATE GFILE
if [ -z "${GFILE}" ]; then
    echo "Error: No genome file found for ${BASENAME}. Exiting."
    exit 1
fi

# VALIDATE BASENAME IS NOT BLANK -- THIS PREVENTS THE SCRIPT FROM RUNNING AND POTENTIALLY DELETING FILES
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

# Remove the old masked genome if it exists
if [ -f "${MASKED_DIR}/${BASENAME}_sorted.cleaned.masked.fasta" ]; then
    echo "Removing the previous masked genome if it exists"
    rm ${MASKED_DIR}/${BASENAME}_sorted.cleaned.masked.fasta
else
    echo "No previous masked genome found, proceeding with the pipeline."
fi

#########################################################################################################
# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate2

export FUNANNOTATE2_DB=/hpc/group/bio1/ewhisnant/databases/funannotate2_db
   
################################################################################################
############                          CLEANING GENOME                               ############
################################################################################################

echo "Cleaning ${BASENAME} genome file"
date

cd ${GENOMES}

# Check if the genome file exists
if [ -f ${CLEANED_ASSEMBLY} ]; then
    echo "Skipping cleaning step, cleaned genome already exists."
else
    funannotate2 clean \
    -f ${GFILE} \
    -o ${CLEANED_ASSEMBLY}
fi

conda deactivate

################################################################################################
############                           MASKING GENOME                               ############
################################################################################################
echo "Skipping RepeatMasker step, using default settings"

source $(conda info --base)/etc/profile.d/conda.sh
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
############                TRAINING AB INITIO GENE PREDICTIONS                     ############
################################################################################################
# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate2

export FUNANNOTATE2_DB=/hpc/group/bio1/ewhisnant/databases/funannotate2_db

# Using a pre-masked genome from RepeatMasker
echo "Training on ${BASENAME} genome"
date

funannotate2 train \
    -f ${CLEANED_ASSEMBLY} \
    --cpus 12  \
    -s Lecanoromycetes \
    -o ${OUTPUT}/${BASENAME}

################################################################################################
############                        RUN GENE PREDICTION                             ############
################################################################################################
echo "Predicting genes from ${BASENAME} genome"
date

funannotate2 predict -i ${OUTPUT}/${BASENAME}/ --cpus 12

################################################################################################
############                        RUN GENE ANNOTATION                             ############
################################################################################################
echo "Annotating genes from ${BASENAME} genome"
date

funannotate2 annotate -i ${OUTPUT}/${BASENAME}/ --cpus 12

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

echo "Runtime for ${BASENAME}; NA: $((RUNTIME / 60)) minutes and $((RUNTIME % 60)) seconds" >> runlength.txt