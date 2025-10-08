#!/usr/bin/bash

#SBATCH --mem-per-cpu=8G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/phyling/cons-tree/lecanoromycetes-tree-cons_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/phyling/cons-tree/lecanoromycetes-tree-cons_%a.err
#SBATCH --partition=scavenger
#SBATCH --array=200,400,600,800,1000,1200,1400,1600,1800,2000,2200,2400,2600,2807 # Array range for filtering, 2807 is the max
#SBATCH -t 2-00:00:00
#SBATCH --job-name=phyling-tree
################################################################################################

# Define variables
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/lecanoromycetes/v25.08.19/

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate phyling

echo "Running PHYling tree building"

mkdir -p ${OUTPUT}/consensus/${SLURM_ARRAY_TASK_ID}-models

# == 3. Build ya-self a tree

if [ ${SLURM_ARRAY_TASK_ID} -eq 2807 ]; then
    echo "Using the full set of models for tree building"
    phyling tree \
        -I ${OUTPUT}/align \
        -o ${OUTPUT}/consensus/2807-models \
        -M iqtree \
        -f \
        -t 32 \
        --seqtype pep
else
    echo "Using filtered models for tree building: ${SLURM_ARRAY_TASK_ID}"
    phyling tree \
        -I ${OUTPUT}/filter/${SLURM_ARRAY_TASK_ID}-models \
        -o ${OUTPUT}/consensus/${SLURM_ARRAY_TASK_ID}-models \
        -M iqtree \
        -f \
        -t 32 \
        --seqtype pep
fi
conda deactivate

################################################################################################
# See below for options and help for # phykit tree
################################################################################################
# phyling tree -h
# usage: phyling tree (-i file [files ...] | -I directory) [-o directory] [--seqtype {pep,dna,AUTO}] [-M {ft,raxml,iqtree}] [-c] [-p] [-f] [--seed SEED] [-t THREADS]
#                     [-v] [-h]

# Construct a phylogenetic tree by the selected multiple sequence alignment (MSA) results.

# By default the consensus tree method will be employed which use a 50% cutoff to represent the majority of all the trees. You can use the -c/--concat option to
# concatenate the MSA and build a single tree instead. Note that enable the -p/--partition option will also output a partition file that compatible to RAxML-NG and IQ-
# TREE.

# For the tree building step, the FastTree will be used as default algorithm. Users can switch to the RAxML-NG or IQ-TREE by specifying the -m/--method raxml/iqtree.

# Once the tree is built, an ASCII figure representing the tree will be displayed, and a treefile in Newick format will be generated as output. Additionally, users can
# choose to obtain a matplotlib-style figure using the -f/--figure option.

# Required arguments:
#   -i file [files ...], --inputs file [files ...]
#                         Multiple sequence alignment fasta of the markers
#   -I directory, --input_dir directory
#                         Directory containing multiple sequence alignment fasta of the markers

# Options:
#   -o directory, --output directory
#                         Output directory of the newick treefile (default: phyling-tree-[YYYYMMDD-HHMMSS] (UTC timestamp))
#   --seqtype {pep,dna,AUTO}
#                         Input data sequence type (default: AUTO)
#   -M {ft,raxml,iqtree}, --method {ft,raxml,iqtree}
#                         Algorithm used for tree building. (default: ft)
#                         Available options:
#                         ft: FastTree
#                         raxml: RAxML-NG
#                         iqtree: IQTree
#   -c, --concat          Concatenated alignment results
#   -p, --partition       Partitioned analysis by sequence. Only works when --concat enabled.
#   -f, --figure          Generate a matplotlib tree figure
#   --seed SEED           Seed number for stochastic elements during inferences. (default: -1 to generate randomly)
#   -t THREADS, --threads THREADS
#                         Threads for tree construction (default: 8)
#   -v, --verbose         Verbose mode for debug
#   -h, --help            show this help message and exit