#!/bin/bash

# Change to your scripts directory
cd /hpc/group/bio1/ewhisnant/comp-genomics/scripts || exit 1

# Stage all changes (except files ignored by .gitignore)
git add .

# Commit with a timestamped message
git commit -m "Update on $(date '+%Y-%m-%d %H:%M:%S')" 

# Pull remote changes to avoid conflicts
git pull --rebase origin main

# Push your changes
git push origin main
