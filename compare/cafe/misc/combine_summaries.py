import csv
import argparse
import re
import os
import glob

def extract_values_from_path(path):
    """
    Extract number_of_hogs_removed and gamma_partitions from path.
    Only accept paths that include both values (e.g., /89filtered-G2/)
    """
    match = re.search(r"/(\d+)filtered-G(\d+)/", path)
    if match:
        number_of_hogs_removed = int(match.group(1))
        gamma_partitions = int(match.group(2))
        return number_of_hogs_removed, gamma_partitions
    else:
        print(f"⚠️ Skipping file (missing -G*): {path}")
        return None, None

def main():
    parser = argparse.ArgumentParser(description="Combine CAFE Gamma_summary files with hogs_removed and gamma_partitions info.")
    parser.add_argument('inputs', nargs='+', help='Paths or glob patterns to Gamma_summary.tsv files (e.g. */Gamma_summary.tsv)')
    parser.add_argument('-o', '--output', required=True, help='Path to output TSV file')
    args = parser.parse_args()

    # Expand all input patterns
    input_files = []
    for pattern in args.inputs:
        expanded = glob.glob(pattern)
        if not expanded:
            print(f"⚠️ No files matched: {pattern}")
        input_files.extend(expanded)

    if not input_files:
        print("❌ No input files to process. Exiting.")
        return

    writer = None
    rows_written = 0

    with open(args.output, "w", newline="") as out_f:
        for infile in input_files:
            print(f"Reading {infile}...")
            hogs_removed, gamma_partitions = extract_values_from_path(infile)
            if hogs_removed is None or gamma_partitions is None:
                continue  # skip this file

            try:
                with open(infile, newline="") as in_f:
                    reader = csv.DictReader(in_f, delimiter="\t")
                    for i, row in enumerate(reader):
                        print(f"  Row {i}: {row}")
                        if not any(row.values()):
                            print("    → Skipping empty row")
                            continue
                        row["number_of_hogs_removed"] = hogs_removed
                        row["gamma_partitions"] = gamma_partitions
                        if writer is None:
                            writer = csv.DictWriter(out_f, fieldnames=list(row.keys()), delimiter="\t")
                            writer.writeheader()
                        writer.writerow(row)
                        rows_written += 1
            except FileNotFoundError:
                print(f"❌ File not found: {infile}")
            except Exception as e:
                print(f"❌ Error processing {infile}: {e}")

    print(f"\n✅ Done. {rows_written} rows written to {args.output}")

if __name__ == "__main__":
    main()
