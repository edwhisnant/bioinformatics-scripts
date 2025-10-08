#!/usr/bin/bash

#SBATCH --mem-per-cpu=32G   # Memory per CPU
#SBATCH -c 12               # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-logs/lecanoromycetes/lecanoromyctes_accessories_%A_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-logs/lecanoromycetes/lecanoromycetes_accessories_%A_%a.err
#SBATCH --partition=common
#SBATCH --array=1-108%11 # Array range (change after quality control step)


# SET VARIABLES
COMP_GENOMICS=/hpc/group/bio1/ewhisnant/comp-genomics  # Base directory for outputs for comp-genomics
GENOMES=${COMP_GENOMICS}/filtered-genomes/lecanoromycetes # Directory containing genome files
GENOME_FILES=($(ls ${GENOMES}/*.fa)) #List of genome files to process
GFILE=${GENOME_FILES[$SLURM_ARRAY_TASK_ID]} # Create the index for the array job
BASENAME=$(basename "${GFILE}" .fa) # Extract the base name of the genome file
MASKED_DIR=${COMP_GENOMICS}/masked-genomes/lecanoromycetes/${BASENAME} # Directory for masked genomes
CLEANED_ASSEMBLY=${COMP_GENOMICS}/cleaned-genomes/lecanoromycetes/${BASENAME}_cleaned.fasta
REPEATMASKED_ASSEMBLY=${MASKED_DIR}/${BASENAME}_sorted.cleaned.masked.fasta
# Output directory for the funannotate2 pipeline
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes

# INTERMEDIATE FILES (for accessory annotations)
INTERMEDIATE_FILES=${OUTPUT}/${BASENAME}/intermediate_annotations
ANNOTATE_DIR=${OUTPUT}/${BASENAME}/annotate_final
IN_PROTEINS=${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.proteins.fa
IN_GBK=${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.gbk

# OUTPUTS FROM STEP 2: INTERMEDIATE ANNOTATIONS
IPRSCAN=${INTERMEDIATE_FILES}/interproscan_results
SIGNALP=${INTERMEDIATE_FILES}/signalp
EFFECTORP=${INTERMEDIATE_FILES}/effectorp
ANTISMASH=${INTERMEDIATE_FILES}/antismash
DEEPLOC=${INTERMEDIATE_FILES}/deeploc_out

# Prevent the script from running if the inputs are empty
if [ -z ${BASENAME} ]; then
    echo "Error: BASENAME is empty. Exiting."
    exit 1
fi

# Make the intermediate directories
mkdir -p ${INTERMEDIATE_FILES}

################################################################################################
############                           InterProScan5                                ############
################################################################################################
# InterProScan5 has been run and tested 03.28.2025. It is currently running as expected.

echo "Starting InterProScan5"

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate java11 #InterProScan5 requires Java 11

# INITIALIZE DIRECTORIES

if [ ! -d ${OUTPUT}/interproscan_temp ]; then
    mkdir -p ${OUTPUT}/interproscan_temp
else
    echo "The temporary directory already exists"
    echo "Please remove the temporary directory and try again"
    echo ${OUTPUT}/interproscan_temp
    rm -r ${OUTPUT}/interproscan_temp
    mkdir -p ${OUTPUT}/interproscan_temp
fi

if [ ! -d ${IPRSCAN} ]; then
    mkdir -p ${IPRSCAN}
else
    echo "The temporary directory already exists"
    echo "Please remove the results directory and try again"
    rm -r ${IPRSCAN}
    echo "Removing ${IPRSCAN}"
fi

echo "Running InterProScan"
echo `date`

bash ${INTERPROSCAN}/interproscan.sh \
    -i ${IN_PROTEINS} --seqtype p \
    --disable-precalc \
    --iprlookup --goterms --pathways \
    --output-file-base ${IPRSCAN} \
    --tempdir ${OUTPUT}/${BASENAME}/interproscan_temp \
    -cpu 16

# REMOVE THE TEMPORARY DIRECTORY
rm -r ${OUTPUT}/interproscan_temp
conda deactivate

################################################################################################
############                              SIGNALP                                   ############
################################################################################################
# THIS WORKS AND HAS BEEN TESTED (3.25.2025)

source $(conda info --base)/etc/profile.d/conda.sh
conda activate signalp60

echo "Starting SignalP"
echo `date`

signalp6 --fastafile ${IN_PROTEINS} \
         --organism eukarya \
         --output_dir ${SIGNALP}  \
         --format txt \
         --mode fast

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
    --output-dir ${ANTISMASH} \
    -c 12 \
    --genefinding-tool none \
    ${IN_GBK}

conda deactivate

echo "Once this is finished, run 03_compile_accessories.sh"
echo `date`
