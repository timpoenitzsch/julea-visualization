#!/bin/bash

# Grafana-URL und API-Schlüssel
GRAFANA_URL="http://localhost:3000"
API_KEY=$GRAFANA_API_TOKEN

# Verzeichnis mit den Alert-Regel-JSON-Dateien
ALERT_RULES_DIR="../alert_rules"

# Prüfen, ob das Verzeichnis existiert
if [ ! -d "$ALERT_RULES_DIR" ]; then
    echo "Das Verzeichnis $ALERT_RULES_DIR existiert nicht."
    exit 1
fi

# Über alle JSON-Dateien im Verzeichnis iterieren
for alert_rule_file in "$ALERT_RULES_DIR"/*.json; do
    # Prüfen, ob Dateien vorhanden sind
    if [ ! -e "$alert_rule_file" ]; then
        echo "Keine Alert-Regel-JSON-Dateien im Verzeichnis $ALERT_RULES_DIR gefunden."
        exit 1
    fi

    # Alert-Regel aus der JSON-Datei lesen
    alert_rule_json=$(cat "$alert_rule_file")

    # Alert-Regel in Grafana importieren
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$GRAFANA_URL/api/v1/rules" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $API_KEY" \
        -d "$alert_rule_json")

    if [ "$response" -eq 200 ] || [ "$response" -eq 201 ]; then
        echo "Alert-Regel aus $alert_rule_file wurde erfolgreich importiert."
    else
        echo "Fehler beim Importieren der Alert-Regel aus $alert_rule_file. HTTP Status Code: $response"
    fi
done
