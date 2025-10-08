#!/usr/bin/bash

#SBATCH --mem-per-cpu=1G  # adjust as needed
#SBATCH -c 16 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/hmmer/hmmbuild/lecanoromycetes_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/hmmer/hmmbuild/lecanoromycetes_%a.err
#SBATCH --partition=scavenger
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=hmmbuild-v25.09.01
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
# Script will use HMMER to build the HMM profile for the Orthogroups
# Requires MAFFT alignment of the Orthogroups
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

mkdir -p ${HMM_DIR}/hmmbuild

hmmbuild --cpu ${THREADS} --amino ${HMM_DIR}/hmmbuild/${BASENAME}.hmm ${OG_MSA_DIR}/MSA/${BASENAME}.fa

conda deactivate

############################################################################
# How to use HMMER/hmmbuild:
############################################################################
# hmmbuild -h
# # hmmbuild :: profile HMM construction from multiple sequence alignments
# # HMMER 3.4 (Aug 2023); http://hmmer.org/
# # Copyright (C) 2023 Howard Hughes Medical Institute.
# # Freely distributed under the BSD open source license.
# # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Usage: hmmbuild [-options] <hmmfile_out> <msafile>

# Basic options:
#   -h     : show brief help on version and usage
#   -n <s> : name the HMM <s>
#   -o <f> : direct summary output to file <f>, not stdout
#   -O <f> : resave annotated, possibly modified MSA to file <f>

# Options for selecting alphabet rather than guessing it:
#   --amino : input alignment is protein sequence data
#   --dna   : input alignment is DNA sequence data
#   --rna   : input alignment is RNA sequence data

# Alternative model construction strategies:
#   --fast           : assign cols w/ >= symfrac residues as consensus  [default]
#   --hand           : manual construction (requires reference annotation)
#   --symfrac <x>    : sets sym fraction controlling --fast construction  [0.5]
#   --fragthresh <x> : if L <= x*alen, tag sequence as a fragment  [0.5]

# Alternative relative sequence weighting strategies:
#   --wpb     : Henikoff position-based weights  [default]
#   --wgsc    : Gerstein/Sonnhammer/Chothia tree weights
#   --wblosum : Henikoff simple filter weights
#   --wnone   : don't do any relative weighting; set all to 1
#   --wgiven  : use weights as given in MSA file
#   --wid <x> : for --wblosum: set identity cutoff  [0.62]  (0<=x<=1)

# Alternative effective sequence weighting strategies:
#   --eent       : adjust eff seq # to achieve relative entropy target  [default]
#   --eclust     : eff seq # is # of single linkage clusters
#   --enone      : no effective seq # weighting: just use nseq
#   --eset <x>   : set eff seq # for all models to <x>
#   --ere <x>    : for --eent: set minimum rel entropy/position to <x>
#   --esigma <x> : for --eent: set sigma param to <x>  [45.0]
#   --eid <x>    : for --eclust: set fractional identity cutoff to <x>  [0.62]

# Alternative prior strategies:
#   --pnone    : don't use any prior; parameters are frequencies
#   --plaplace : use a Laplace +1 prior

# Handling single sequence inputs:
#   --singlemx    : use substitution score matrix for single-sequence inputs
#   --mx <s>      : substitution score matrix (built-in matrices, with --singlemx)
#   --mxfile <f>  : read substitution score matrix from file <f> (with --singlemx)
#   --popen <x>   : force gap open prob. (w/ --singlemx, aa default 0.02, nt 0.031)
#   --pextend <x> : force gap extend prob. (w/ --singlemx, aa default 0.4, nt 0.75)

# Control of E-value calibration:
#   --EmL <n> : length of sequences for MSV Gumbel mu fit  [200]  (n>0)
#   --EmN <n> : number of sequences for MSV Gumbel mu fit  [200]  (n>0)
#   --EvL <n> : length of sequences for Viterbi Gumbel mu fit  [200]  (n>0)
#   --EvN <n> : number of sequences for Viterbi Gumbel mu fit  [200]  (n>0)
#   --EfL <n> : length of sequences for Forward exp tail tau fit  [100]  (n>0)
#   --EfN <n> : number of sequences for Forward exp tail tau fit  [200]  (n>0)
#   --Eft <x> : tail mass for Forward exponential tail tau fit  [0.04]  (0<x<1)

# Other options:
#   --cpu <n>          : number of parallel CPU workers for multithreads  [2]
#   --mpi              : run as an MPI parallel program
#   --stall            : arrest after start: for attaching debugger to process
#   --informat <s>     : assert input alifile is in format <s> (no autodetect)
#   --seed <n>         : set RNG seed to <n> (if 0: one-time arbitrary seed)  [42]
#   --w_beta <x>       : tail mass at which window length is determined
#   --w_length <n>     : window length 
#   --maxinsertlen <n> : pretend all inserts are length <= <n>