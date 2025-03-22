#!/bin/bash

# Elasticsearch endpoint
ELASTICSEARCH_HOST="https://127.0.0.1:9200"
ELASTICSEARCH_USER="elastic"
ELASTICSEARCH_PASSWORD=""

# Define the data streams and their categories
declare -A DATA_STREAMS=(
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

# Loop through each data stream and create an index template
for INDEX_PATTERN in "${!DATA_STREAMS[@]}"; do
  DATA_STREAM_TYPE=$(echo "$INDEX_PATTERN" | cut -d'.' -f3 | cut -d'-' -f1)
  CATEGORY="${DATA_STREAMS[$INDEX_PATTERN]}"
  TEMPLATE_NAME="backup-${CATEGORY}.${DATA_STREAM_TYPE}"
  
  echo "Creating index template: $TEMPLATE_NAME for pattern: $INDEX_PATTERN"
  
  curl -k -X PUT "$ELASTICSEARCH_HOST/_index_template/$TEMPLATE_NAME" \
    -u "$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD" \
    -H "Content-Type: application/json" \
    -d "{
      \"index_patterns\": [\"$INDEX_PATTERN\"],
      \"template\": {
        \"settings\": {
          \"index.lifecycle.name\": \"logs@lifecycle\",
          \"index.number_of_shards\": 1,
          \"index.number_of_replicas\": 0
        }
      }
    }"
  
  echo -e "\nDone creating template: $TEMPLATE_NAME\n"
done
