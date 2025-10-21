#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/phyling/filter/lecanoromycetes-filter-%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/phyling/filter/lecanoromycetes-filter-%a.err
#SBATCH --partition=scavenger
#SBATCH --array=200,400,600,800,1000,1200,1400,1600,1800,2000,2200,2400,2600 # Array range for filtering, 2807 is the max so you will feed the align directory directly
#SBATCH -t 2-00:00:00
#SBATCH --job-name=phyling-filter

################################################################################################
## === PHYling Filter Script ===
## This script performs a filtering step after the MSA from phyling align. The input is the output directory from phyling align.
## This module will quickly construct a tree for each MSA with fasttree and calculate the treeness/RCV value using PhyKIT.
## Treeness/RCV is a measure of how informative a marker is and is a way of reducing bias in phylogenomic datasets.
## Markers are ranked by their treeness/RCV value and the top N markers are selected for the final tree building step.
## The output will be a directory containing the filtered markers for each value of N, which is fed into the next step (phyling tree)
################################################################################################
# Define variables
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/lecanoromycetes/v25.08.19/

mkdir -p ${OUTPUT}/filter/${SLURM_ARRAY_TASK_ID}-models

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate phyling

echo "Running PHYling filter..."

# == 2. Filter the best models for the tree builiding
phyling filter \
    -I ${OUTPUT}/align \
    -o ${OUTPUT}/filter/${SLURM_ARRAY_TASK_ID}-models \
    --ml \
    -t 32 \
    --top_n_toverr ${SLURM_ARRAY_TASK_ID} \
    --seqtype pep

conda deactivate

################################################################################################
# See below for options and help for # phykit filter
################################################################################################
# phyling filter -h
# usage: phyling filter (-i file [files ...] | -I directory) -n TOP_N_TOVERR [-o directory] [--seqtype {pep,dna,AUTO}] [--ml] [-t THREADS] [-v] [-h]

# Filter the multiple sequence alignment (MSA) results for tree module.

# The align step usually reports a lot of markers but many of them are uninformative or susceptible to composition bias. The Treeness/RCV value computed by PhyKIT is
# used to estimate how informative the markers are. By default the -n/--top_n_toverr is set to 50 to select only the top 50 markers.

# Required arguments:
#   -i file [files ...], --inputs file [files ...]
#                         Multiple sequence alignment fasta of the markers
#   -I directory, --input_dir directory
#                         Directory containing multiple sequence alignment fasta of the markers
#   -n TOP_N_TOVERR, --top_n_toverr TOP_N_TOVERR
#                         Select the top n markers based on their treeness/RCV for final tree building

# Options:
#   -o directory, --output directory
#                         Output directory of the treeness.tsv and selected MSAs (default: phyling-tree-[YYYYMMDD-HHMMSS] (UTC timestamp))
#   --seqtype {pep,dna,AUTO}
#                         Input data sequence type (default: AUTO)
#   --ml                  Use maximum-likelihood estimation during tree building
#   -t THREADS, --threads THREADS
#                         Threads for filtering (default: 8)
#   -v, --verbose         Verbose mode for debug
#   -h, --help            show this help message and exit