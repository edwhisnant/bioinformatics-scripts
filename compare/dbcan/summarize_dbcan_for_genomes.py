import pandas as pd
import glob
import os
from collections import Counter
import re

def keep_most_specific(families):
    """
    Given a list of families, remove duplicates and keep the most specific subfamilies only.
    For example:
      - ['AA1', 'AA1'] -> ['AA1']
      - ['AA1_3', 'AA1'] -> ['AA1_3']
      - ['GH13', 'CBM13'] -> ['GH13', 'CBM13']
      - ['AA1_3', 'AA1', 'AA1'] -> ['AA1_3']
    """
    # Remove exact duplicates first
    unique_fams = list(set(families))

    # Sort by length descending: longer names are more specific
    unique_fams.sort(key=len, reverse=True)

    to_keep = []
    for fam in unique_fams:
        # Check if fam is subfamily of any already kept family
        # A family is considered subfamily if one matches the other with an optional _number suffix
        # For example, AA1_3 is subfamily of AA1
        is_subfamily = False
        for kept in to_keep:
            # Regex to match subfamily relation:
            # fam is subfamily of kept if fam starts with kept + optional _number
            # OR kept is subfamily of fam if kept starts with fam + optional _number
            pattern_fam = re.escape(kept) + r'(_\d+)?$'
            pattern_kept = re.escape(fam) + r'(_\d+)?$'

            if re.fullmatch(pattern_fam, fam) or re.fullmatch(pattern_kept, kept):
                is_subfamily = True
                # If fam is longer (more specific), replace kept with fam
                if len(fam) > len(kept):
                    to_keep.remove(kept)
                    to_keep.append(fam)
                break
        if not is_subfamily:
            to_keep.append(fam)

    # Remove duplicates from to_keep in case of replacement
    return list(set(to_keep))


# Directory containing all overview.tsv files
IN_DIR = "/hpc/group/bio1/ewhisnant/comp-genomics/compare/dbcan/lecanoromycetes/v25.08.19"
files = glob.glob(os.path.join(IN_DIR, "*/overview.tsv"))

# Master dictionary: genome -> Counter of families
genome_cazyme_counts = {}

for file in files:
    genome_id = os.path.basename(os.path.dirname(file))
    df = pd.read_csv(file, sep='\t')

    if 'Recommend Results' not in df.columns:
        continue

    # Clean up: remove e-values like GH5_e23 → GH5
    df['Recommend Results'] = df['Recommend Results'].str.replace(r'_e\d+', '', regex=True)

    # Filter out '-' or missing
    valid_families = df['Recommend Results'][df['Recommend Results'] != '-']

    processed_families = []

    processed_entries = []

    for fam_entry in valid_families:
        fam_list = fam_entry.split('|')

        # If all identical, keep one; else keep most specific subset
        collapsed = keep_most_specific(fam_list)

        # Join into a string (sorted to keep consistent order)
        collapsed_str = '|'.join(sorted(collapsed))

        processed_entries.append(collapsed_str)

    


    # Count frequencies for this genome
    fam_counts = Counter(processed_entries)
    genome_cazyme_counts[genome_id] = fam_counts

# Create DataFrame with genomes as rows and CAZyme families as columns
summary_df = pd.DataFrame.from_dict(genome_cazyme_counts, orient='index').fillna(0).astype(int)

# Save the summary matrix
output_path = os.path.join(IN_DIR, "cazyme_matrix.tsv")
summary_df.to_csv(output_path, sep='\t')

print(f"✅ Matrix written to {output_path}")
