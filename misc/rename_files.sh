#!/usr/bin/env bash
# Path to renaming map and the files
# MAP is a txt file that has two columns (no headers): (1) Old-name and (2) New name for file
MAP=/hpc/group/bio1/ewhisnant/comp-genomics/genomes-database/other-pezizomycotina/pezizomycotina_basenames.txt
RENAME_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/ascomycota/select_pezizomycotina_25.09.24/unmasked

while IFS=$'\t' read -r old new; do
    # Trim whitespace
    old=$(echo "$old" | xargs)
    new=$(echo "$new" | xargs)

    # Skip if either field is missing
    if [[ -z "$old" || -z "$new" ]]; then
        echo "Warning: Skipping line with empty old or new name."
        continue
    fi

    old_file="$RENAME_DIR/${old}.fa"
    new_file="$RENAME_DIR/${new}.fa"

    if [[ -f "$old_file" ]]; then
        mv "$old_file" "$new_file"
        echo "Renamed '$old_file' to '$new_file'"
    else
        echo "Warning: File '$old_file' not found, skipping."
    fi
done < "$MAP"

echo "File renaming process complete."