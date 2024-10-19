#!/bin/bash

# Setze den Basisordner
BASE_DIR="/home/tim/BA-Projekt/julea-visualization"

# Erstelle den Ordner für die CSV-Dateien, falls er nicht existiert
mkdir -p "$BASE_DIR/benchmark_csv"

# Erzeuge den Namen der neuen CSV-Datei mit dem aktuellen Timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CSV_FILE="$BASE_DIR/benchmark_csv/benchmark_results_$TIMESTAMP.csv"
PROMETHEUS_FILE="$BASE_DIR/benchmark_metrics.txt"

# Führe den Benchmark-Befehl aus und speichere die Ausgabe in der CSV-Datei
./scripts/benchmark.sh -m > "$CSV_FILE"

# Erstelle eine Prometheus-kompatible Datei
echo "" > "$PROMETHEUS_FILE"  # Leere die Datei, falls sie existiert

# Gehe durch alle CSV-Dateien im Ordner benchmark_csv und lese die Daten
for FILE in "$BASE_DIR"/benchmark_csv/benchmark_results_*.csv; do
  # Extrahiere den Timestamp aus dem Dateinamen (z.B. 20241010_142230)
  FILE_TIMESTAMP=$(basename "$FILE" | cut -d'_' -f3 | sed 's/.csv//')

  # Konvertiere den extrahierten Timestamp in UNIX-Zeit
  UNIX_TIMESTAMP=$(date -d "$FILE_TIMESTAMP" +%s)

  # Lese jede CSV-Datei und konvertiere die Werte in Prometheus-kompatible Metriken
  while IFS=$'\t' read -r name elapsed operations bytes total_elapsed; do
    # Überspringe die Kopfzeile
    if [[ "$name" == "name" ]]; then
      continue
    fi

    # Schreibe die Prometheus-Metriken in die Datei mit dem Dateitimestamp
    echo "# HELP benchmark_elapsed Zeit, die für den Benchmark-Vorgang benötigt wurde (ohne den Benchmark-overhead)" >> "$PROMETHEUS_FILE"
    echo "# TYPE benchmark_elapsed gauge" >> "$PROMETHEUS_FILE"
    echo "benchmark_elapsed{name=\"$name\"} $elapsed $UNIX_TIMESTAMP" >> "$PROMETHEUS_FILE"

    echo "# HELP benchmark_operations Anzahl der durchgeführten Operationen im Benchmark pro Sekunde" >> "$PROMETHEUS_FILE"
    echo "# TYPE benchmark_operations gauge" >> "$PROMETHEUS_FILE"
    echo "benchmark_operations{name=\"$name\"} $operations $UNIX_TIMESTAMP" >> "$PROMETHEUS_FILE"

    echo "# HELP benchmark_total_elapsed Gesamtzeit, die für den Benchmark benötigt wurde" >> "$PROMETHEUS_FILE"
    echo "# TYPE benchmark_total_elapsed gauge" >> "$PROMETHEUS_FILE"
    echo "benchmark_total_elapsed{name=\"$name\"} $total_elapsed $UNIX_TIMESTAMP" >> "$PROMETHEUS_FILE"

  done < "$FILE"
done

# Starte einen einfachen HTTP-Server auf Port 8080, um die Metriken bereitzustellen
echo "Starting HTTP server on port 8080 to serve Prometheus metrics..."
cd "$BASE_DIR"
python3 -m http.server 8080
