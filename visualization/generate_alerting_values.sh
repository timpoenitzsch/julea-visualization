#!/bin/bash

# Basisordner setzen
BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"
ALERTING_DIR="$BASE_DIR/alerting"
VALUES_FILE="$ALERTING_DIR/values.csv"

# Verzeichnis für die Werte-CSV-Datei erstellen, falls es nicht existiert
mkdir -p "$ALERTING_DIR"

# Werte-CSV-Datei mit dem Kopf initialisieren
echo "name,min_elapsed,max_elapsed,mean_elapsed,median_elapsed,modified_z_score_elapsed,lower_threshold_elapsed,upper_threshold_elapsed,min_total_elapsed,max_total_elapsed,mean_total_elapsed,median_total_elapsed,modified_z_score_total_elapsed,lower_threshold_total_elapsed,upper_threshold_total_elapsed,file_count" > "$VALUES_FILE"

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

    # Funktionen zur Berechnung von Statistikwerten mit awk
    calculate_stats() {
        local values=("$@")
        printf '%s\n' "${values[@]}" | awk '
        {
            count[NR] = $1
            sum += $1
        }
        END {
            n = NR
            asort(count)
            min = count[1]
            max = count[n]
            mean = sum / n
            if (n % 2) {
                median = count[(n + 1) / 2]
            } else {
                median = (count[n/2] + count[n/2 + 1]) / 2
            }
            printf "%f %f %f %f\n", min, max, mean, median
        }'
    }

    # Berechnung der Statistik für elapsed
    read min_elapsed max_elapsed mean_elapsed median_elapsed <<<$(calculate_stats "${elapsed_values[@]}")

    # Berechnung der Statistik für total_elapsed
    read min_total_elapsed max_total_elapsed mean_total_elapsed median_total_elapsed <<<$(calculate_stats "${total_elapsed_values[@]}")

    # Funktion zur Berechnung der Schwellenwerte und modifizierten Z-Scores mit awk
    calculate_thresholds_and_zscore() {
        local median="$1"
        shift
        local values=("$@")
        printf '%s\n' "${values[@]}" | awk -v median="$median" '
        {
            data[NR] = $1
            deviation = ($1 > median) ? $1 - median : median - $1
            deviations[NR] = deviation
        }
        END {
            n = NR
            asort(deviations)
            if (n % 2) {
                mad = deviations[(n + 1) / 2]
            } else {
                mad = (deviations[n/2] + deviations[n/2 + 1]) / 2
            }
            threshold = (3.5 * mad) / 0.6745
            upper = median + threshold
            lower = median - threshold

            # Berechnung des modifizierten Z-Scores für den neuesten Wert
            latest_value = data[n]
            if (mad != 0) {
                modified_z_score = 0.6745 * (latest_value - median) / mad
            } else {
                modified_z_score = 0
            }

            printf "%f %f %f\n", modified_z_score, lower, upper
        }'
    }

    # Berechnung der Schwellenwerte und des modifizierten Z-Scores für elapsed
    read modified_z_score_elapsed lower_threshold_elapsed upper_threshold_elapsed <<<$(calculate_thresholds_and_zscore "$median_elapsed" "${elapsed_values[@]}")

    # Berechnung der Schwellenwerte und des modifizierten Z-Scores für total_elapsed
    read modified_z_score_total_elapsed lower_threshold_total_elapsed upper_threshold_total_elapsed <<<$(calculate_thresholds_and_zscore "$median_total_elapsed" "${total_elapsed_values[@]}")

    # Ergebnisse in die Werte-CSV-Datei schreiben
    echo "$name,$min_elapsed,$max_elapsed,$mean_elapsed,$median_elapsed,$modified_z_score_elapsed,$lower_threshold_elapsed,$upper_threshold_elapsed,$min_total_elapsed,$max_total_elapsed,$mean_total_elapsed,$median_total_elapsed,$modified_z_score_total_elapsed,$lower_threshold_total_elapsed,$upper_threshold_total_elapsed,$file_count" >> "$VALUES_FILE"
done

# Temporäres Verzeichnis löschen
rm -rf "$TEMP_DIR"

echo "Zusammenfassung in $VALUES_FILE gespeichert."
