#!/usr/bin/env bash
set -euo pipefail

PEZIZO_TSV=/hpc/group/bio1/ewhisnant/comp-genomics/genomes-database/other-pezizomycotina/selected-pezizomycotina-genomes-v25.09.24.tsv
OUTDIR=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/ascomycota/select_pezizomycotina_25.09.24/raw
SEARCH_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/ascomycota

dos2unix "$PEZIZO_TSV"   # normalize TSV endings
mkdir -p "$OUTDIR"

# Skip header, extract needed columns
tail -n +2 "$PEZIZO_TSV" | awk -F'\t' '{
    link=$24
    basename=$25
    diego=$5
    print link "\t" basename "\t" diego
}' | while IFS=$'\t' read -r link basename diego_file; do
    
    # 🧹 sanitize values to remove \r, spaces, accidental whitespace
    link=$(echo "$link" | tr -d '\r')
    basename=$(echo "$basename" | tr -d '\r' | tr -d '\n' | sed 's/[[:space:]]/_/g')
    diego_file=$(echo "$diego_file" | tr -d '\r')

    # define final path
    final_path="$OUTDIR/${basename}.fa"

    if [[ "$link" != "NA" && -n "$link" ]]; then
        echo "📥 Downloading $basename from $link ..."
        wget -q -O "${final_path}.gz" "$link" || {
            echo "❌ Failed to download $link"
            continue
        }
        # decompress if gzipped
        if file "${final_path}.gz" | grep -q 'gzip'; then
            gunzip -f "${final_path}.gz"
        else
            mv "${final_path}.gz" "$final_path"
        fi

    elif [[ "$diego_file" != "NA" && -n "$diego_file" ]]; then
        echo "🔍 Searching for files matching: $diego_file*"
        found=$(find "$SEARCH_DIR" -type f -name "${diego_file}.*" | head -n 1)
        if [[ -n "$found" ]]; then
            echo "📂 Copying $found → $final_path"
            cp "$found" "$final_path"
        else
            echo "⚠️ File not found for $basename ($diego_file)"
        fi
    else
        echo "⚠️ No link or diego_file_name for $basename"
    fi
done