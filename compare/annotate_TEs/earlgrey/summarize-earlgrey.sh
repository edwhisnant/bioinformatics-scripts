#!/usr/bin/bash

# Code to summarize the results from EarlGrey TE annotation

# Option 1: Collect the summary stats for high level overview from the .highLevelCount.kable file

INDIR_PEZIZO=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/f2-intermediate-files/masked-genomes/other-pezizomycotina
INDIR_LECANO=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/f2-intermediate-files/masked-genomes/lecanoromycetes
OUTDIR_PEZIZO=/hpc/group/bio1/ewhisnant/comp-genomics/compare/annotate_TEs/earlgrey/v25.09.29/pezizomycotina
OUTDIR_LECANO=/hpc/group/bio1/ewhisnant/comp-genomics/compare/annotate_TEs/earlgrey/v25.09.29/lecanoromycetes
SUMMARY_PY=/hpc/group/bio1/ewhisnant/comp-genomics/scripts/compare/annotate_TEs/earlgrey/get_HighLevelSummary_percGenomeCov.py

source $(conda info --base)/etc/profile.d/conda.sh
conda activate earlgrey_sum

# Script takes in a directory of several earlgrey results and summarizes the .highLevelCount.kable files
# It produces a summary table of the genome with the breakdown of the 

echo "#1. === Summarizing the Lecanoromycetes"
mkdir -p ${OUTDIR_LECANO}
python3 ${SUMMARY_PY} --indir ${INDIR_LECANO} --outdir ${OUTDIR_LECANO} --name_prefix Lecanoromycetes

echo "#2. === Summarizing the other Pezizomycotina"
mkdir -p ${OUTDIR_PEZIZO}
python3 ${SUMMARY_PY} --indir ${INDIR_PEZIZO} --outdir ${OUTDIR_PEZIZO} --name_prefix Pezizomycotina

conda deactivate
