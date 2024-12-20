#!/bin/bash

# set home directory
BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"
ALERTING_DIR="$BASE_DIR/alerting"
VALUES_FILE="$ALERTING_DIR/values.csv"

# create directory for file
mkdir -p "$ALERTING_DIR"

# initialise csv-header
echo "name,min_elapsed,max_elapsed,mean_elapsed,median_elapsed,modified_z_score_elapsed,lower_threshold_elapsed,upper_threshold_elapsed,min_total_elapsed,max_total_elapsed,mean_total_elapsed,median_total_elapsed,modified_z_score_total_elapsed,lower_threshold_total_elapsed,upper_threshold_total_elapsed,file_count,latest_elapsed,latest_total_elapsed,latest_timestamp" > "$VALUES_FILE"

# temporary directory for calculations
TEMP_DIR=$(mktemp -d)

# Number of used files (optional)
NUM_FILES=${1:-0}

if [ "$NUM_FILES" -gt 0 ]; then
    mapfile -t files < <(ls -1 -t "$CSV_DIR"/benchmark_results_*.csv | head -n "$NUM_FILES")
else
    mapfile -t files < <(ls -1 "$CSV_DIR"/benchmark_results_*.csv)
fi

sanitize_filename() {
    local filename="$1"
    echo "$filename" | sed 's/[^A-Za-z0-9._-]/_/g'
}

declare -A latest_timestamp
declare -A latest_elapsed
declare -A latest_total_elapsed

#mapping file for names (path)
: > "$TEMP_DIR/name_mapping.tmp"

# Dateien verarbeiten
for file in "${files[@]}"; do
    # get timestampf from filename
    filename=$(basename "$file")
    current_timestamp=$(echo "$filename" | sed 's/^benchmark_results_//' | sed 's/\.csv$//')

    # check if timestamp is numeric
    if ! [[ "$current_timestamp" =~ ^[0-9]+$ ]]; then
        # avoid issues for non-numeric data
        echo "Warnung: $filename hat keinen numerischen Timestamp."
        continue
    fi

    while IFS=$'\t' read -r name elapsed operations bytes total_elapsed; do
        sanitized_name=$(sanitize_filename "$name")

        echo "$sanitized_name|$name" >> "$TEMP_DIR/name_mapping.tmp"

        elapsed_file="$TEMP_DIR/elapsed_$sanitized_name.tmp"
        total_elapsed_file="$TEMP_DIR/total_elapsed_$sanitized_name.tmp"

        echo "$elapsed" >> "$elapsed_file"
        echo "$total_elapsed" >> "$total_elapsed_file"

        # refresh values
        if [ -z "${latest_timestamp[$sanitized_name]}" ] || [ "$current_timestamp" -gt "${latest_timestamp[$sanitized_name]}" ]; then
            latest_timestamp[$sanitized_name]="$current_timestamp"
            latest_elapsed[$sanitized_name]="$elapsed"
            latest_total_elapsed[$sanitized_name]="$total_elapsed"
        fi

    done < <(tail -n +2 "$file")
done

# remove redundant entries
sort -u "$TEMP_DIR/name_mapping.tmp" -o "$TEMP_DIR/name_mapping.tmp"

declare -A name_mapping
while IFS='|' read -r sanitized_name original_name; do
    name_mapping["$sanitized_name"]="$original_name"
done < "$TEMP_DIR/name_mapping.tmp"

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

        latest_value = data[n]
        if (mad != 0) {
            modified_z_score = 0.6745 * (latest_value - median) / mad
        } else {
            modified_z_score = 0
        }

        printf "%f %f %f\n", modified_z_score, lower, upper
    }'
}

# Computations for each Path
for elapsed_file in "$TEMP_DIR"/elapsed_*.tmp; do
    sanitized_name=$(basename "$elapsed_file" | sed 's/^elapsed_//' | sed 's/\.tmp$//')
    total_elapsed_file="$TEMP_DIR/total_elapsed_$sanitized_name.tmp"

    name="${name_mapping[$sanitized_name]}"

    mapfile -t elapsed_values < "$elapsed_file"
    mapfile -t total_elapsed_values < "$total_elapsed_file"

    file_count=${#elapsed_values[@]}

    if [ "$file_count" -eq 0 ]; then
        continue
    fi

    # elapsed
    read min_elapsed max_elapsed mean_elapsed median_elapsed <<<$(calculate_stats "${elapsed_values[@]}")

    # total_elapsed
    read min_total_elapsed max_total_elapsed mean_total_elapsed median_total_elapsed <<<$(calculate_stats "${total_elapsed_values[@]}")

    # Thresholds and Z-Scores for elapsed
    read modified_z_score_elapsed lower_threshold_elapsed upper_threshold_elapsed <<<$(calculate_thresholds_and_zscore "$median_elapsed" "${elapsed_values[@]}")

    # Thresholds and Z-Scores for total_elapsed
    read modified_z_score_total_elapsed lower_threshold_total_elapsed upper_threshold_total_elapsed <<<$(calculate_thresholds_and_zscore "$median_total_elapsed" "${total_elapsed_values[@]}")

    latest_val_elapsed=${latest_elapsed[$sanitized_name]}
    latest_val_total_elapsed=${latest_total_elapsed[$sanitized_name]}
    latest_val_timestamp=${latest_timestamp[$sanitized_name]}

    echo "$name,$min_elapsed,$max_elapsed,$mean_elapsed,$median_elapsed,$modified_z_score_elapsed,$lower_threshold_elapsed,$upper_threshold_elapsed,$min_total_elapsed,$max_total_elapsed,$mean_total_elapsed,$median_total_elapsed,$modified_z_score_total_elapsed,$lower_threshold_total_elapsed,$upper_threshold_total_elapsed,$file_count,$latest_val_elapsed,$latest_val_total_elapsed,$latest_val_timestamp" >> "$VALUES_FILE"
done

rm -rf "$TEMP_DIR"

echo "Zusammenfassung in $VALUES_FILE gespeichert."
