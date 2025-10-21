#!/usr/bin/env bash

IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/dbcan/lecanoromycetes/v25.08.19
ls ${IN_DIR}/*/overview.tsv

TEMP_DIR=${IN_DIR}/temp_cazy_counts
SUMMARY_TABLE=${IN_DIR}/summary_overview.tsv

mkdir -p "$TEMP_DIR"
rm -f "$TEMP_DIR"/*.tsv "$SUMMARY_TABLE"

echo "Genome	CazymeFamily	Count" > "$TEMP_DIR/all_counts.tsv"

for f in ${IN_DIR}/*/overview.tsv; do
    BASENAME=$(basename $(dirname "$f"))

    awk -F'\t' -v genome="$BASENAME" '
    BEGIN { OFS="\t" }
    NR > 1 && $6 >= 2 && $7 != "-" {
        # Split $7 on pipe if present
        n = split($7, parts, "|")
        if (n == 2 && parts[1] == parts[2]) {
            # If both parts equal, collapse to one
            family_str = parts[1]
        } else {
            # Otherwise keep original string (or decide how to handle)
            family_str = $7
        }
        # Extract family code before underscore (from collapsed string)
        match(family_str, /^([A-Z]+[0-9]+)/, arr)
        family = arr[1]
        print genome, family
    }' "$f" \
    | sort | uniq -c \
    | awk '{ print $2 "\t" $3 "\t" $1 }' >> "$TEMP_DIR/all_counts.tsv"
done


# Now pivot into wide format: genomes = rows, CAZy families = columns
csvpivot "$TEMP_DIR/all_counts.tsv" \
    --rows Genome \
    --columns CazymeFamily \
    --values Count \
    --default 0 > "$SUMMARY_TABLE"

echo "✅ Summary table written to: $SUMMARY_TABLE"
