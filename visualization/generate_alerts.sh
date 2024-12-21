#!/usr/bin/env bash
set -euo pipefail

CSV_FILE="../alerting/values.csv"
OUTPUT_DIR="../alert_rules"
FOLDER_UID="${1:-ee3mqdhx91on4a}" # Parameter

# check if csv can be read
if [ ! -r "$CSV_FILE" ]; then
  echo "CSV-Datei $CSV_FILE nicht gefunden oder nicht lesbar."
  exit 1
fi

# create output directory
mkdir -p "$OUTPUT_DIR"

TEMPLATE=$(cat <<'EOF'
{
  "title": "$Name",
  "ruleGroup": "API",
  "folderUID": "$FolderUID",
  "noDataState": "NoData",
  "execErrState": "Error",
  "for": "5m",
  "orgId": 1,
  "uid": "",
  "condition": "C",
  "labels": {},
  "data": [
    {
      "refId": "C",
      "relativeTimeRange": {
        "from": 0,
        "to": 0
      },
      "datasourceUid": "__expr__",
      "model": {
        "conditions": [
          {
            "evaluator": {
              "params": [
                0,
                0
              ],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": []
            },
            "reducer": {
              "params": [],
              "type": "avg"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "name": "Expression",
          "type": "__expr__",
          "uid": "__expr__"
        },
        "expression": "$value < $lower_threshold || $value > $upper_threshold",
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "refId": "C",
        "type": "math"
      }
    }
  ]
}
EOF
)

echo "Zeilen in $CSV_FILE:"
wc -l "$CSV_FILE"

echo "Erste Zeilen von $CSV_FILE:"
head "$CSV_FILE"

echo "Starte Verarbeitung..."

tail -n +2 "$CSV_FILE" | while IFS=',' read -r name min_elapsed max_elapsed mean_elapsed median_elapsed modified_z_score_elapsed \
    lower_threshold_elapsed upper_threshold_elapsed \
    min_total_elapsed max_total_elapsed mean_total_elapsed median_total_elapsed \
    modified_z_score_total_elapsed lower_threshold_total_elapsed upper_threshold_total_elapsed \
    file_count latest_elapsed latest_total_elapsed latest_timestamp; do
    
    # Debug-output
    echo "Verarbeite Eintrag für: $name"

    # remove slashes as they lead to errors
    CLEAN_NAME=$(echo "$name" | tr '/' '_')

    # elapsed
    NAME_ELAPSED="${CLEAN_NAME}_elapsed"
    JSON_ELAPSED=$(echo "$TEMPLATE" | sed "s|\$Name|$NAME_ELAPSED|g; s|\$value|$latest_elapsed|g; s|\$lower_threshold|$lower_threshold_elapsed|g; s|\$upper_threshold|$upper_threshold_elapsed|g; s|\$FolderUID|$FOLDER_UID|g")
    echo "$JSON_ELAPSED" > "$OUTPUT_DIR/${NAME_ELAPSED}.json"
    echo "Erstellt: $OUTPUT_DIR/${NAME_ELAPSED}.json"

    # total_elapsed
    NAME_TOTAL_ELAPSED="${CLEAN_NAME}_total_elapsed"
    JSON_TOTAL_ELAPSED=$(echo "$TEMPLATE" | sed "s|\$Name|$NAME_TOTAL_ELAPSED|g; s|\$value|$latest_total_elapsed|g; s|\$lower_threshold|$lower_threshold_total_elapsed|g; s|\$upper_threshold|$upper_threshold_total_elapsed|g; s|\$FolderUID|$FOLDER_UID|g")
    echo "$JSON_TOTAL_ELAPSED" > "$OUTPUT_DIR/${NAME_TOTAL_ELAPSED}.json"
    echo "Erstellt: $OUTPUT_DIR/${NAME_TOTAL_ELAPSED}.json"

done

echo "Alle Alert-Regeln erstellt!"
