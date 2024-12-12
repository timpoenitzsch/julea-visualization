#!/usr/bin/env bash
set -euo pipefail

GRAFANA_HOST="http://localhost:3000"
API_TOKEN="${GRAFANA_API_TOKEN:-}"

if [ -z "$API_TOKEN" ]; then
    echo "Fehler: Bitte setzen Sie die Umgebungsvariable GRAFANA_API_TOKEN."
    exit 1
fi

echo "Hole alle Alert-Regeln von Grafana..."
ALL_RULES_JSON=$(curl -s -X GET "$GRAFANA_HOST/api/v1/provisioning/alert-rules" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json")

UIDS_TO_DELETE=$(echo "$ALL_RULES_JSON" | jq -r '.[] | select(.title | test("_elapsed$") or test("_total_elapsed$")) | .uid')

if [ -z "$UIDS_TO_DELETE" ]; then
    echo "Keine passenden Alert-Regeln zum Löschen gefunden."
    exit 0
fi

echo "Folgende Alert-Regeln werden gelöscht:"
echo "$UIDS_TO_DELETE"

# Lösche jede gefundene Regel
for uid in $UIDS_TO_DELETE; do
    echo "Lösche Alert-Regel mit UID: $uid"
    curl -s -X DELETE "$GRAFANA_HOST/api/v1/provisioning/alert-rules/$uid" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json"
    echo "  -> Gelöscht"
done

echo "Alle ausgewählten Alert-Regeln wurden gelöscht."
