#!/bin/bash

# Elasticsearch host
ELASTICSEARCH_URL="https://127.0.0.1:9200"
API_KEY=""

# Input directory where backups are stored
BACKUP_PATH="/home/elkuser/elastic-dump_backup"

# Get current date for new index suffix
DATE_SUFFIX=$(date +%Y.%m.%d)

# Process each integration and data stream type from the backed-up files
find "$BACKUP_PATH" -type d -path "*/*" | while read -r DATA_DIR; do
  # Only process directories that contain actual data files
  if ls "$DATA_DIR"/*.json.gz.part_* 1> /dev/null 2>&1; then
    # Extract integration and data_stream_type from the directory path
    # Path format: $BACKUP_PATH/$INTEGRATION/$DATA_STREAM_TYPE/
    INTEGRATION=$(basename "$(dirname "$DATA_DIR")")
    DATA_STREAM_TYPE=$(basename "$DATA_DIR")
    
    # Define the new destination index
    DEST_INDEX="backup-$INTEGRATION.$DATA_STREAM_TYPE-$DATE_SUFFIX"
    
    echo "Importing data from $DATA_DIR to index: $DEST_INDEX"
    
    # Concatenate all parts, decompress, and import to new index
    cat "$DATA_DIR"/*.json.gz.part_* | gunzip | NODE_TLS_REJECT_UNAUTHORIZED=0 elasticdump \
      --input=$ \
      --output="$ELASTICSEARCH_URL/$DEST_INDEX" \
      --headers="{\"Authorization\":\"ApiKey ${API_KEY}\"}"
    
    echo "Import complete for $DEST_INDEX"
  fi
done

echo "All imports completed"