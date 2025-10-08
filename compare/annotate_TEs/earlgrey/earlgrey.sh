#!/usr/bin/bash

#SBATCH --mem-per-cpu=2G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/earlgrey/lecanoromycetes_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/earlgrey/lecanoromycetes_%a.err
#SBATCH --partition=scavenger
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=EarlGrey-v25.09.01
#SBATCH -t 7-00:00:00
#SBATCH --array=30 # Array range

# === Define variables ===
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes
OUTDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/annotate_TEs/earlgrey
THREADS=32

# === Create the index for the array job ===
NUC_FILES=($(ls ${IN_DIR}/*/annotate_results/*.nuclear.unmasked.fa))
NFILE=${NUC_FILES[$SLURM_ARRAY_TASK_ID]}
BASENAME=$(basename "${NFILE}" .nuclear.unmasked.fa)

# === Validate input files exist ===
if [ -z "${NFILE}" ]; then
    echo "Error: No genome file found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}. Exiting."
    exit 1
fi

if [ -z "${BASENAME}" ]; then
    echo "Error: BASENAME is empty. Exiting."
    exit 1
fi

# === Run EarlGrey
source $(conda info --base)/etc/profile.d/conda.sh
conda activate earlgrey

mkdir -p ${OUTDIR}

earlGrey \
    -g ${NFILE} \
    -s ${BASENAME} \
    -o ${OUTDIR}/${BASENAME} \
    -t ${THREADS} \
    -e yes \
    -i 10 \
    -f 1000 \
    -c no \
    -m no \
    -d no \
    -n 20 \
    -a 3

conda deactivate

######################################################
# For help with using EarlGrey, see:
######################################################

# earlGrey
    
#               )  (
#              (   ) )
#              ) ( (
#            _______)_
#         .-'---------|  
#        ( C|/\/\/\/\/|
#         '-./\/\/\/\/|
#           '_________'
#            '-------'
#         <<< Checking Parameters >>>
#         #############################
#         earlGrey version 6.3.0
#         Required Parameters:
#                 -g == genome.fasta
#                 -s == species name
#                 -o == output directory

#         Optional Parameters:
#                 -t == Number of Threads (DO NOT specify more than are available)
#                 -r == RepeatMasker search term (e.g arthropoda/eukarya)
#                 -l == Starting consensus library for an initial mask (in fasta format)
#                 -i == Number of Iterations to BLAST, Extract, Extend (Default: 10)
#                 -f == Number flanking basepairs to extract (Default: 1000)
#                 -c == Cluster TE library to reduce redundancy? (yes/no, Default: no)
#                 -m == Remove putative spurious TE annotations <100bp? (yes/no, Default: no)
#                 -d == Create soft-masked genome at the end? (yes/no, Default: no)
#                 -n == Max number of sequences used to generate consensus sequences (Default: 20)
#                 -a == minimum number of sequences required to build a consensus sequence (Default: 3)
#                 -e == Run HELIANO as an optional step to detect Helitrons (yes/no, Default: no)
#                 -h == Show help

#         Example Usage:

#         earlGrey -g bombyxMori.fasta -s bombyxMori -o /home/toby/bombyxMori/repeatAnnotation/ -t 16

#         Queries can be sent to:
#         tobias.baril[at]unine.ch

#         Please make use of the GitHub Issues and Discussion Tabs at: https://github.com/TobyBaril/EarlGrey
#         #############################