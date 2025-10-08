#!/bin/bash

# Define variables

# == As long as the name of the file in the source directory matches "basename" in the tsv and basename is the first column
TSV_FILE=/hpc/group/bio1/ewhisnant/comp-genomics/genomes-database/lecanoromycetes/filtered-genomes/busco-complete-95-coverage-25x.tsv  # Path to your TSV file
SOURCE_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/lecanoromycetes       # Directory containing the files
DEST_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/filtered-genomes/lecanoromycetes    # Directory to copy files to

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Extract the basenames from the TSV file (skipping the header) and copy matching files
awk 'NR > 1 {print $1}' "$TSV_FILE" | while read BASENAME; do
    FILE="$SOURCE_DIR/${BASENAME}.fa"  # Adjust the file extension if needed
    if [ -f "$FILE" ]; then
        cp "$FILE" "$DEST_DIR"
        echo "Copied: $FILE to $DEST_DIR"
    else
        echo "File not found: $FILE"
    fi
done

ls -l "$DEST_DIR" | wc -l
echo "Files copied to $DEST_DIR"