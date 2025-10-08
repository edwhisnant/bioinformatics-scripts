#!/usr/bin/bash


COMBINE_SUMMARIES_PY=/hpc/group/bio1/ewhisnant/comp-genomics/scripts/compare/cafe/misc/combine_summaries.py
CAFE_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/cafe/lecanoromycetes/v25.07.11
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/cafe/lecanoromycetes/v25.07.11/compare_gamma_results.tsv

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate cafe5

python3 ${COMBINE_SUMMARIES_PY} \
    ${CAFE_DIR}/91filtered-G*/CAFE/Gamma_summary.tsv \
    --output ${OUTPUT}

conda deactivate

