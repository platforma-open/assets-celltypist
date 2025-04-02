#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <modelFileUrls.json>"
    exit 1
fi

MODEL_URLS_FILE=$1

if [ ! -f "$MODEL_URLS_FILE" ]; then
    echo "Error: $MODEL_URLS_FILE not found"
    exit 1
fi

# Create indexed_model directory
mkdir -p indexed_model

# Download and process model files
jq -r 'to_entries[] | "\(.key) \(.value.model_url)"' "$MODEL_URLS_FILE" | while read -r model_name model_url; do
    echo "Processing $model_name from $model_url"
    mkdir -p "indexed_model/$model_name"
    wget -nv -c "$model_url" -O "indexed_model/$model_name/$model_name.pkl"
done
