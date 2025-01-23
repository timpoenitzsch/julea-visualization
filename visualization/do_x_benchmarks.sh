#!/bin/bash

BASE_DIR="../"
CSV_DIR="$BASE_DIR/benchmark_csv"
LOG_DIR="$BASE_DIR/benchmark_logs"


# Create directories
mkdir -p "$CSV_DIR" "$LOG_DIR"

NUM_ITERATIONS=${1:-1}
SLEEP_TIME=${2:-600}

# do x benchmarks
for i in $(seq 1 $NUM_ITERATIONS); do

    UNIX_TIMESTAMP=$(date +%s)
    CSV_FILE="$CSV_DIR/benchmark_results_$UNIX_TIMESTAMP.csv"
    LOG_FILE="$LOG_DIR/benchmark_log_$UNIX_TIMESTAMP.log"
    
    #execute benchmark and save information in log- and CSV-file
    ../scripts/benchmark.sh -m 2> "$LOG_FILE" | \
        # if dependencies were not loaded, respective messages are not saved in CSV-File
        grep -v '^Dependency "' \
        > "$CSV_FILE"
    
    # If log is empty (no errors occured), create message
    if [ ! -s "$LOG_FILE" ]; then
        echo "Es sind keine Fehlermeldungen aufgetreten." > "$LOG_FILE"
    fi

    echo "CSV-Datei erstellt: $CSV_FILE"
    echo "log-Datei erstellt: $LOG_FILE"
    echo "Timestamp (Unix-Zeit): $UNIX_TIMESTAMP"
    
    # wait until next benchmark
    if [ "$i" -lt $NUM_ITERATIONS ]; then
        sleep $SLEEP_TIME
    fi
done