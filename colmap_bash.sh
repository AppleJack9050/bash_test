#!/bin/bash

# Specify the output file
output_file="colmap_output.txt"

# Record the script start time
start_time=$(date +%s)

# Execute your script content
{
    # Record the script start time
    start_time=$(date +%s)
    DATASET_PATH=/path/to/dataset

    colmap feature_extractor \
    --database_path  DATASET_PATH/database.db \
    --image_path  DATASET_PATH/images

    colmap exhaustive_matcher \
    --database_path  DATASET_PATH/database.db

    mkdir DATASET_PATH/sparse

    colmap mapper \
    --database_path  DATASET_PATH/database.db \
    --image_path  DATASET_PATH/images \
    --output_path  DATASET_PATH/sparse

    # Record the script end time
    end_time=$(date +%s)

    # Calculate the runtime
    run_time=$((end_time - start_time))
    echo "The script runtime is ${run_time} seconds."
} | tee "$output_file"