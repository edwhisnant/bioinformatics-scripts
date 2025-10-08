#!/usr/bin/bash

#SBATCH --mem-per-cpu=1G  # adjust as needed
#SBATCH -c 16 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/hmmer/hmmsearch/lecanoromycetes_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/hmmer/hmmsearch/lecanoromycetes_%a.err
#SBATCH --partition=scavenger
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=hmmsearch-v25.09.01
#SBATCH -t 7-00:00:00
#SBATCH --array=1-160 # Array range

# === Define variables ===
VERSION=v25.08.19
RESULTS=Results_Aug22
LIST=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/Orthogroups/OGs_for_annotation_list.txt
FASTA_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/Orthogroup_Sequences
OG_MSA_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/MSA_Orthogroups
HMM_DIR=${OG_MSA_DIR}/HMM_Profiles
THREADS=16

############################################################################
# Script will use HMMER to search the Orthogroup HMM profiles against the
# original sequences to check for coverage and similarity
# Requires MAFFT alignment of the Orthogroups & HMM profiles from hmmbuild
############################################################################

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

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate hmmer

mkdir -p ${HMM_DIR}/hmmsearch

# Use hmmsearch to search the HMM profile against the ORIGINAL sequences
hmmsearch --cpu ${THREADS} --domtblout ${HMM_DIR}/hmmsearch/${BASENAME}.tbl ${HMM_DIR}/hmmbuild/${BASENAME}.hmm  ${FASTA_DIR}/${FASTA_FILE}

conda deactivate

############################################################################
# How to use HMMER/hmmsearch:
############################################################################
# hmmsearch -h
# hmmsearch :: search profile(s) against a sequence database
# HMMER 3.4 (Aug 2023); http://hmmer.org/
# Copyright (C) 2023 Howard Hughes Medical Institute.
# Freely distributed under the BSD open source license.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Usage: hmmsearch [options] <hmmfile> <seqdb>

# Basic options:
#   -h : show brief help on version and usage

# Options directing output:
#   -o <f>           : direct output to file <f>, not stdout
#   -A <f>           : save multiple alignment of all hits to file <f>
#   --tblout <f>     : save parseable table of per-sequence hits to file <f>
#   --domtblout <f>  : save parseable table of per-domain hits to file <f>
#   --pfamtblout <f> : save table of hits and domains to file, in Pfam format <f>
#   --acc            : prefer accessions over names in output
#   --noali          : don't output alignments, so output is smaller
#   --notextw        : unlimit ASCII text output line width
#   --textw <n>      : set max width of ASCII text output lines  [120]  (n>=120)

# Options controlling reporting thresholds:
#   -E <x>     : report sequences <= this E-value threshold in output  [10.0]  (x>0)
#   -T <x>     : report sequences >= this score threshold in output
#   --domE <x> : report domains <= this E-value threshold in output  [10.0]  (x>0)
#   --domT <x> : report domains >= this score cutoff in output

# Options controlling inclusion (significance) thresholds:
#   --incE <x>    : consider sequences <= this E-value threshold as significant
#   --incT <x>    : consider sequences >= this score threshold as significant
#   --incdomE <x> : consider domains <= this E-value threshold as significant
#   --incdomT <x> : consider domains >= this score threshold as significant

# Options controlling model-specific thresholding:
#   --cut_ga : use profile's GA gathering cutoffs to set all thresholding
#   --cut_nc : use profile's NC noise cutoffs to set all thresholding
#   --cut_tc : use profile's TC trusted cutoffs to set all thresholding

# Options controlling acceleration heuristics:
#   --max    : Turn all heuristic filters off (less speed, more power)
#   --F1 <x> : Stage 1 (MSV) threshold: promote hits w/ P <= F1  [0.02]
#   --F2 <x> : Stage 2 (Vit) threshold: promote hits w/ P <= F2  [1e-3]
#   --F3 <x> : Stage 3 (Fwd) threshold: promote hits w/ P <= F3  [1e-5]
#   --nobias : turn off composition bias filter

# Other expert options:
#   --nonull2     : turn off biased composition score corrections
#   -Z <x>        : set # of comparisons done, for E-value calculation
#   --domZ <x>    : set # of significant seqs, for domain E-value calculation
#   --seed <n>    : set RNG seed to <n> (if 0: one-time arbitrary seed)  [42]
#   --tformat <s> : assert target <seqfile> is in format <s>: no autodetection
#   --cpu <n>     : number of parallel CPU workers to use for multithreads  [2]
#   --stall       : arrest after start: for debugging MPI under gdb
#   --mpi         : run as an MPI parallel program