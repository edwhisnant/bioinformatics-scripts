#!/usr/bin/bash

#SBATCH --mem-per-cpu=1G  # adjust as needed
#SBATCH -c 16 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/mafft/lecanoromycetes_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/mafft/lecanoromycetes_%a.err
#SBATCH --partition=scavenger
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=mafft-v25.09.01
#SBATCH -t 7-00:00:00
#SBATCH --array=1-160 # Array range


# === Define variables ===
VERSION=v25.08.19
RESULTS=Results_Aug22
LIST=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/Orthogroups/OGs_for_annotation_list.txt
FASTA_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/Refined_Orthogroups
OG_MSA_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/MSA_Refined_Orthogroups
THREADS=16

# === Get the correct orthogroup file and ensure it is in unix format ===
dos2unix ${LIST}

# === Create the index for the array job ===
FASTA_FILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$LIST")
BASENAME=$(basename "$FASTA_FILE" .fa)

# === Checkpoint to ensure there is a real file
if [ -z "$FASTA_FILE" ]; then
  echo "No FASTA file found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"
  exit 1
fi

if [ -z "${BASENAME}" ]; then
  echo "BASENAME empty"
  exit 1
fi

# === Initialize output directory ===
mkdir -p ${OG_MSA_DIR}

# === This script will use MAFFT to conduct a multiple sequence alignment of Orthogroups from OrthoFinder ===
# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate orthofinder

# Running MAFFT using recommended settings from https://mafft.cbrc.jp/alignment/software/manual/manual.html
mafft --localpair --maxiterate 1000 --thread ${THREADS} ${FASTA_DIR}/${FASTA_FILE} > ${OG_MSA_DIR}/${BASENAME}.fa

conda deactivate


#############################################
# How to use MAFFT:
# mafft --help
# ------------------------------------------------------------------------------
#   MAFFT v7.525 (2024/Mar/13)
#   https://mafft.cbrc.jp/alignment/software/
#   MBE 30:772-780 (2013), NAR 30:3059-3066 (2002)
# ------------------------------------------------------------------------------
# High speed:
#   % mafft in > out
#   % mafft --retree 1 in > out (fast)

# High accuracy (for <~200 sequences x <~2,000 aa/nt):
#   % mafft --maxiterate 1000 --localpair  in > out (% linsi in > out is also ok)
#   % mafft --maxiterate 1000 --genafpair  in > out (% einsi in > out)
#   % mafft --maxiterate 1000 --globalpair in > out (% ginsi in > out)

# If unsure which option to use:
#   % mafft --auto in > out

# --op # :         Gap opening penalty, default: 1.53
# --ep # :         Offset (works like gap extension penalty), default: 0.0
# --maxiterate # : Maximum number of iterative refinement, default: 0
# --clustalout :   Output: clustal format, default: fasta
# --reorder :      Outorder: aligned, default: input order
# --quiet :        Do not report progress
# --thread # :     Number of threads (if unsure, --thread -1)
# --dash :         Add structural information (Rozewicki et al, submitted)

# Algorithm:
#--localpair

#All pairwise alignments are computed with the Smith-Waterman algorithm. 
# More accurate but slower than --6merpair. Suitable for a set of locally alignable sequences.
# Applicable to up to ~200 sequences. 
# A combination with --maxiterate 1000 is recommended (L-INS-i). Default: off (6mer distance is used)