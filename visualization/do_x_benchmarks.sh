#!/bin/bash

# Setze die Basisordner
BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"
ALERTING_DIR="$BASE_DIR/alerting"
VALUES_FILE="$ALERTING_DIR/values.csv"

# Erstelle die Ordner für CSV-Dateien, falls sie nicht existieren
mkdir -p "$CSV_DIR"

NUM_ITERATIONS=${1:-10}

# Führe x Benchmarks aus
for i in $(seq 1 $NUM_ITERATIONS); do
    # Erzeuge den Namen der neuen CSV-Datei mit dem aktuellen Unix-Timestamp
    UNIX_TIMESTAMP=$(date +%s)
    CSV_FILE="$CSV_DIR/benchmark_results_$UNIX_TIMESTAMP.csv"
    
    # Führe den Benchmark-Befehl aus und speichere die Ausgabe in der neuen CSV-Datei
    ../scripts/benchmark.sh -m > "$CSV_FILE"
    
    echo "CSV-Datei erstellt: $CSV_FILE"
    echo "Timestamp (Unix-Zeit): $UNIX_TIMESTAMP"
    
    # Warte x Minuten, bevor der nächste Benchmark ausgeführt wird
    if [ "$i" -lt $NUM_ITERATIONS ]; then
        sleep 600
    fi
done