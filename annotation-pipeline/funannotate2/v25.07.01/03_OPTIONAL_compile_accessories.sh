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
ANNOTATE_DIR=${OUTPUT}/${BASENAME}/annotate_accessory
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

################################################################################################
############         STEP 3: COMPILE INTERMEDIATE ANNOTATIONS AND FINALIZE          ############
################################################################################################

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate_hydra

# INPUT WILL BE THE GENBANK FILE FROM FUNANNOTATE2 ANNOTATE

funannotate annotate \
    -i ${IN_GBK} \
    -o ${ANNOTATE_DIR} \
    --species "${BASENAME}" \
    --antismash ${ANTISMASH}/Cladonia_grayi.gbk \
    --iprscan ${IPRSCAN}/interproscan_results.xml \
    --signalp ${SIGNALP}/prediction_results.txt \
    --busco_db "Ascomycota" \
    --renumber_antismash \
    --tmpdir ${OUTPUT}/tmp \
    --cpus 16

conda deactivate

echo "Once this is done, run 04_finalize_annotations.sh"
date