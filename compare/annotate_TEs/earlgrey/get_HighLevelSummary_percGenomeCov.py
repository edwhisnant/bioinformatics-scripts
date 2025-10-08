import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from io import StringIO
import os
from glob import glob
import argparse

# Run in the `earlgrey_sum` conda environment
def load_md_table(filepath):
    basename = os.path.splitext(os.path.basename(filepath))[0]
    with open(filepath, 'r') as f:
        markdown_table_string = f.read()

    df = pd.read_csv(
        StringIO(markdown_table_string),
        sep="|",
        engine="python",
        na_values=["NA"]
    )

    # Clean table
    df = df.dropna(axis=1, how="all").dropna(axis=0, how="all")
    df.columns = [col.strip().replace(" ", "_") for col in df.columns]
    df = df[~df[df.columns[0]].astype(str).str.contains("---")]

    # Ensure numeric
    df['%_Genome_Coverage'] = (
        df['%_Genome_Coverage']
        .astype(str).str.strip().replace("NA", np.nan).astype(float)
    )

    # Normalize TE class labels
    df['TE_Classification'] = df['TE_Classification'].astype(str).str.strip()
    df['Genome'] = basename

    return df[['Genome', 'TE_Classification', '%_Genome_Coverage']]


def main():
    parser = argparse.ArgumentParser(
        description="Summarize TE coverage from multiple .kable markdown tables prduced by EarlGrey."
    )
    parser.add_argument(
        "--indir",
        required=True,
        help="Input directory to search recursively for .highLevelCount.kable files from EarlGrey outputs"
    )
    parser.add_argument(
        "--outdir",
        required=True,
        help="Output directory where summary results (TSV + plot) will be saved"
    )

    args = parser.parse_args()
    indir = args.indir
    outdir = args.outdir

    os.makedirs(outdir, exist_ok=True)

    # === Load all markdown tables ===
    all_files = glob(os.path.join(indir, "**", "*.highLevelCount.kable"), recursive=True)

    print(f"Found {len(all_files)} highLevelCount.kable files")
    if not all_files:
        raise FileNotFoundError("No .highLevelCount.kable files found – check the input directory!")

    # Combine and pivot
    df_all = pd.concat([load_md_table(f) for f in all_files], ignore_index=True)
    df_wide = df_all.pivot_table(
        index="Genome",
        columns="TE_Classification",
        values="%_Genome_Coverage",
        aggfunc="sum"
    ).fillna(0)

    # Collapse duplicate TE columns if still present
    df_wide = df_wide.groupby(level=0, axis=1).sum()

    # === Save outputs ===
    out_table = os.path.join(outdir, "TE_percent_coverage_wide.tsv")
    df_wide.to_csv(out_table, sep="\t")
    print(f"Saved summary table: {out_table}")

    # === Plotting ===
    fig_height = 0.25 * len(df_wide) if len(df_wide) > 20 else 6
    ax = df_wide.plot(
        kind="barh",
        stacked=True,
        figsize=(15, fig_height),
        colormap="tab20"
    )

    ax.set_xlabel("% Genome Coverage")
    ax.set_ylabel("Genome")
    ax.set_title("TE Genome Coverage Across Genomes")

    plt.legend(title="TE Class", bbox_to_anchor=(1.05, 1), loc="upper left")
    plt.tight_layout()

    out_plot = os.path.join(outdir, "TE_percent_coverage_stacked_barplot.png")
    plt.savefig(out_plot, dpi=300, bbox_inches="tight")
    print(f"Saved stacked bar plot: {out_plot}")

    plt.show()


if __name__ == "__main__":
    main()
