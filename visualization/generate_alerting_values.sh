#!/bin/bash

# Setze die Basisordner
BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"
ALERTING_DIR="$BASE_DIR/alerting"
VALUES_FILE="$ALERTING_DIR/values.csv"

# Erstelle die Ordner für CSV-Dateien, falls sie nicht existieren
mkdir -p "$CSV_DIR"
mkdir -p "$ALERTING_DIR"

# Initialisiere die Werte-CSV-Datei mit dem Kopf
echo "name,min,max,mean" > "$VALUES_FILE"

# Führe 10 Benchmarks aus
for i in {1..10}; do
    # Erzeuge den Namen der neuen CSV-Datei mit dem aktuellen Unix-Timestamp
    UNIX_TIMESTAMP=$(date +%s)
    CSV_FILE="$CSV_DIR/benchmark_results_$UNIX_TIMESTAMP.csv"
    
    # Führe den Benchmark-Befehl aus und speichere die Ausgabe in der neuen CSV-Datei
    ../scripts/benchmark.sh -m > "$CSV_FILE"
    
    echo "CSV-Datei erstellt: $CSV_FILE"
    echo "Timestamp (Unix-Zeit): $UNIX_TIMESTAMP"
    
    # Warte 10 Minuten, bevor der nächste Benchmark ausgeführt wird
    if [ "$i" -lt 10 ]; then
        sleep 600
    fi
done

# Verarbeite die erstellten Benchmark-Dateien
for file in "$CSV_DIR"/benchmark_results_*.csv; do
    # Überspringe die Kopfzeile
    tail -n +2 "$file" | while IFS=$',' read -r name elapsed operations bytes total_elapsed; do
        # Berechne Min, Max und Mittelwert für jeden Namen
        if grep -q "$name" "$VALUES_FILE"; then
            # Aktualisiere vorhandene Werte
            min=$(awk -v n="$name" '$1 == n {print $2}' "$VALUES_FILE")
            max=$(awk -v n="$name" '$1 == n {print $3}' "$VALUES_FILE")
            mean=$(awk -v n="$name" '$1 == n {print $4}' "$VALUES_FILE")
            
            # Aktualisiere mit neuen Werten
            min=$(echo "$min $elapsed" | awk '{if ($2 < $1) print $2; else print $1}')
            max=$(echo "$max $elapsed" | awk '{if ($2 > $1) print $2; else print $1}')
            mean=$(echo "$mean $elapsed" | awk '{print ($1 + $2) / 2}')
            
            # Update Werte in der Datei
            sed -i "/^$name,/s/.*/$name,$min,$max,$mean/" "$VALUES_FILE"
        else
            # Schreibe neuen Eintrag
            echo "$name,$elapsed,$elapsed,$elapsed" >> "$VALUES_FILE"
        fi
    done
done

echo "Zusammenfassung in $VALUES_FILE gespeichert."
