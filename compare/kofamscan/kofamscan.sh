#!/usr/bin/bash

#SBATCH --mem-per-cpu=16G  # adjust as needed
#SBATCH -c 12 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/kofamscan/test.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/kofamscan/test.err
#SBATCH --partition=common

KOFAM_SCAN_DIR=/hpc/group/bio1/ewhisnant/software/kofamscan/bin/kofam_scan-1.3.0
KOFAM_SCAN_OUT=/hpc/group/bio1/ewhisnant/comp-genomics/kofamscan
COMP_GENOMICS_DIR=/hpc/group/bio1/ewhisnant/comp-genomics
GENOME_DIR=/hpc/group/bio1/ewhisnant/armaleo-data/Clagr3/funannotations/test-w-repeatsuite/predict_results/Cladonia_grayi.proteins.fa

# THIS WILL MOST LIKELY HAVE TO BE RUN AFTER A GENE PREDICTION STEP IN FUNANNOTATE

${KOFAM_SCAN_DIR}/exec_annotation -o ${KOFAM_SCAN_OUT} -f detail-tsv -i ${GENOME_DIR}

