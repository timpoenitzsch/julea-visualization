#!/bin/bash

# name of the CSV-file
BASE_DIR="../"
CSV_DIR="$BASE_DIR/commit_timestamps"
OUTPUT_FILE="$CSV_DIR/commit_timestamps.csv"

mkdir -p "$CSV_DIR"

# header
echo "SHA,timestamp" > "$OUTPUT_FILE"

# add commit information
git log --pretty=format:'%h,%at' -- $(git ls-tree -r HEAD --name-only) >> "$OUTPUT_FILE" 
#git log --pretty=format:'%h,%at' >> "$OUTPUT_FILE"  

echo "Die Commit-Informationen wurden in $OUTPUT_FILE gespeichert."
