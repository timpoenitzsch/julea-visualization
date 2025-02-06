#!/bin/bash

# Set base directory
BASE_DIR="../"

"$BASE_DIR/visualization/get_commits.sh"

echo "Starte HTTP server auf port 8080 um CSV-Daten zur Verfügung zu stellen..."
cd "$BASE_DIR"
python3 -m http.server 8080 &  # start server in background

# wait until server is fully started
sleep 2  

echo "Sending data with curl"
curl -X POST -H "Authorization: Bearer $GRAFANA_API_TOKEN" -H "Content-Type: application/json" -d @visualization/benchmark_dashboard.json http://localhost:3000/api/dashboards/db
