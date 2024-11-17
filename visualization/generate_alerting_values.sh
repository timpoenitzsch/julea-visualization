#!/bin/bash

# Basisordner setzen
BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"
ALERTING_DIR="$BASE_DIR/alerting"
VALUES_FILE="$ALERTING_DIR/values.csv"

# Verzeichnis für die Werte-CSV-Datei erstellen, falls es nicht existiert
mkdir -p "$ALERTING_DIR"

# Werte-CSV-Datei mit dem Kopf initialisieren
echo "name,min_elapsed,max_elapsed,mean_elapsed,median_elapsed,min_total_elapsed,max_total_elapsed,mean_total_elapsed,median_total_elapsed,file_count" > "$VALUES_FILE"

# Temporäres Verzeichnis für Zwischenwerte erstellen
TEMP_DIR=$(mktemp -d)

# Anzahl der zu verarbeitenden Dateien (optional)
NUM_FILES=${1:-0}

# Liste der zu verarbeitenden Dateien erstellen
if [ "$NUM_FILES" -gt 0 ]; then
    # Die neuesten NUM_FILES Dateien auswählen
    mapfile -t files < <(ls -1 -t "$CSV_DIR"/benchmark_results_*.csv | head -n "$NUM_FILES")
else
    # Alle Dateien verarbeiten
    mapfile -t files < <(ls -1 "$CSV_DIR"/benchmark_results_*.csv)
fi

# Funktion zum Bereinigen von Dateinamen
sanitize_filename() {
    local filename="$1"
    # Ersetze alle nicht-alphanumerischen Zeichen durch Unterstriche
    echo "$filename" | sed 's/[^A-Za-z0-9._-]/_/g'
}

# Verarbeitung der ausgewählten Benchmark-Dateien
for file in "${files[@]}"; do
    # Überspringe die Kopfzeile und verarbeite die Datei
    tail -n +2 "$file" | while IFS=$'\t' read -r name elapsed operations bytes total_elapsed; do
        # Name bereinigen, um ihn als Dateinamen zu verwenden
        sanitized_name=$(sanitize_filename "$name")
        
        # Mapping von sanitized_name zu originalem name speichern
        echo "$sanitized_name|$name" >> "$TEMP_DIR/name_mapping.tmp"
        
        # Temporäre Dateien für jeden Namen erstellen
        elapsed_file="$TEMP_DIR/elapsed_$sanitized_name.tmp"
        total_elapsed_file="$TEMP_DIR/total_elapsed_$sanitized_name.tmp"
        
        # Aktuelle Werte zu den temporären Dateien hinzufügen
        echo "$elapsed" >> "$elapsed_file"
        echo "$total_elapsed" >> "$total_elapsed_file"
    done
done

# Doppelte Einträge in der Mapping-Datei entfernen
sort -u "$TEMP_DIR/name_mapping.tmp" -o "$TEMP_DIR/name_mapping.tmp"

# Assoziatives Array für das Mapping erstellen
declare -A name_mapping
while IFS='|' read -r sanitized_name original_name; do
    name_mapping["$sanitized_name"]="$original_name"
done < "$TEMP_DIR/name_mapping.tmp"

# Verarbeitung der gesammelten Daten für jeden Namen
for elapsed_file in "$TEMP_DIR"/elapsed_*.tmp; do
    # Bereinigten Namen aus dem Dateinamen extrahieren
    sanitized_name=$(basename "$elapsed_file" | sed 's/^elapsed_//' | sed 's/\.tmp$//')
    total_elapsed_file="$TEMP_DIR/total_elapsed_$sanitized_name.tmp"
    
    # Originalen Namen aus dem Mapping erhalten
    name="${name_mapping[$sanitized_name]}"
    
    # Werte in Arrays einlesen
    mapfile -t elapsed_values < "$elapsed_file"
    mapfile -t total_elapsed_values < "$total_elapsed_file"
    
    # Anzahl der Werte
    file_count=${#elapsed_values[@]}
    
    if [ "$file_count" -eq 0 ]; then
        continue
    fi
    
    # Werte sortieren
    sorted_elapsed=($(printf '%s\n' "${elapsed_values[@]}" | LC_ALL=C sort -n))
    sorted_total_elapsed=($(printf '%s\n' "${total_elapsed_values[@]}" | LC_ALL=C sort -n))
    
    # Min, Max, Mean, Median für elapsed berechnen
    min_elapsed=${sorted_elapsed[0]}
    max_index=$((file_count - 1))
    max_elapsed=${sorted_elapsed[$max_index]}
    sum_elapsed=0
    for value in "${elapsed_values[@]}"; do
        sum_elapsed=$(echo "$sum_elapsed + $value" | bc -l)
    done
    mean_elapsed=$(echo "$sum_elapsed / $file_count" | bc -l)
    median_index=$((file_count / 2))
    if (( file_count % 2 == 1 )); then
        # Ungerade Anzahl von Werten
        median_elapsed=${sorted_elapsed[$median_index]}
    else
        # Gerade Anzahl von Werten --> Mittelwert der beiden mittleren Werte
        index1=$((median_index - 1))
        index2=$median_index
        value1=${sorted_elapsed[$index1]}
        value2=${sorted_elapsed[$index2]}
        median_elapsed=$(echo "($value1 + $value2) / 2" | bc -l)
    fi
    
    #Ausgabe in der Konsole
    echo "Name: $name"
    echo "Elapsed values: ${elapsed_values[@]}"
    echo "Sorted elapsed values: ${sorted_elapsed[@]}"
    echo "File count: $file_count"
    echo "Median index: $median_index"
    echo "Median elapsed: $median_elapsed"
    echo "Mean elapsed: $mean_elapsed"
    echo "---------------------------"
    
    # Ergebnisse in die Werte-CSV-Datei schreiben
    echo "$name,$min_elapsed,$max_elapsed,$mean_elapsed,$median_elapsed,$min_total_elapsed,$max_total_elapsed,$mean_total_elapsed,$median_total_elapsed,$file_count" >> "$VALUES_FILE"
done

# Temporäres Verzeichnis löschen
rm -rf "$TEMP_DIR"

echo "Zusammenfassung in $VALUES_FILE gespeichert."
