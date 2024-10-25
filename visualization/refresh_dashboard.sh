#!/bin/bash

# Setze den Basisordner
BASE_DIR="../"

echo "Starting HTTP server on port 8080 to serve CSV data..."
cd "$BASE_DIR"
python3 -m http.server 8080

echo "curl data"
curl -X POST -H "Authorization: Bearer $GRAFANA_API_TOKEN" -H "Content-Type: application/json" -d @benchmark_dashboard.json http://localhost:3000/api/dashboards/db
