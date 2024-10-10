#!/bin/bash

# Name der CSV-Datei, die die Benchmark-Ergebnisse enthält
CSV_FILE="benchmark_results.csv"
PROMETHEUS_FILE="/home/tim/benchmark_metrics.txt"

# Überprüfen, ob die CSV-Datei existiert
if [[ ! -f "$CSV_FILE" ]]; then
  echo "Fehler: Die Datei $CSV_FILE wurde nicht gefunden."
  exit 1
fi

# Erstelle eine Prometheus-kompatible Datei
echo "" > "$PROMETHEUS_FILE"  # Leere die Datei, falls sie existiert

# Lese die CSV-Datei und konvertiere die Werte in Prometheus-kompatible Metriken
while IFS=$'\t' read -r name elapsed operations bytes total_elapsed; do
  # Überspringe die Kopfzeile
  if [[ "$name" == "name" ]]; then
    continue
  fi

  # Schreibe die Prometheus-Metriken in die Datei
  echo "# HELP benchmark_elapsed Zeit, die für den Benchmark-Vorgang benötigt wurde (ohne den Benchmark-overhead)" >> "$PROMETHEUS_FILE"
  echo "# TYPE benchmark_elapsed gauge" >> "$PROMETHEUS_FILE"
  echo "benchmark_elapsed{name=\"$name\"} $elapsed" >> "$PROMETHEUS_FILE"

  echo "# HELP benchmark_operations Anzahl der durchgeführten Operationen im Benchmark pro Sekunde" >> "$PROMETHEUS_FILE"
  echo "# TYPE benchmark_operations gauge" >> "$PROMETHEUS_FILE"
  echo "benchmark_operations{name=\"$name\"} $operations" >> "$PROMETHEUS_FILE"

  echo "# HELP benchmark_total_elapsed Gesamtzeit, die für den Benchmark benötigt wurde" >> "$PROMETHEUS_FILE"
  echo "# TYPE benchmark_total_elapsed gauge" >> "$PROMETHEUS_FILE"
  echo "benchmark_total_elapsed{name=\"$name\"} $total_elapsed" >> "$PROMETHEUS_FILE"

done < "$CSV_FILE"

cd "$(dirname "$PROMETHEUS_FILE")"

# Starte einen einfachen HTTP-Server auf Port 8080, um die Metriken bereitzustellen
echo "Starting HTTP server on port 8080 to serve Prometheus metrics..."
python3 -m http.server 8080
