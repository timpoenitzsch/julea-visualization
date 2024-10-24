#!/bin/bash

# Setze den Basisordner und den Ausgabeordner
BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"
OUTPUT_DIR="$BASE_DIR/benchmark_csv_total"
OUTPUT_FILE="$OUTPUT_DIR/benchmark_total.csv"

# Erstelle den Ordner für die Gesamt-CSV-Datei, falls er nicht existiert
mkdir -p "$OUTPUT_DIR"

# Überschrift für die neue Spalte
echo "name,elapsed,operations,bytes,total_elapsed,timestamp" > "$OUTPUT_FILE"

# Gehe durch alle CSV-Dateien im Ordner benchmark_csv und füge sie der Gesamtdatei hinzu
for FILE in "$CSV_DIR"/benchmark_results_*.csv; do
  # Extrahiere den Timestamp (Unix-Zeit) aus dem Dateinamen
  FILE_TIMESTAMP=$(basename "$FILE" | cut -d'_' -f3 | sed 's/.csv//')

  # Lese die Daten aus der CSV-Datei (überspringe die Kopfzeile) und füge den Timestamp hinzu
  tail -n +2 "$FILE" | while IFS=$'\t' read -r name elapsed operations bytes total_elapsed; do
    # Füge die Zeile zur Ausgabe-Datei hinzu, inklusive Timestamp
    echo "$name,$elapsed,$operations,$bytes,$total_elapsed,$FILE_TIMESTAMP" >> "$OUTPUT_FILE"
  done
done

echo "Die zusammengeführte Datei wurde erfolgreich erstellt: $OUTPUT_FILE"
