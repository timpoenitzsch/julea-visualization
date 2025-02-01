#!/bin/bash

# Set base- and output-directory
BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"
OUTPUT_DIR="$BASE_DIR/benchmark_csv_total"
OUTPUT_FILE="$OUTPUT_DIR/benchmark_total.csv"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Überschrift für die neue Spalte
echo "name,elapsed,operations,bytes,total_elapsed,timestamp" > "$OUTPUT_FILE"

# Merge all CSV-files
for FILE in "$CSV_DIR"/benchmark_results_*.csv; do
  # extract timestamp from filename
  FILE_TIMESTAMP=$(basename "$FILE" | cut -d'_' -f3 | sed 's/.csv//')

  tail -n +2 "$FILE" | while IFS=$'\t' read -r name elapsed operations bytes total_elapsed; do
    echo "$name,$elapsed,$operations,$bytes,$total_elapsed,$FILE_TIMESTAMP" >> "$OUTPUT_FILE"
  done
done

echo "Die zusammengeführte Datei wurde erfolgreich erstellt: $OUTPUT_FILE"
