import os
import glob
import csv
from collections import defaultdict
from goatools.obo_parser import GODag

# Paths
EGGNOG_DIR = "/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/proteins/Results_May04/eggnog-annotations"
INTERPRO_DIR = "/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/proteins/Results_May04/iprscan-annotations"
GO_OBO_PATH = "/hpc/group/bio1/ewhisnant/databases/go/go.obo"
OUTPUT_FILE = "/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/proteins/Results_May04/orthogroup_go_summary.tsv"

# Load GO ontology
print("Loading GO ontology...")
go_dag = GODag(GO_OBO_PATH)

# Data structure: orthogroup -> namespace -> set of (GO ID, name)
orthogroup_go = defaultdict(lambda: defaultdict(set))

# --- Process EggNOG annotations ---
print("Processing EggNOG annotations...")
for filepath in glob.glob(f"{EGGNOG_DIR}/*.emapper.annotations"):
    og = os.path.basename(filepath).split(".")[0]
    with open(filepath, "r") as f:
        for line in f:
            if line.startswith("#"):
                continue
            fields = line.strip().split("\t")
            if len(fields) < 16:
                continue
            go_field = fields[13]
            if go_field and go_field != "-":
                for go_id in go_field.split(","):
                    go_id = go_id.strip()
                    if go_id in go_dag:
                        term = go_dag[go_id]
                        ns = term.namespace
                        ns_short = {"biological_process": "BP", "molecular_function": "MF", "cellular_component": "CC"}.get(ns, None)
                        if ns_short:
                            orthogroup_go[og][ns_short].add((go_id, term.name))

# --- Process InterProScan annotations ---
print("Processing InterProScan annotations...")
for file in os.listdir(INTERPRO_DIR):
    if not file.endswith(".tsv"):
        continue
    og = file.replace(".interproscan.tsv", "")
    filepath = os.path.join(INTERPRO_DIR, file)
    with open(filepath) as f:
        for line in f:
            if line.startswith("#"):
                continue
            fields = line.strip().split("\t")
            if len(fields) < 14:
                continue
            go_field = fields[12]
            if go_field and go_field != "-":
                for go_id in go_field.split("|"):
                    go_id = go_id.strip().split("(")[0]
                    if go_id in go_dag:
                        term = go_dag[go_id]
                        ns = term.namespace
                        ns_short = {"biological_process": "BP", "molecular_function": "MF", "cellular_component": "CC"}.get(ns, None)
                        if ns_short:
                            orthogroup_go[og][ns_short].add((go_id, term.name))

# Collect all orthogroups across both datasets
all_orthogroups = set(orthogroup_go.keys())
for file in glob.glob(f"{EGGNOG_DIR}/*.emapper.annotations"):
    og = os.path.basename(file).split(".")[0]
    all_orthogroups.add(og)
for file in os.listdir(INTERPRO_DIR):
    if file.endswith(".tsv"):
        og = file.replace(".interproscan.tsv", "")
        all_orthogroups.add(og)

# Write output
print(f"Writing summary to: {OUTPUT_FILE}")
with open(OUTPUT_FILE, "w") as out:
    writer = csv.writer(out, delimiter="\t")
    writer.writerow([
        "Orthogroup",
        "BP_GO_IDs", "BP_Names",
        "MF_GO_IDs", "MF_Names",
        "CC_GO_IDs", "CC_Names"
    ])

    for og in sorted(all_orthogroups):
        row = [og]
        for ns in ['BP', 'MF', 'CC']:
            terms = sorted(orthogroup_go[og][ns])
            ids = "; ".join(t[0] for t in terms)
            names = "; ".join(t[1] for t in terms)
            row.extend([ids if ids else "-", names if names else "-"])
        writer.writerow(row)

print("Done.")
