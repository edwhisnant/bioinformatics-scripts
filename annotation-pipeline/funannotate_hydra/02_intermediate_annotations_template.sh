#!/usr/bin/bash

#SBATCH --mem-per-cpu=32G  # Memory per CPU
#SBATCH -c 16               # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control/logs/clean_mask_pred_%A_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control/logs/clean_mask_pred_busco_%A_%a.err
#SBATCH --partition=common
#SBATCH --array=1-442%6 # Array range (change after prediction step)

################################################################################################
# This script is for curating the intermediate annotations from funannotate predict
# The intermediate annotations consist of the following:
# 1. InterProScan5 XML file
# 2. SignalP pre-computed results (-org eukarya -input nucleotide fasta file)
# 3. antiSMASH secondary metabolism results (GBK file from output)
# 4. DeepLoc pre-computed results
# 5. EffectorP pre-computed results
################################################################################################
# Note: These processes will not be able to run at the same time, but must be done in tandem.
# This is because there will be issues removing temporary files if they are run in parallel.
################################################################################################

COMP_GENOMICS=/hpc/group/bio1/ewhisnant/comp-genomics/  # Base directory for outputs
GENOMES=${COMP_GENOMICS}/genomes # Directory containing genome files
GENOME_FILES=($(ls ${GENOMES}/*.fa)) #List of genome files to process
GFILE=${GENOME_FILES[$SLURM_ARRAY_TASK_ID]} # Create the index for the array job
BASENAME=$(basename "${GFILE}" .fa) # Extract the base name of the genome file
MASKED_DIR=${COMP_GENOMICS}/masked-genomes/ # Directory for masked genomes
PREDICT_DIR=${COMP_GENOMICS}/predictions/${BASENAME}
CPUS=10
BUSCO_DB=pezizomycotina


CLEANED_ASSEMBLY=${COMP_GENOMICS}/cleaned-genomes/${BASENAME}_cleaned.fasta
REPEATMASKED_ASSEMBLY=${MASKED_DIR}/${BASENAME}_cleaned.masked.fasta
PROTEINS=${PREDICT_DIR}/predict_results/${BASENAME}.proteins.fa
GENBANK=${PREDICT_DIR}/predict_results/${BASENAME}.gbk

INTERMEDIATE_FILES=${PREDICT_DIR}/intermediate_annotations
INTERPROSCAN=/hpc/group/bio1/ewhisnant/software/my_interproscan/interproscan-5.73-104.0

echo "Processing genome: ${BASENAME}"

################################################################################################
############                   STEP 2: INTERMEDIATE ANNOTATIONS                     ############
################################################################################################

################################################################################################
############                           InterProScan5                                ############
################################################################################################
# InterProScan5 has been run and tested 03.28.2025. It is currently running as expected.

echo "Starting InterProScan5"

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate java11 #InterProScan5 requires Java 11

# INITIALIZE DIRECTORIES

if [ ! -d ${PREDICT_DIR}/interproscan_temp ]; then
    mkdir -p ${PREDICT_DIR}/interproscan_temp
else
    echo "The temporary directory already exists"
    echo "Please remove the temporary directory and try again"
    echo ${PREDICT_DIR}/interproscan_temp
    exit 1
fi

if [ ! -d ${INTERMEDIATE_FILES}/interproscan_results ]; then
    mkdir -p ${INTERMEDIATE_FILES}/interproscan_results
else
    echo "The temporary directory already exists"
    echo "Please remove the results directory and try again"
    echo ${INTERMEDIATE_FILES}/interproscan_results
    exit 1
fi

echo "Running InterProScan"
echo `date`

bash ${INTERPROSCAN}/interproscan.sh \
    -i ${PROTEINS} --seqtype p \
    --disable-precalc \
    --iprlookup --goterms --pathways \
    --output-file-base ${INTERMEDIATE_FILES}/interproscan_results \
    --tempdir ${PREDICT_DIR}/interproscan_temp \
    --verbose \
    -cpu 16

# REMOVE THE TEMPORARY DIRECTORY
rm -r ${PREDICT_DIR}/interproscan_temp
conda deactivate

################################################################################################
############                              SIGNALP                                   ############
################################################################################################
# THIS WORKS AND HAS BEEN TESTED (3.25.2025)

source $(conda info --base)/etc/profile.d/conda.sh
conda activate signalp60

echo "Starting SignalP"
echo `date`

signalp6 --fastafile ${PROTEINS} \
         --organism eukarya \
         --output_dir ${INTERMEDIATE_FILES}/signalp  \
         --format txt \
         --mode fast

conda deactivate

################################################################################################
############                             EFFECTORP                                  ############
################################################################################################
# EFFECTORP MUST BE RUN AFTER SIGNALP, AS SIGNALP CREATES THE INPUT FILE FOR EFFECTORP
# EffectorP is was tested and functions (03.25.2025)

echo 'EffectorP starting' `date`

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate_hydra

cd /hpc/group/bio1/ewhisnant/software/EffectorP_3.0.0-beta
mkdir -p ${INTERMEDIATE_FILES}/effectorp

python EffectorP.py \
-i ${INTERMEDIATE_FILES}/signalp/processed_entries.fasta \
-o ${INTERMEDIATE_FILES}/effectorp/effectors.txt

conda deactivate

################################################################################################
############                             ANTISMASH                                  ############
################################################################################################
# anitSMASH has been run and tested 3.19.2025. It is currently running as expected.
echo `date`
echo "Starting antiSMASH"

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate antismash

# RUN ANTISMASH
antismash \
    -t fungi \
    --output-dir ${INTERMEDIATE_FILES}/antismash \
    -c 12 \
    --genefinding-tool none \
    ${GENBANK}

conda deactivate

################################################################################################
############                              DEEPLOC                                   ############
################################################################################################
# DeepLoc has been run and tested 3.19.2025. It is currently running as expected.
source $(conda info --base)/etc/profile.d/conda.sh
conda activate deeploc20

deeploc2 \
    -f ${PROTEINS} \
    -o ${INTERMEDIATE_FILES}/deeploc

conda deactivate

echo `date`

################################################################################################
############                 MOVE ON TO FINALIZE THE ANNOTATION                     ############
################################################################################################


