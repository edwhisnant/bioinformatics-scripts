import pandas as pd
import glob
from collections import Counter, defaultdict

ANNOT_DIR = "/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.08.19/Results_Aug22/eggnog"

output_summary = []
per_protein_annots = defaultdict(list)

def top_terms(term_list, n=3):
    flat = [term.strip() for entry in term_list for term in str(entry).split(",") if term.strip() != '-' and term.strip()]
    return ", ".join([f"{term} ({count})" for term, count in Counter(flat).most_common(n)])

for file in glob.glob(f"{ANNOT_DIR}/*.emapper.annotations"):
    orthogroup_id = file.split("/")[-1].split(".")[0]

    # Read header line first (the one starting with # but not ##)
    with open(file, 'r') as f:
        for line in f:
            if line.startswith('#') and not line.startswith('##'):
                header = line.lstrip('#').strip().split('\t')
                break

    # Read data skipping commented lines
    df = pd.read_csv(file, comment='#', sep='\t', names=header)

    # Drop empty/unannotated entries
    df = df[df['eggNOG_OGs'].notna()]

    # Collect annotation columns for summary
    all_desc = df['Description'].dropna().tolist()
    all_go    = df['GOs'].dropna().tolist()
    all_kegg  = df['KEGG_ko'].dropna().tolist()
    all_cog   = df['COG_category'].dropna().tolist()
    all_og    = df['eggNOG_OGs'].dropna().tolist()

    # Append summary info
    output_summary.append({
        "Orthogroup": orthogroup_id,
        "Top_Descriptions": top_terms(all_desc, 2),
        "Top_GO_terms": top_terms(all_go, 3),
        "Top_KEGG_terms": top_terms(all_kegg, 3),
        "Top_COG_categories": top_terms(all_cog, 3),
        "Top_eggNOG_OGs": top_terms(all_og, 3)
    })

    # Store per-protein annotation details
    for _, row in df.iterrows():
        per_protein_annots[orthogroup_id].append({
            "ProteinID": row['query'],
            "Description": row['Description'] if pd.notna(row['Description']) else "-",
            "GOs": row['GOs'] if pd.notna(row['GOs']) else "-",
            "KEGG_ko": row['KEGG_ko'] if pd.notna(row['KEGG_ko']) else "-",
            "COG_category": row['COG_category'] if pd.notna(row['COG_category']) else "-",
            "eggNOG_OGs": row['eggNOG_OGs'] if pd.notna(row['eggNOG_OGs']) else "-"
        })

# Save orthogroup summary
summary_df = pd.DataFrame(output_summary)
summary_df.to_csv(f"{ANNOT_DIR}/../Annotate_Orthogroups/eggnog_orthogroup_summary.tsv", sep="\t", index=False)
print("Summary saved to eggnog_orthogroup_summary.tsv")

# Save per-protein detailed annotations
per_protein_rows = []
for og, proteins in per_protein_annots.items():
    for prot in proteins:
        row = {"Orthogroup": og}
        row.update(prot)
        per_protein_rows.append(row)

per_protein_df = pd.DataFrame(per_protein_rows)
per_protein_df.to_csv(f"{ANNOT_DIR}/../eggnog_per_protein.tsv", sep="\t", index=False)
print("Per-protein annotations saved to eggnog_per_protein.tsv")
