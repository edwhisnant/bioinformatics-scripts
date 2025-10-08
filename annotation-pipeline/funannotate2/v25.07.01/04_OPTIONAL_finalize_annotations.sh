#!/usr/bin/bash

#SBATCH --mem-per-cpu=16G  # adjust as needed
#SBATCH -c 12 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/armaleo-data/funannotate2/scripts/logs/f2_clagr3_final_annot.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/armaleo-data/funannotate2/scripts/logs/f2_clagr3_final_annot.err
#SBATCH --partition=common

# funannotate2 annotate -h
# usage: funannotate2 annotate [-i] [-f] [-t] [-g] [-o] [-a] [-s] [-st] [--cpus] [--tmpdir] [--curated-names] [-h]
#                              [--version]

# Add functional annotate to gene models

# Required arguments:
#   -i , --input-dir     funannotate2 output directory
#   -f , --fasta         genome in FASTA format
#   -t , --tbl           genome annotation in TBL format
#   -g , --gff3          genome annotation in GFF3 format
#   -o , --out           Output folder name

# Optional arguments:
#   -a , --annotations   Annotations files, 3 column TSV [transcript-id, feature, data]
#   -s , --species       Species name, use quotes for binomial, e.g. "Aspergillus fumigatus"
#   -st , --strain       Strain/isolate name
#   --cpus               Number of CPUs to use (default: 2)
#   --tmpdir             volume to write tmp files (default: /tmp)
#   --curated-names      Path to custom file with gene-specific annotations (tab-delimited: gene_id annotation_type
#                        annotation_value)

# Other arguments:
#   -h, --help           show this help message and exit
#   --version            show program's version number and exit

GENOME=/hpc/group/bio1/ewhisnant/armaleo-data/Clagr3/assemblies/Clagr3_AssemblyScaffolds.fasta
BASENAME=$(basename "${GENOME}" .fasta) # Extract the base name of the genome file

# Define the variables for the rest of the anlaysis
MASKED_DIR=/hpc/group/bio1/ewhisnant/armaleo-data/funannotate2/clagr3_f2/masked-genomes/softmask-modeled-ltr
CLEANED_ASSEMBLY=/hpc/group/bio1/ewhisnant/armaleo-data/funannotate2/clagr3_f2/cleaned-genomes/${BASENAME}_cleaned.fasta
REPEATMASKED_ASSEMBLY=${MASKED_DIR}/${BASENAME}_sorted.cleaned.softmasked.fasta

ACCESSORY_ANNOT_DIR=/hpc/group/bio1/ewhisnant/armaleo-data/funannotate2/clagr3_f2/softmask/annotate_accessory/annotate_results
FINAL_ANNOT_DIR=/hpc/group/bio1/ewhisnant/armaleo-data/funannotate2/clagr3_f2/softmask/annotate_final

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
ACCESSORY_ANNOT_DIR=${OUTPUT}/${BASENAME}/annotate_accessory

# Prevent the script from running if the inputs are empty
if [ -z ${BASENAME} ]; then
    echo "Error: BASENAME is empty. Exiting."
    exit 1
fi

################################################################################################
############                   FINAL ANNOTATION FUNANNOTATE2                        ############
################################################################################################

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate2

export FUNANNOTATE2_DB=/hpc/group/bio1/ewhisnant/databases/funannotate2_db

cd /hpc/group/bio1/ewhisnant/armaleo-data/funannotate2

echo "Finalizing funannotate2 on ${BASENAME} genome"
date

funannotate2 annotate \
    -f ${CLEANED_ASSEMBLY} \
    -t ${ACCESSORY_ANNOT_DIR}/${BASENAME}.tbl \
    -g ${ACCESSORY_ANNOT_DIR}/${BASENAME}.gff3 \
    -o ${FINAL_ANNOT_DIR}\
    -s "Ascomycota" \
    --cpus 12

conda deactivate

