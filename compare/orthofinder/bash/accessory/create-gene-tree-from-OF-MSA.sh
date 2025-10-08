#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G  # adjust as needed
#SBATCH -c 16 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/HET_orthogroup_iqtree.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/HET_orthogroup_iqtree.err
#SBATCH --partition=common

# === Multiple Sequence Alignment (MSA) to Gene Tree ===
MSA=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/proteins/Results_May28/MultipleSequenceAlignments/OG0000730.fa
OG_OF_INTEREST=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/proteins/Results_May28/Orthogroups_of_interest/HET-proteins


cd ${OG_OF_INTEREST}

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate iqtree

iqtree \
    -s ${MSA} \
    --polytomy \
    --seqtype AA \
    --seed 42 \
    --prefix HET_OG0000730 \
    -m MFP \
    -v \
    -B 1000 \
    -T 16

conda deactivate