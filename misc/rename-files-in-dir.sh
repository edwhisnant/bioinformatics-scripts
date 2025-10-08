#!/usr/bin/bash
# This script renames files in the current directory that start with a specific prefix to a new name format.

# Change to the directory where the files are located
TARGET_DIR="$1"

# Variables for renaming
FILES_TO_RENAME_STARTS_WITH=$2
NEW_NAME=$3

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory $TARGET_DIR does not exist."
    exit 1
fi

# Change to the target directory
cd "$TARGET_DIR"

# Check if the variables are set
if [ -z "$FILES_TO_RENAME_STARTS_WITH" ] || [ -z "$NEW_NAME" ]; then
    echo "Error: Both FILES_TO_RENAME_STARTS_WITH and NEW_NAME must be provided."
    exit 1
fi

# Check if there are files to rename
if ! ls ${FILES_TO_RENAME_STARTS_WITH}.* 1> /dev/null 2>&1; then
    echo "No files matching ${FILES_TO_RENAME_STARTS_WITH}.* found. Exiting."
    exit 1
fi

# Loop through all files that match the pattern
for file in ${FILES_TO_RENAME_STARTS_WITH}.*; do
    # Extract the file extension
    extension="${file#$FILES_TO_RENAME_STARTS_WITH}"
    
    # Rename the file
    mv "$file" "${NEW_NAME}${extension}"
    
    # Check if the rename was successful
    if [ $? -eq 0 ]; then
        echo "Renamed $file to ${NEW_NAME}${extension}"
    else
        echo "Error renaming $file. Skipping."
    fi
done