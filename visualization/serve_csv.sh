#!/bin/bash

# Setze den Basisordner
BASE_DIR="../"

"$BASE_DIR/visualization/get_commits.sh"

echo "Starting HTTP server on port 8080 to serve CSV data..."
cd "$BASE_DIR"
python3 -m http.server 8080 # Starte Server