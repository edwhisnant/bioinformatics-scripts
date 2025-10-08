#!/usr/bin/bash

SUMMARIZE_EGGNOG_PY=/hpc/group/bio1/ewhisnant/comp-genomics/scripts/compare/annotate-orthogroups/eggnog-summarize-orthogroups.py
SUMMARIZE_IPR_PY=/hpc/group/bio1/ewhisnant/comp-genomics/scripts/compare/annotate-orthogroups/interpro-summarize-orthogroups.py

ANNOTATE_OUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.08.19/Results_Aug22/Annotate_Orthogroups
# Before running this script, esnure you have modified the input/output paths in the two python scripts above
# Then run:

mkdir -p ${ANNOTATE_OUT}

python3 ${SUMMARIZE_EGGNOG_PY}
python3 ${SUMMARIZE_IPR_PY}

