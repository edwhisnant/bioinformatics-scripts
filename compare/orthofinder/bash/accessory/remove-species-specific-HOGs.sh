# Remove species specific HOGs from OrthoFinder results

REMOVE_SP_SP_HOGS_PY=/hpc/group/bio1/ewhisnant/comp-genomics/scripts/compare/orthofinder/python/remove-species-specific-HOGs.py
IN_N0_TSV=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.06.16/Results_Jun09/Phylogenetic_Hierarchical_Orthogroups/N0.tsv
OUT_N0_TSV=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.06.16/Results_Jun09/Phylogenetic_Hierarchical_Orthogroups/N0.filtered.tsv

if [ -z "${IN_N0_TSV}" ] || [ -z "${OUT_N0_TSV}" ]; then
    echo "Usage: $0 <input: N0.tsv> <output: N0.filtered.tsv>"
    exit 1
fi

# === Usage: ===
python3 ${REMOVE_SP_SP_HOGS_PY} ${IN_N0_TSV} ${OUT_N0_TSV}

