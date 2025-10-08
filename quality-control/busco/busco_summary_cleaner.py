import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Read the input TSV file
busco_summary = pd.read_csv("combined_summary.tsv", sep="\t")

# Calculate percentages
busco_summary["Complete_BUSCOs_percent"] = busco_summary["Complete_BUSCOs"] / busco_summary["Total_BUSCOs"]
busco_summary["Single_Copy_BUSCOs_percent"] = busco_summary["Single_Copy_BUSCOs"] / busco_summary["Total_BUSCOs"]
busco_summary["Duplicated_BUSCOs_percent"] = busco_summary["Duplicated_BUSCOs"] / busco_summary["Total_BUSCOs"]
busco_summary["Fragmented_BUSCOs_percent"] = busco_summary["Fragmented_BUSCOs"] / busco_summary["Total_BUSCOs"]
busco_summary["Missing_BUSCOs_percent"] = busco_summary["Missing_BUSCOs"] / busco_summary["Total_BUSCOs"]

# Rename columns
busco_summary = busco_summary.rename(columns={
    "Scaffold N50": "scaffold_N50",
    "Contigs N50": "contig_N50",
    "Number of scaffolds": "num_scaffolds",
    "Number of contigs": "num_contigs",
    "Total length": "total_length_bp",
    "Percent gaps": "percent_gaps"
})

# Write the updated data back to a TSV file
busco_summary.to_csv("combined_summary.tsv", sep="\t", index=False)


# What organisms are < 80% complete?

print("=== Extracting genomes with < 80% completeness")

below_80perc = busco_summary[busco_summary['Complete_BUSCOs_percent'] <= 0.80].copy()

below_80perc.to_csv("combined_summary_below80.tsv", sep="\t", index=False)


# What organisms are < 85% complete?

print("=== Extracting genomes with < 85% completeness")

below_85perc = busco_summary[busco_summary['Complete_BUSCOs_percent'] <= 0.85].copy()

below_85perc.to_csv("combined_summary_below85.tsv", sep="\t", index=False)

# What organisms are are < 90% complete?

print("=== Extracting genomes with < 90% completeness")

below_90perc = busco_summary[busco_summary['Complete_BUSCOs_percent'] <= 0.90].copy()

below_90perc.to_csv("combined_summary_below90.tsv", sep="\t", index=False)

# What organisms are < 95% complete?

print("=== Extracting genomes with < 95% completeness")

below_95perc = busco_summary[busco_summary['Complete_BUSCOs_percent'] <= 0.95].copy()

below_95perc.to_csv("combined_summary_below95.tsv", sep="\t", index=False)

# === Plot the completeness in a bar plot ===

print("=== Plotting large summary BUSCO completeness bar plot")

# Choose the column that identifies the organism/genome for y-axis labels
label_column = "Organism"  # Change this to your actual column name (e.g., "Organism", "Sample", etc.)

plt.figure(figsize=(8, max(4, len(busco_summary) * 0.5)))
plt.barh(busco_summary[label_column], busco_summary["Complete_BUSCOs_percent"], color="skyblue")
plt.xlabel('Complete BUSCOs Percent')
plt.ylabel('Genome')
plt.title('BUSCO Completeness by Genome')
plt.tight_layout()
plt.savefig("busco_completeness_barplot.png", dpi=300)
plt.show()
