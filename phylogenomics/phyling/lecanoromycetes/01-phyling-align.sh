#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/phyling/lecanoromycetes-align.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/phyling/lecanoromycetes-align.err
#SBATCH --partition=scavenger
#SBATCH -t 2-00:00:00

################################################################################################
## === PHYling Alignment Script ===
## This script performs multiple sequence alignment using PHYling. The input is a directory of protein FASTA files.
## This module will extract single copy orthologs, perform MSA using MUSCLE, and trim the alignments using ClipKIT.
## The output will be a directory containing the aligned sequences for each marker, which can is fed into the next step (phyling tree or filter)
################################################################################################
# NOTE:
# 25.10.17: Running this script using the Lecanoromycetes protein fasta files from funannotate2 v25.09.29
# Something is causing the alignment script to fail.

# 6:28 PM Trying to re-install phyling in a fresh conda env to see if that helps



################################################################################################

# Define variables
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/lecanoromycetes
OUTPUT=/work/edw36/comp-genomics/compare/phyling/lecanoromycetes

# # Create a temporary directory for input files
TEMP_DIR=$(mktemp -d /work/edw36/comp-genomics/compare/phyling/temp-dir.XXXXXX)

# Find all protein FASTA files in the specified directory and copy them to the temporary directory
echo "Copying protein FASTA files to temporary directory: ${TEMP_DIR}"
find "${IN_DIR}" -path "*/annotate_results/*proteins.fa" -exec cp {} ${TEMP_DIR} \;

# === OR USE A PRE-COMPILED DIRECTORY ===
# TEMP_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/temp-dir.sT42Fz

# === PHYling requires you to have the output directory created beforehand ===
mkdir -p ${OUTPUT}/align

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate phyling

echo "Running PHYling..."

# == 1. RUN THE MSA (ALIGNMENT)
phyling align \
    -I ${TEMP_DIR} \
    -o ${OUTPUT}/align \
    -m ascomycota_odb12 \
    -M muscle \
    -t 32 \
    -v \
    --seqtype pep

conda deactivate

echo "You have two next steps to choose from:"
echo "=== 1. Run the filtering step to select the best models for tree building (optional)"
echo "=== 2. Run the tree building step directly using all models"
echo "Remember to clean up temporary directory when done."


##############################
# How to run phyling align:
##############################
# phyling align -h
# usage: phyling align (-i file [files ...] | -I directory) -m directory [-o directory] [--seqtype {dna,pep,AUTO}] [-E float] [-M {hmmalign,muscle}]
#                      [--non_trim] [-t THREADS] [-v] [-h]

# Perform multiple sequence alignment (MSA) on orthologous sequences that match the hmm markers across samples.

# Initially, hmmsearch is used to match the samples against a given markerset and report the top hit of each sample for each hmm marker, representing
# "orthologs" across all samples. In order to build a tree, minimum of 4 samples should be used. If the bitscore cutoff file is present in the hmms folder,
# it will be used as the cutoff. Otherwise, an evalue of 1e-10 will be used as the default cutoff.

# Sequences corresponding to orthologs found in more than 4 samples are extracted from each input. These sequences then undergo MSA with hmmalign or
# muscle. The resulting alignments are further trimmed using clipkit by default. You can use the --non_trim option to skip the trimming step. Finally, The
# alignment results are output separately for each hmm marker.

# Required arguments:
#   -i file [files ...], --inputs file [files ...]
#                         Query pepetide/cds fasta or gzipped fasta
#   -I directory, --input_dir directory
#                         Directory containing query pepetide/cds fasta or gzipped fasta
#   -m directory, --markerset directory
#                         Directory of the HMM markerset

# Options:
#   -o directory, --output directory
#                         Output directory of the alignment results (default: phyling-align-[YYYYMMDD-HHMMSS] (UTC timestamp))
#   --seqtype {dna,pep,AUTO}
#                         Input data sequence type (default: AUTO)
#   -E float, --evalue float
#                         Hmmsearch reporting threshold (default: 1e-10, only being used when bitscore cutoff file is not available)
#   -M {hmmalign,muscle}, --method {hmmalign,muscle}
#                         Program used for multiple sequence alignment (default: hmmalign)
#   --non_trim            Report non-trimmed alignment results
#   -t THREADS, --threads THREADS
#                         Threads for hmmsearch and the number of parallelized jobs in MSA step. Better be multiple of 4 if using more than 8 threads
#   -v, --verbose         Verbose mode for debug
#   -h, --help            show this help message and exit