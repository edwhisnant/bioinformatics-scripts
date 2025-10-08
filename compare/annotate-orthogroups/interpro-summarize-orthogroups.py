import os
from collections import defaultdict

input_folder = "/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.08.19/Results_Aug22/iprscan-annotations"
output_summary = "/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.08.19/Results_Aug22/Annotate_Orthogroups/interproscan_orthogroup_summary.tsv"
output_per_protein = "/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.08.19/Results_Aug22/Annotate_Orthogroups/interproscan_per_protein.tsv"

# Data structure: orthogroup -> protein -> annotations
data = defaultdict(lambda: defaultdict(lambda: {
    'length': None,
    'domains': defaultdict(int),
    'ipr_desc': defaultdict(int),
    'go_terms': set(),
    'metacyc_pathways': set(),
    'reactome_pathways': set()
}))

for filename in os.listdir(input_folder):
    if not filename.endswith(".tsv"):
        continue
    filepath = os.path.join(input_folder, filename)
    # Remove suffixes like '.interproscan' or '.interproscan.tsv'
    og = filename
    for suffix in ['.interproscan.tsv', '.interproscan', '.tsv']:
        if og.endswith(suffix):
            og = og[:-len(suffix)]
            break

    with open(filepath) as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            fields = line.strip().split("\t")
            if len(fields) < 15:
                continue

            protein_id = fields[0]
            seq_len = fields[2]
            source = fields[3]
            db_id = fields[4]
            sig_desc = fields[5]
            start = fields[6]
            end = fields[7]
            evalue = fields[8]
            ipr_id = fields[11]
            ipr_desc_str = fields[12]
            go_terms_str = fields[13]
            pathways_str = fields[14]

            data[og][protein_id]['length'] = seq_len

            # Domain key simplified: source:db_id (drop positions and evalue)
            if source in ["Pfam", "CDD", "SMART"]:
                domain_key = f"{source}:{db_id}"
                data[og][protein_id]['domains'][domain_key] += 1

            if ipr_id and ipr_id != "-":
                ipr_entry = f"{ipr_id}:{ipr_desc_str}" if ipr_desc_str and ipr_desc_str != "-" else ipr_id
                data[og][protein_id]['ipr_desc'][ipr_entry] += 1

            if go_terms_str and go_terms_str != "-":
                for go in go_terms_str.split("|"):
                    go_id = go.split("(")[0].strip()
                    if go_id:
                        data[og][protein_id]['go_terms'].add(go_id)

            if pathways_str and pathways_str != "-":
                for pw in pathways_str.split("|"):
                    pw = pw.strip()
                    if pw:
                        if pw.startswith("Reactome:"):
                            data[og][protein_id]['reactome_pathways'].add(pw)
                        else:
                            data[og][protein_id]['metacyc_pathways'].add(pw)

# Write per protein output
with open(output_per_protein, "w") as out_prot:
    header = [
        "Orthogroup", "Protein", "Length",
        "Domains", "GO_Terms", "InterPro_Entries", "MetaCyc_Pathways", "Reactome_Pathways"
    ]
    out_prot.write("\t".join(header) + "\n")
    for og in sorted(data):
        for prot in sorted(data[og]):
            length = data[og][prot]['length'] or "-"
            domains = ", ".join(sorted(data[og][prot]['domains'].keys()))
            go_terms = ", ".join(sorted(data[og][prot]['go_terms']))
            ipr_desc = ", ".join(sorted(data[og][prot]['ipr_desc'].keys()))
            metacyc = ", ".join(sorted(data[og][prot]['metacyc_pathways']))
            reactome = ", ".join(sorted(data[og][prot]['reactome_pathways']))
            out_prot.write(f"{og}\t{prot}\t{length}\t{domains}\t{go_terms}\t{ipr_desc}\t{metacyc}\t{reactome}\n")

# Write summary per orthogroup
with open(output_summary, "w") as out_sum:
    header = [
        "Orthogroup", "Num_Proteins", "Median_Length", "Domains",
        "GO_Terms", "InterPro_Entries", "MetaCyc_Pathways", "Reactome_Pathways"
    ]
    out_sum.write("\t".join(header) + "\n")

    for og in sorted(data):
        proteins = data[og]
        num_proteins = len(proteins)

        lengths = [int(proteins[p]['length']) for p in proteins if proteins[p]['length']]
        lengths.sort()
        if lengths:
            mid = len(lengths) // 2
            median_length = (lengths[mid-1] + lengths[mid]) / 2 if len(lengths) % 2 == 0 else lengths[mid]
        else:
            median_length = "-"

        domain_counts = defaultdict(int)
        ipr_desc_counts = defaultdict(int)
        go_terms_set = set()
        metacyc_set = set()
        reactome_set = set()

        for prot in proteins:
            for d, c in proteins[prot]['domains'].items():
                domain_counts[d] += c
            for ipr, c in proteins[prot]['ipr_desc'].items():
                ipr_desc_counts[ipr] += c
            go_terms_set.update(proteins[prot]['go_terms'])
            metacyc_set.update(proteins[prot]['metacyc_pathways'])
            reactome_set.update(proteins[prot]['reactome_pathways'])

        domain_str = ", ".join(sorted(domain_counts, key=domain_counts.get, reverse=True))
        ipr_desc_str = ", ".join(sorted(ipr_desc_counts, key=ipr_desc_counts.get, reverse=True))
        go_terms_str = ", ".join(sorted(go_terms_set))
        metacyc_str = ", ".join(sorted(metacyc_set))
        reactome_str = ", ".join(sorted(reactome_set))

        out_sum.write(f"{og}\t{num_proteins}\t{median_length}\t{domain_str}\t{go_terms_str}\t{ipr_desc_str}\t{metacyc_str}\t{reactome_str}\n")

print(f"Per-protein annotation saved to {output_per_protein}")
print(f"Orthogroup summary saved to {output_summary}")
