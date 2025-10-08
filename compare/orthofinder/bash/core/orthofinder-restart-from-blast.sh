#!/usr/bin/bash

#SBATCH --mem 500G  # adjust as needed
#SBATCH -c 64 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/lecanoromycetes-v25.08.13.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/lecanoromycetes-v25.08.13.err
#SBATCH --partition=common
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=orthofinder-v25.08.13
#SBATCH -t 7-00:00:00

# === This script is used when you are restarting the OrthoFinder run after running the BLAST/DIAMOND results
# === This script can also simply be used to update the OrthoFinder results with new genomes, species tree, or an update to OrthoFinder

# === Define variables ===
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.07.11/Results_Jul11
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.08.13
PHYLING_TREE=/hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/lecanoromycetes/tree-cons1000/SpeciesTree_rerooted.txt

cd ${IN_DIR}

################################################################################################
############                          RUN ORTHOFINDER                               ############
################################################################################################

echo "Restarting OrthoFinder from BLAST/DIAMOND results in: ${IN_DIR}"

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate orthofinder

if [ ! -d "${IN_DIR}" ]; then
    echo "Directory ${IN_DIR} does not exist. This script requires you to have run an instance of OrthoFinder previously. Exiting."
    exit 0
fi

orthofinder \
    -b ${IN_DIR} \
    -T fasttree \
    -t 64 \
    -a 16 \
    -M msa \
    -A mafft \
    -S diamond \
    -y \
    -s ${PHYLING_TREE}

conda deactivate
