#!/bin/bash
# BigQuery Table Setup Script for NewsExpress
# Run this after setting up GCP project

set -e

# Configuration - UPDATE THESE VALUES
PROJECT_ID="${GCP_PROJECT_ID:-your-project-id}"
DATASET_ID="${BQ_DATASET_ID:-news_stream}"
LOCATION="${BQ_LOCATION:-US}"

SCHEMA_DIR="$(dirname "$0")/schemas"

echo "=========================================="
echo "NewsExpress BigQuery Setup"
echo "=========================================="
echo "Project: $PROJECT_ID"
echo "Dataset: $DATASET_ID"
echo "Location: $LOCATION"
echo "=========================================="

# Create dataset if not exists
echo "Creating dataset $DATASET_ID..."
bq --project_id=$PROJECT_ID mk --dataset \
    --location=$LOCATION \
    --description="NewsExpress streaming data" \
    $PROJECT_ID:$DATASET_ID 2>/dev/null || echo "Dataset already exists"

# Create tables
TABLES=(
    "news_table"
    "news_table_staging"
    "similarity_table"
    "dp_counts_table"
    "sample_table"
    "news_with_sentiment"
)

for table in "${TABLES[@]}"; do
    echo "Creating table $table..."
    bq --project_id=$PROJECT_ID mk --table \
        --description="NewsExpress $table" \
        $PROJECT_ID:$DATASET_ID.$table \
        $SCHEMA_DIR/${table}.json 2>/dev/null || echo "Table $table already exists"
done

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Tables created:"
for table in "${TABLES[@]}"; do
    echo "  - $PROJECT_ID:$DATASET_ID.$table"
done
