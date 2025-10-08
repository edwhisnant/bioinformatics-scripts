#!/usr/bin/bash

#SBATCH --mem-per-cpu=2G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control/logs/extractITS/Lasallia_pustulata_NCBI_GCA_937840595.1.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control/logs/extractITS/Lasallia_pustulata_NCBI_GCA_937840595.1.err
#SBATCH --partition=common

# === CONFIGURATION ===
HMM_DIR="../databases/extract_its/diego-rDNA-HMMs/hmmer"
GENOME=/hpc/group/bio1/ewhisnant/comp-genomics/cleaned-genomes/lecanoromycetes/Lasallia_pustulata_NCBI_GCA_937840595.1_cleaned.fasta
# GENOME=/hpc/group/bio1/ewhisnant/armaleo-data/Clagr3/assemblies/Clagr3_AssemblyScaffolds.fasta
OUTPUT_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control/extractITS

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate hmmer

mkdir -p ${OUTPUT_DIR}

# === Use nhmmer and Diego's custom HMMs to extract rDNA sequences
# === SETUP ===
mkdir -p "$OUTPUT_DIR"

# === LOOP OVER EACH .hmm FILE ===
for hmm in "$HMM_DIR"/*.hmm; do
    base=$(basename "$hmm" .hmm)
    echo "🔍 Processing $base"

    # Output files
    tbl="$OUTPUT_DIR/${base}.tbl"
    bed="$OUTPUT_DIR/${base}.bed"
    fasta="$OUTPUT_DIR/${base}.fna"
    log="$OUTPUT_DIR/${base}.log"

    # Run nhmmer
    nhmmer \
        --cpu 32 \
        --tblout "$tbl" \
        -o "$log" \
        "$hmm" "$GENOME"

    # Extract coordinates from .tbl
    awk '!/^#/ {
        s = ($7 < $8 ? $7 : $8);
        e = ($7 > $8 ? $7 : $8);
        strand = ($7 <= $8 ? "+" : "-");
        print $1 "\t" (s-1) "\t" e "\t" $3 "\t.\t" strand
    }' "$tbl" > "$bed"

    # Extract sequences
    bedtools getfasta \
        -fi "$GENOME" \
        -bed "$bed" \
        -fo "$fasta" \
        -s

    echo "✅ Done with $base — output: $fasta"
done

conda deactivate