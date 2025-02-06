#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="../alert_rules"

if [ -z "${GRAFANA_API_TOKEN:-}" ]; then
    echo "GRAFANA_API_TOKEN wurde nicht gesetzt."
    exit 1
fi

for json_file in "$OUTPUT_DIR"/*.json; do
    echo "import alert-rule: $json_file"
    curl -X POST "http://localhost:3000/api/v1/provisioning/alert-rules" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $GRAFANA_API_TOKEN" \
        -d @"$json_file"
    echo
done
