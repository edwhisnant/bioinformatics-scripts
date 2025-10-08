#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G  # adjust as needed
#SBATCH -c 16 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/dbcan/v25.08.19/lecanoromycetes-dbcan-%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/dbcan/v25.08.19/lecanoromycetes-dbcan-%a.err
#SBATCH --partition=scavenger
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=dbcan-v25.08.19
#SBATCH -t 2-00:00:00
#SBATCH --array=0-114 # Array range (change after quality control step)



# To build a HMMER profile for each Orthogroup (OG) from OrthoFinder results
# This script assumes you have already run OrthoFinder and have the results directory available

# OrthoFinder has MSA created using MAFFT and trimmed by the OF algorithm
# This script will use those alignments to build HMMER profiles for the Orthogroups of interest 


VERSION=v25.08.19
RESULTS=Results_Aug22
LIST=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/Orthogroups/OGs_for_annotation_list.txtMSA_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.08.19/Results_Aug22/MultipleSequenceAlignments
OG_HMM_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/Orthogroup_HMMs

# === Create the index for the array job ===
dos2unix ${LIST}
MSA_FILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$LIST")
ORTHOGROUP=$(basename "$FASTA_FILE" .fa)

# === Install a checkpoint to ensure there is a real file ===
if [ -z "$MSA_FILE" ]; then
    echo "No MSA file found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

if [ -z "${ORTHOGROUP}" ]; then
    echo "BASENAME empty"
    exit 1
fi


# === Makee the output directory for the HMM profiles ===
echo "Building HMMER profile for Orthogroup: ${ORTHOGROUP}"
mkdir -p ${OG_HMM_DIR}/${ORTHOGROUP}
cd ${OG_HMM_DIR}/${ORTHOGROUP}

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate hmmer

hmmbuild \
    --amino \
    --cpu 16 \
    ${ORTHOGROUP}_profile.hmm \
    ${OG_HMM_DIR}/${ORTHOGROUP}/${ORTHOGROUP}.fa

conda deactivate

# === Check that the HMMER profile was created successfully ===
if [ -f ${ORTHOGROUP}_profile.hmm ]; then
    echo "HMMER profile for ${ORTHOGROUP} created successfully."
else
    echo "Error: HMMER profile for ${ORTHOGROUP} was not created."
    exit 1
fi



