#!/bin/bash

# Elasticsearch host
ELASTICSEARCH_URL="https://127.0.0.1:9200"
API_KEY=""

# Output directory
OUTPUT_DIR="/home/elkuser/elastic-dump_backup"
mkdir -p "$OUTPUT_DIR"

# Index patterns and their corresponding integration folders
declare -A INTEGRATIONS=(
  [".ds-logs-windows.powershell-default-*"]="windows"
  [".ds-logs-windows.powershell_operational-default-*"]="windows"
  [".ds-logs-windows.windows_defender-default-*"]="windows"
  [".ds-logs-panw.panos-default-*"]="panw"
  [".ds-logs-fortinet_fortigate.log-default-*"]="fortinet"
  [".ds-logs-crowdstrike.alert-default-*"]="crowdstrike"
  [".ds-logs-o365.audit-default-*"]="o365"
  [".ds-logs-system.system-default-*"]="system"
  [".ds-logs-system.auth-default-*"]="system"
  [".ds-logs-system.syslog-default-*"]="system"
  [".ds-logs-system.application-default-*"]="system"
  [".ds-logs-system.security-default-*"]="system"
)

# Set the max size for each gzip file (3G)
MAX_SIZE="3G"

for INDEX in "${!INTEGRATIONS[@]}"; do
  FOLDER_NAME="${INTEGRATIONS[$INDEX]}"
  # Extract the data stream type from the index pattern
  # Example: .ds-logs-system.auth-default-* -> auth
  DATA_STREAM_TYPE=$(echo "$INDEX" | cut -d'.' -f3 | cut -d'-' -f1)
  
  YEAR=$(date +%Y)
  MONTH=$(date +%b)
  DEST_DIR="$OUTPUT_DIR/$YEAR/$MONTH/$FOLDER_NAME/$DATA_STREAM_TYPE/"
  mkdir -p "$DEST_DIR"

  echo "Exporting index: $INDEX to $DEST_DIR"

  NODE_TLS_REJECT_UNAUTHORIZED=0 elasticdump \
    --input="$ELASTICSEARCH_URL/$INDEX" \
    --output="$" \
    --headers="{\"Authorization\":\"ApiKey ${API_KEY}\"}" \
    --limit=1000 | \
    gzip | \
    split -b "$MAX_SIZE" - "$DEST_DIR/${INDEX#.ds-logs-}.json.gz.part_"

done
