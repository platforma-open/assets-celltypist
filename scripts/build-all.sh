#!/bin/bash
set -e

# Function to build a model
build_model() {
    local model_dir="$1"
    echo "Building model in $model_dir"
    cd "$model_dir"
    ./build-everything.sh ./modelFileUrls.json
    cd - > /dev/null
}

# Build all models in human-healthy directory
for dir in ../human-healthy/*/; do
    if [ -f "$dir/package.json" ]; then
        build_model "$dir"
    fi
done

# Build all models in human-disease directory
for dir in ../human-disease/*/; do
    if [ -f "$dir/package.json" ]; then
        build_model "$dir"
    fi
done

# Build all models in mouse-healthy directory
for dir in ../mouse-healthy/*/; do
    if [ -f "$dir/package.json" ]; then
        build_model "$dir"
    fi
done 