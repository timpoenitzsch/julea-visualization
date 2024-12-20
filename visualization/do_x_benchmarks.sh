#!/bin/bash

BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"
ALERTING_DIR="$BASE_DIR/alerting"
VALUES_FILE="$ALERTING_DIR/values.csv"

# Create folder for csv-files
mkdir -p "$CSV_DIR"

NUM_ITERATIONS=${1:-1}
SLEEP_TIME=${2:-600}

# do x benchmarks
for i in $(seq 1 $NUM_ITERATIONS); do

    UNIX_TIMESTAMP=$(date +%s)
    CSV_FILE="$CSV_DIR/benchmark_results_$UNIX_TIMESTAMP.csv"
    
    ../scripts/benchmark.sh -m > "$CSV_FILE"
    
    echo "CSV-Datei erstellt: $CSV_FILE"
    echo "Timestamp (Unix-Zeit): $UNIX_TIMESTAMP"
    
    # wait until next benchmark
    if [ "$i" -lt $NUM_ITERATIONS ]; then
        sleep $SLEEP_TIME
    fi
done