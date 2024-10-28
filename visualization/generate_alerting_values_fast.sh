#!/bin/bash

# Setze die Basisordner
BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"
ALERTING_DIR="$BASE_DIR/alerting"
VALUES_FILE="$ALERTING_DIR/values.csv"

# Erstelle das Verzeichnis für die Werte-CSV-Datei, falls es noch nicht existiert
mkdir -p "$ALERTING_DIR"

# Initialisiere die Werte-CSV-Datei mit dem Kopf
echo "name,min_elapsed,max_elapsed,mean_elapsed,count_elapsed,min_total_elapsed,max_total_elapsed,mean_total_elapsed,count_total_elapsed" > "$VALUES_FILE"

# Verarbeite die erstellten Benchmark-Dateien
for file in "$CSV_DIR"/benchmark_results_*.csv; do
    # Überspringe die Kopfzeile und verarbeite die Datei
    tail -n +2 "$file" | while IFS=$'\t' read -r name elapsed operations bytes total_elapsed; do
        # Prüfe, ob der Name schon existiert und berechne min, max, mean für elapsed und total_elapsed
        if grep -q "^$name," "$VALUES_FILE"; then
            # Extrahiere bestehende Werte aus der Datei
            min_elapsed=$(awk -F',' -v n="$name" '$1 == n {print $2}' "$VALUES_FILE")
            max_elapsed=$(awk -F',' -v n="$name" '$1 == n {print $3}' "$VALUES_FILE")
            mean_elapsed=$(awk -F',' -v n="$name" '$1 == n {print $4}' "$VALUES_FILE")
            count_elapsed=$(awk -F',' -v n="$name" '$1 == n {print $5}' "$VALUES_FILE")

            min_total_elapsed=$(awk -F',' -v n="$name" '$1 == n {print $6}' "$VALUES_FILE")
            max_total_elapsed=$(awk -F',' -v n="$name" '$1 == n {print $7}' "$VALUES_FILE")
            mean_total_elapsed=$(awk -F',' -v n="$name" '$1 == n {print $8}' "$VALUES_FILE")
            count_total_elapsed=$(awk -F',' -v n="$name" '$1 == n {print $9}' "$VALUES_FILE")

            # Berechne min, max und aktualisierten Mittelwert für elapsed
            min_elapsed=$(echo "$min_elapsed $elapsed" | awk '{if ($2 < $1) print $2; else print $1}')
            max_elapsed=$(echo "$max_elapsed $elapsed" | awk '{if ($2 > $1) print $2; else print $1}')
            sum_elapsed=$(echo "$mean_elapsed * $count_elapsed + $elapsed" | bc -l)
            count_elapsed=$((count_elapsed + 1))
            mean_elapsed=$(echo "$sum_elapsed / $count_elapsed" | bc -l)

            # Berechne min, max und aktualisierten Mittelwert für total_elapsed
            min_total_elapsed=$(echo "$min_total_elapsed $total_elapsed" | awk '{if ($2 < $1) print $2; else print $1}')
            max_total_elapsed=$(echo "$max_total_elapsed $total_elapsed" | awk '{if ($2 > $1) print $2; else print $1}')
            sum_total_elapsed=$(echo "$mean_total_elapsed * $count_total_elapsed + $total_elapsed" | bc -l)
            count_total_elapsed=$((count_total_elapsed + 1))
            mean_total_elapsed=$(echo "$sum_total_elapsed / $count_total_elapsed" | bc -l)

            # Escape Schrägstriche und andere Sonderzeichen in $name für sed
            escaped_name=$(printf '%s\n' "$name" | sed 's/[\/&]/\\&/g')

            # Aktualisiere die Datei mit den neuen Werten
            sed -i "s|^$escaped_name,.*|$name,$min_elapsed,$max_elapsed,$mean_elapsed,$count_elapsed,$min_total_elapsed,$max_total_elapsed,$mean_total_elapsed,$count_total_elapsed|" "$VALUES_FILE"
        else
            # Füge neuen Eintrag für den Namen hinzu, inklusive Zähler
            echo "$name,$elapsed,$elapsed,$elapsed,1,$total_elapsed,$total_elapsed,$total_elapsed,1" >> "$VALUES_FILE"
        fi
    done
done

echo "Zusammenfassung in $VALUES_FILE gespeichert."
