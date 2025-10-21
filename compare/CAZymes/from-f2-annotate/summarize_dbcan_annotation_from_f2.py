#!/usr/bin/env python3
import pandas as pd
import glob
import os
from collections import Counter
import argparse as ap
import re

def parse_args():
    parser = ap.ArgumentParser(
        prog="extract_dbcan_annotations_from_f2.py",
        usage="extract_dbcan_annotations_from_f2.py [options]",
        description="Extract and summarize CAZyme annotations from funannotate2 results directories.",
        epilog="Written by Eric Whisnant [Lutzoni Lab, Duke University; edw36@duke.edu]. All rights reserved."
    )
    parser.add_argument(
        '-i', '--indir', required=True, type=str,
        help='Directory containing a collection of funannotate2 results folders.'
    )
    parser.add_argument(
        '-o', '--outdir', required=True, type=str,
        help='Directory to save output summary TSV files.'
    )
    parser.add_argument(
        '-n', '--filenames', required=True, type=str,
        help='Filename for output summary TSV (e.g., summary.tsv).'
    )

    return parser.parse_args()


def main():
    args = parse_args()
    indir = args.indir
    outdir = args.outdir
    filename = args.filenames

    os.makedirs(outdir, exist_ok=True)

    genome_data = []

    # Iterate through each funannotate2 genome folder
    for folder in glob.glob(os.path.join(indir, '*/')):
        genome_name = os.path.basename(os.path.normpath(folder))
        dbcan_file = os.path.join(folder, 'annotate_misc', 'annotations.dbcan.tsv')

        if os.path.exists(dbcan_file):
            df = pd.read_csv(dbcan_file, sep='\t', header=None)
            if df.shape[1] < 3:
                print(f"Warning: {dbcan_file} has fewer than 3 columns; skipping.")
                continue

            # Remove prefix and handle multiple CAZyme annotations per protein
            df[2] = df[2].astype(str).str.replace('CAZy:', '', regex=False)

            # Split entries that have multiple CAZyme annotations (e.g., GH5,CBM13)
            

            # Count unique annotations
            unique_annotations = df[2] 
            cazyme_counts = Counter(unique_annotations)

            genome_entry = {'Genome': genome_name}
            genome_entry.update(cazyme_counts)
            genome_data.append(genome_entry)
        else:
            print(f"Warning: No dbCAN file found for {genome_name}")

    if not genome_data:
        print("No valid dbCAN annotation files found.")
        return

    # === Family-level CAZyme summary ===
    summary_df = pd.DataFrame(genome_data).fillna(0)
    summary_df.set_index('Genome', inplace=True)

    # Ensure all numeric-like columns are integers
    for col in summary_df.columns:
        # Try to convert to numeric safely
        summary_df[col] = pd.to_numeric(summary_df[col], errors='coerce').fillna(0).astype(int)

    family_outfile = os.path.join(outdir, 'low.level.summary.' + filename + '.tsv')
    print(f"=== Saving family-level CAZyme summary to {family_outfile}")
    summary_df.to_csv(family_outfile, sep='\t')


    # === High-level class summary (GH, GT, PL, CE, AA, CBM) ===
    class_summary = pd.DataFrame(index=summary_df.index)
    for class_prefix in ['GH', 'GT', 'PL', 'CE', 'AA', 'CBM']:
        cols = [col for col in summary_df.columns if col.startswith(class_prefix)]
        class_summary[class_prefix] = summary_df[cols].sum(axis=1) if cols else 0

    class_summary['Total_CAZymes'] = class_summary.sum(axis=1)

    class_outfile = os.path.join(outdir, 'high.level.summary.' + filename + '.tsv')
    print(f"=== Saving high-level CAZyme summary to {class_outfile}")
    class_summary.to_csv(class_outfile, sep='\t')


if __name__ == "__main__":
    main()
