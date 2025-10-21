#!/usr/bin/bash

#SBATCH --mem-per-cpu=3G   # Memory per CPU
#SBATCH -c 16               # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/logs/lecanoromyctes_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/logs/lecanoromycetes_%a.err
#SBATCH --partition=scavenger
#SBATCH -t 15-00:00:00
#SBATCH --array=109 # Array range (change after quality control step)
################################################################################################
# NOTE 25.10.16:

# === One more genome still running. 114/115 are complete.
# [29] Gyalolechia_ehrenbergii_NCBI_GCA_023646125.1

################################################################################################
#############                   RUNNING FUNANNOTATE2 PIPELINE                       ############
################################################################################################

# SET VARIABLES
THREADS=16
COMP_GENOMICS=/hpc/group/bio1/ewhisnant/comp-genomics  # Base directory for outputs for comp-genomics
GENOMES=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/select-lecanoromycetes-25.09.03/genomes/raw # Directory containing genome files
UNMASKED=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/select-lecanoromycetes-25.09.03/genomes/unmasked
GENOME_FILES=($(ls ${GENOMES}/*.fa)) #List of genome files to process
GFILE=${GENOME_FILES[$SLURM_ARRAY_TASK_ID]} # Create the index for the array job
BASENAME=$(basename "${GFILE}" .fa) # Extract the base name of the genome file

# Output directory for the funannotate2 pipeline
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/lecanoromycetes

F2_INTERMEDIATE=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/f2-intermediate-files
MASKED_DIR=${F2_INTERMEDIATE}/masked-genomes/lecanoromycetes    # Directory for masked genomes
CLEANED_DIR=${F2_INTERMEDIATE}/cleaned-genomes/lecanoromycetes

################################################################################################
#############                    RUNNING A FILE CHECKPOINT                          ############
################################################################################################
# RUN THE CHECKPOINT

# HAS THE GENOME BEEN ANNOTATED ALREADY? IF SO, SKIP IT AND EXIT
if [ -f "${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.gbk" ] && \
   [ -f "${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.proteins.fa" ]; then
    echo "Genome ${BASENAME} has likely already been processed. Checking for proper nuclear and mito separation."

    # Check to see if renaming and mito splitting was done
    if [ -s "${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.nuclear.fasta" ] && \
       [ -f "${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.mito.fasta" ]; then
        echo "=== Renaming and mito splitting already completed for ${BASENAME}. Exiting."
        exit 0
    else
        echo "=== Renaming and mito splitting not completed for ${BASENAME}. Continuing."

        source $(conda info --base)/etc/profile.d/conda.sh
        conda activate seqkit

        echo "=== If mito DNA was identified, funannotate2 has edited the FASTA headers accordingly."

        echo "=== Remaining mitochondrial contigs (if present) will be printed below:"
        grep "mito" ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.fasta

        echo "=== Separating newly identified mitochondrial contigs with seqkit (if present) ==="

        seqkit grep -nvrip "mito" ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.fasta > ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.nuclear.fasta # Keeps only the nuclear DNA
        seqkit grep -nrip "mito" ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.fasta > ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.mito.fasta # Keeps only the mito DNA

        echo "=== Saved nuclear contigs to: ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.nuclear.fasta"
        echo "=== Saved mito contigs to: ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.mito.fasta"

        conda deactivate
        exit 0
    fi
    
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
    echo "${BASENAME} output is empty. Continuing with the pipeline."
    
fi

###############################################################################################
echo "# 1. Pre-processing genome: ${BASENAME}"
################################################################################################
############          PRE-PROCESSING: UNMASK GENOME & REMOVE MITO CONTIGS           ############
################################################################################################
## NOTE: NCBI genomes are pre-soft masked, so to ensure they are properly processed, we need to unmask them first

mkdir -p ${F2_INTERMEDIATE} # Create the intermediate file

source $(conda info --base)/etc/profile.d/conda.sh
conda activate seqkit

# === Unmasking the genome
echo "=== Ensuring genome is not masked. Unmasking ${BASENAME} genome file ==="

UNMASKED_ASSEMBLY=${UNMASKED}/${BASENAME}.fasta

seqkit seq -u ${GFILE} -o ${UNMASKED_ASSEMBLY}

# === Removing mitochondrial DNA
mkdir -p ${CLEANED_DIR}/nuclear

echo "=== Removing preliminary mitochondrial contigs with seqkit ==="
seqkit grep -nvrip "mito" ${UNMASKED_ASSEMBLY} > ${CLEANED_DIR}/nuclear/${BASENAME}_nuclear.fa # Keeps only the nuclear DNA
conda deactivate

###############################################################################################
echo "# 2. Cleaning genome: ${BASENAME}"
################################################################################################
############                          CLEANING GENOME                               ############
################################################################################################

# === Cleaning with F2 clean
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate2

export FUNANNOTATE2_DB=/hpc/group/bio1/ewhisnant/databases/funannotate2_db

mkdir -p ${CLEANED_DIR}/cleaned # Make the cleaned directory to store the cleaned genomes
CLEANED_ASSEMBLY=${CLEANED_DIR}/cleaned/${BASENAME}_cleaned.fa

# === Check to see if the file already exists
# === If not, run f2 clean
# === If it does, skip and move on...

if [ -f "$CLEANED_ASSEMBLY" ]; then
    echo "=== Cleaned assembly detected -- skipping this step! ==="
else
    echo "=== Running funannotate2 clean for ${BASENAME} ==="
    funannotate2 clean \
        -f ${CLEANED_DIR}/nuclear/${BASENAME}_nuclear.fa \
        -o ${CLEANED_ASSEMBLY}

    # sanity check
    if [ -f "$CLEANED_ASSEMBLY" ]; then
        echo "=== Cleaned genome file created: $CLEANED_ASSEMBLY ==="
    else
        echo "[Error]: funannotate2 clean failed for ${BASENAME}"
        exit 1
    fi
fi

conda deactivate


###############################################################################################
echo "# 3. Masking genome with EarlGrey: ${BASENAME}"
################################################################################################
############                           MASKING GENOME                               ############
################################################################################################
### === note 25.09.19: This part of the pipleline is under revision. We may need to adjust the masking parameters, as we are noticing that some genomes are beinf UNDER masked.
### For example, some genomes have ~50% of the genome as TEs (depending on the program method), but RepeatMasker is only masking 1-2% of the genome.

# === Run EarlGrey
source $(conda info --base)/etc/profile.d/conda.sh
conda activate earlgrey

mkdir -p ${MASKED_DIR}/${BASENAME}

# Create the softmasked genome variable
SOFTMASKED_ASSEMBLY=${MASKED_DIR}/${BASENAME}/${BASENAME}_EarlGrey/${BASENAME}_summaryFiles/${BASENAME}.softmasked.fasta

# === Check to see if earlgrey has been run on the genome previously
# === If so, then skip to the next step
# === If not, run earlgrey to annotate TEs and repeats

if [ -f ${SOFTMASKED_ASSEMBLY} ]; then

    echo "=== Soft-masked genome detected, moving on to gene prediction ==="
    echo "=== Path to soft-masked genome: ${SOFTMASKED_ASSEMBLY} ==="

else
    echo "=== Masking ${BASENAME} genome file with EarlGrey ==="

    earlGrey \
        -g ${CLEANED_ASSEMBLY} \
        -s ${BASENAME} \
        -o ${MASKED_DIR}/${BASENAME} \
        -t ${THREADS} \
        -e yes \
        -i 10 \
        -f 1000 \
        -c no \
        -m no \
        -d yes \
        -n 20 \
        -a 3

 

    # Check to see if the masking was completed
    if [ -f ${SOFTMASKED_ASSEMBLY} ]; then
        echo "=== Soft-masked genome file created: ${SOFTMASKED_ASSEMBLY} ==="
    else
        echo "[Error]: Soft-masked genome file not found for ${BASENAME}!"
        exit 1
    fi
fi

conda deactivate
###############################################################################################
echo "# 4. Training ab initio gene predictions: ${BASENAME}"
################################################################################################
############                TRAINING AB INITIO GENE PREDICTIONS                     ############
################################################################################################

source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate2

# Using a pre-masked genome from EarlGrey

funannotate2 train \
    -f ${SOFTMASKED_ASSEMBLY} \
    --cpus ${THREADS}  \
    -s ${BASENAME} \
    -o ${OUTPUT}/${BASENAME}

###############################################################################################
echo "# 5. Predicting genes: ${BASENAME}"
################################################################################################
############                        RUN GENE PREDICTION                             ############
################################################################################################

funannotate2 predict -i ${OUTPUT}/${BASENAME} --cpus ${THREADS}


###############################################################################################
echo "# 6. Annotating genes: ${BASENAME}"
################################################################################################
############                        RUN GENE ANNOTATION                             ############
################################################################################################

funannotate2 annotate -i ${OUTPUT}/${BASENAME} --cpus ${THREADS}

conda deactivate


###############################################################################################
echo "# 7. Renaming F2 output files: ${BASENAME}"
################################################################################################
############             ENSURE FILES ARE RENAMED TO PROPER FORMAT                  ############
################################################################################################

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
                echo "=== Renamed $file to ${BASENAME}.${ext} ==="
            else
                echo "=== Error in renaming $file. Skipping. ==="
            fi
        fi
    done
done


###############################################################################################
echo "# 8. Splitting mito contigs: ${BASENAME}"
################################################################################################
############                          REMOVE MITO DNA                               ############
################################################################################################
# Note 09.30.25: Need to see what the annotation is once the trial has finished running 
source $(conda info --base)/etc/profile.d/conda.sh
conda activate seqkit

echo "=== If mito DNA was identified, funannotate2 has edited the FASTA headers accordingly."

echo "=== Remaining mitochondrial contigs (if present) will be printed below:"
grep "mito" ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.fasta

echo "=== Separating newly identified mitochondrial contigs with seqkit (if present) ==="

seqkit grep -nvrip "mito" ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.fasta > ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.nuclear.fasta # Keeps only the nuclear DNA
seqkit grep -nrip "mito" ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.fasta > ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.mito.fasta # Keeps only the mito DNA

echo "=== Saved nuclear contigs to: ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.nuclear.fasta"
echo "=== Saved mito contigs to: ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.mito.fasta"

conda deactivate