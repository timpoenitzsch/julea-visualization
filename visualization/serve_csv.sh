#!/bin/bash

# Set home directory
BASE_DIR="../"

echo "Starting HTTP server on port 8080 to serve CSV data..."
cd "$BASE_DIR"
python3 -m http.server 8080 
