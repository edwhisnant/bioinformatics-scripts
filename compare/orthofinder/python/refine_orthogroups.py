#!/usr/bin/env python3
import argparse
import os
import numpy as np
import pandas as pd
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq

def refine_orthogroup(fasta_path, basename, output_dir, og_df, method="sd"):
    """Refine sequences in a single orthogroup and return counts + summary stats."""
    seq_data = []
    for seq_record in SeqIO.parse(fasta_path, "fasta"):
        seq_data.append({
            'seq_id': seq_record.id,
            'seq_len': len(seq_record),
            'seq_seq': str(seq_record.seq)
        })
    df = pd.DataFrame(seq_data)

    if df.empty:
        return {}, None

    # Stats before
    mean_before = df['seq_len'].mean()
    sd_before = df['seq_len'].std()
    total = len(df)

    lengths = df['seq_len'].values

    if method == "sd":
        mu, sigma = lengths.mean(), lengths.std()
        keep_mask = (lengths >= mu - sigma) & (lengths <= mu + sigma)
    elif method == "mad":
        median = np.median(lengths)
        mad = np.median(np.abs(lengths - median))
        cutoff = 2.5 * mad
        keep_mask = (lengths >= median - cutoff) & (lengths <= median + cutoff)
    elif method == "quantile":
        low, high = np.quantile(lengths, [0.05, 0.95])
        keep_mask = (lengths >= low) & (lengths <= high)
    else:
        keep_mask = np.ones_like(lengths, dtype=bool)

    refined_df = df[keep_mask]

    # Stats after
    mean_after = refined_df['seq_len'].mean() if not refined_df.empty else 0
    sd_after = refined_df['seq_len'].std() if not refined_df.empty else 0
    refined = len(refined_df)
    removed = total - refined

    # Save refined FASTA as {basename}.fa
    refined_records = [
        SeqRecord(Seq(row['seq_seq']), id=row['seq_id'], description="")
        for _, row in refined_df.iterrows()
    ]
    file_out = os.path.join(output_dir, f"{basename}.fa")
    SeqIO.write(refined_records, file_out, "fasta")

    # Map sequences → species
    og_row = og_df[og_df['Orthogroup'] == basename]
    seq_to_species = {}
    for col in og_row.columns[1:]:
        val = og_row.iloc[0][col] if not og_row.empty else None
        if pd.notna(val) and val != "":
            seq_ids = val.split(", ")
            for seq_id in seq_ids:
                seq_to_species[seq_id] = col

    species_counts = {col: 0 for col in og_df.columns[1:]}
    for seq_id in refined_df['seq_id']:
        if seq_id in seq_to_species:
            sp = seq_to_species[seq_id]
            species_counts[sp] += 1

    # Summary row
    summary_row = {
        "Orthogroup": basename,
        "Total": total,
        "Refined": refined,
        "Removed": removed,
        "Mean_Before": round(mean_before, 2),
        "SD_Before": round(sd_before, 2),
        "Mean_After": round(mean_after, 2) if refined > 0 else 0,
        "SD_After": round(sd_after, 2) if refined > 0 else 0,
        "Method": method
    }

    print(f"{basename}: total={total}, refined={refined}, removed={removed}, "
          f"mean_before={mean_before:.1f}, sd_before={sd_before:.1f}, "
          f"mean_after={mean_after:.1f}, sd_after={sd_after:.1f}, method={method}")

    return species_counts, summary_row


def main():
    parser = argparse.ArgumentParser(description="Refine Orthogroups by seq length filtering")
    parser.add_argument("-i", "--input", required=True, help="Path to Orthogroup_Sequences directory")
    parser.add_argument("-o", "--output", required=True, help="Output directory for refined FASTAs + summary tables")
    parser.add_argument("-l", "--list", required=True, help="File with orthogroup list (one per line, can include .fa)")
    parser.add_argument("-t", "--tsv", required=True, help="Path to Orthogroups.tsv")
    parser.add_argument("-m","--method", choices=["sd", "mad", "quantile"], default="sd",
                        help="Filtering method: sd (mean±SD), mad (median±MAD), or quantile (default 5–95 percent)")
    args = parser.parse_args()

    os.makedirs(args.output, exist_ok=True)

    # Load Orthogroups.tsv
    og_df = pd.read_csv(args.tsv, sep="\t", dtype=str).fillna("")

    # Load OG list and strip ".fa" if present
    with open(args.list) as f:
        og_list = [line.strip().replace(".fa", "") for line in f if line.strip()]

    all_species = list(og_df.columns[1:])
    summary_matrix = pd.DataFrame(index=all_species)
    summary_rows = []

    for og in og_list:
        fasta_path = os.path.join(args.input, f"{og}.fa")
        if not os.path.exists(fasta_path):
            print(f"Warning: {fasta_path} not found, skipping")
            continue
        counts, summary_row = refine_orthogroup(fasta_path, og, args.output, og_df, method=args.method)
        if counts:
            summary_matrix[og] = pd.Series(counts)
        if summary_row:
            summary_rows.append(summary_row)

    # Write all-species × OG counts matrix
    summary_matrix_out = os.path.join(args.output, "Orthogroup_Refined_Gene_Counts.tsv")
    summary_matrix.to_csv(summary_matrix_out, sep="\t")

    # Write refinement summary
    refinement_summary_out = os.path.join(args.output, "Orthogroup_Refinement_Summary.tsv")
    pd.DataFrame(summary_rows).to_csv(refinement_summary_out, sep="\t", index=False)

    print(f"Species count matrix written to: {summary_matrix_out}")
    print(f"Refinement summary written to: {refinement_summary_out}")


if __name__ == "__main__":
    main()