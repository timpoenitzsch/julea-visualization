#!/bin/bash

# Setze den Basisordner
BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"

# Erstelle den Ordner für die CSV-Dateien, falls er nicht existiert
mkdir -p "$CSV_DIR"

# Erzeuge den Namen der neuen CSV-Datei mit dem aktuellen Unix-Timestamp
UNIX_TIMESTAMP=$(date +%s)
CSV_FILE="$CSV_DIR/benchmark_results_$UNIX_TIMESTAMP.csv"

# Führe den Benchmark-Befehl aus und speichere die Ausgabe in der neuen CSV-Datei
../scripts/benchmark.sh -m > "$CSV_FILE"

echo "CSV-Datei erstellt: $CSV_FILE"
echo "Timestamp (Unix-Zeit): $UNIX_TIMESTAMP"
