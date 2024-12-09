#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="../alert_rules"

# Überprüfen, ob die Umgebungsvariable GRAFANA_API_TOKEN gesetzt ist
if [ -z "${GRAFANA_API_TOKEN:-}" ]; then
    echo "GRAFANA_API_TOKEN ist nicht gesetzt."
    exit 1
fi

for json_file in "$OUTPUT_DIR"/*.json; do
    echo "Importiere Alert-Regel: $json_file"
    curl -X POST "http://localhost:3000/api/v1/provisioning/alert-rules" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
        -d @"$json_file"
    echo
done
