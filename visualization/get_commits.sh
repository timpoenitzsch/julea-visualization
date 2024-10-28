#!/bin/bash

# Name der CSV-Datei
BASE_DIR="../"
CSV_DIR="$BASE_DIR/commit_timestamps"
OUTPUT_FILE="$CSV_DIR/commit_timestamps.csv"

mkdir -p "$CSV_DIR"

# Schreibe den Kopf in die CSV-Datei
echo "SHA,timestamp" > "$OUTPUT_FILE"

# Füge die Informationen der Commits hinzu
git log --pretty=format:'%H,%at' >> "$OUTPUT_FILE"

echo "Die Commit-Informationen wurden in $OUTPUT_FILE gespeichert."
