#!/usr/bin/bash

#SBATCH --mem-per-cpu=16G  # adjust as needed
#SBATCH -c 12 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/dram/setup.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/dram/setup.err
#SBATCH --partition=common

echo `date`
echo "Setting up DRAM databases"

source $(conda info --base)/etc/profile.d/conda.sh
conda activate DRAM


cd /hpc/group/bio1/ewhisnant/comp-genomics/compare/dram

rm -rf DRAM_data

DRAM-setup.py prepare_databases \
    --output_dir DRAM_data \
    --skip_uniref \
    --threads 12 \

conda deactivate


