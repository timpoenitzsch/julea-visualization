#!/bin/bash

# Pfad zur Werte-CSV-Datei
VALUES_FILE="../alerting/values.csv"

# Verzeichnis für die generierten Alert-Regeln erstellen
ALERT_RULES_DIR="../alert_rules"
mkdir -p "$ALERT_RULES_DIR"

# Überspringe die Kopfzeile und lese die CSV-Datei Zeile für Zeile
tail -n +2 "$VALUES_FILE" | while IFS=',' read -r name min_elapsed max_elapsed mean_elapsed median_elapsed modified_z_score_elapsed lower_threshold_elapsed upper_threshold_elapsed min_total_elapsed max_total_elapsed mean_total_elapsed median_total_elapsed modified_z_score_total_elapsed lower_threshold_total_elapsed upper_threshold_total_elapsed file_count; do

    # Entferne Anführungszeichen und Leerzeichen aus dem Namen
    sanitized_name=$(echo "$name" | tr -d '"' | sed 's/[^A-Za-z0-9._-]/_/g')

    # Erstelle den Dateinamen für die Alert-Regel
    alert_rule_file="$ALERT_RULES_DIR/alert_rule_${sanitized_name}.json"

    # Erstelle die Alert-Regel als JSON
    cat > "$alert_rule_file" <<EOF
{
  "alertRule": {
    "name": "Alert for $name",
    "condition": "C",
    "noDataState": "NoData",
    "execErrState": "Error",
    "for": "5m",
    "annotations": {
      "summary": "Alert for $name",
      "description": "The elapsed time for $name is outside the thresholds."
    },
    "labels": {
      "severity": "critical",
      "name": "$name"
    },
    "datasourceUid": "your_datasource_uid",
    "grafanaAlert": {
      "title": "Alert for $name",
      "condition": "C",
      "data": [
        {
          "refId": "A",
          "queryType": "Infinity",
          "type": "timeSeriesQuery",
          "relativeTimeRange": {
            "from": 600,
            "to": 0
          },
          "model": {
            "type": "infinity",
            "source": "inline",
            "format": "timeseries",
            "data": "",
            "columns": [],
            "filters": [
              {
                "field": "name",
                "operator": "equals",
                "value": "$name"
              }
            ]
          }
        },
        {
          "refId": "B",
          "queryType": "Infinity",
          "type": "tableQuery",
          "model": {
            "type": "infinity",
            "source": "inline",
            "format": "table",
            "data": "",
            "columns": [],
            "filters": [
              {
                "field": "name",
                "operator": "equals",
                "value": "$name"
              }
            ]
          }
        }
      ],
      "conditions": [
        {
          "ref": "C",
          "type": "classic",
          "evaluator": {
            "type": "gt",
            "params": [0]
          },
          "operator": {
            "type": "and"
          },
          "reducer": {
            "type": "last",
            "params": []
          },
          "query": {
            "refId": "difference"
          }
        }
      ]
    }
  }
}
EOF

    echo "Alert rule for $name has been created at $alert_rule_file"

done
