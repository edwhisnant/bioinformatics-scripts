#!/usr/bin/bash

#SBATCH --mem=64G  # adjust as needed
#SBATCH -c 12 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/cafe/cafefig.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/cafe/cafefig.err
#SBATCH -t 7-00:00:00
#SBATCH --partition=common

INDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/cafe/lecanoromycetes/v25.06.18/100filtered/HOGs_fasttree/
OUTDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/cafe/lecanoromycetes/v25.06.18/100filtered/cafefig
CAFEREPORT=${INDIR}/Gamma_report.cafe
CAFEFIGPY=/hpc/group/bio1/ewhisnant/comp-genomics/scripts/compare/cafe/cafefig.py


# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate cafefig

python3 ${CAFEFIGPY} \
    --dump ${OUTDIR} \
    --gfx_output_format pdf \
    ${CAFEREPORT}

conda deactivate

# === MAN PAGE ===
# python3 cafefig.py -h
# usage: cafefig.py [-h] [-f FAMILIES [FAMILIES ...]] [-c CLADES [CLADES ...]]                                                                                     
#                   [-pb PB] [-pf PF] [-d DUMP] [-g GFX_OUTPUT_FORMAT]                                                                                             
#                   [--count_all_expansions]                                                                                                                       
#                   report_cafe                                                                                                                                    
                                                                                                                                                                 
# Parses a CAFE output file (.cafe) and plots a summary tree that shows the                                                                                        
# average expansion/contraction across the phylogeny; a tree that shows which
# clades evolved under the same lambda (if available); and a gene family
# evolution tree for each user-specified gene family.

# positional arguments:
#   report_cafe           the file report.cafe (or similar name)

# optional arguments:
#   -h, --help            show this help message and exit
#   -f FAMILIES [FAMILIES ...], --families FAMILIES [FAMILIES ...]
#                         only show families with these IDs
#   -c CLADES [CLADES ...], --clades CLADES [CLADES ...]
#                         only show families that are expanded/contracted at
#                         this clade. Format: [clade]=[leaf],[leaf] where clade
#                         is the name of the last common ancestor of the two
#                         leaves, e.g.: Isoptera=zne,mna
#   -pb PB                branch p-value cutoff (default: 0.05)
#   -pf PF                family p-value cutoff (default: 0.05)
#   -d DUMP, --dump DUMP  don't open trees in a window, write them to files in
#                         the specified directory instead (default: off)
#   -g GFX_OUTPUT_FORMAT, --gfx_output_format GFX_OUTPUT_FORMAT
#                         output format for the tree figures when using --dump
#                         [svg|pdf|png] (default: pdf)
#   --count_all_expansions
#                         count and write down the number of *all* expansions
#                         and contractions (default: only count significant
#                         expansions/contractions)