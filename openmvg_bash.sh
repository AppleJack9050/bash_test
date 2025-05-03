#!/bin/bash

# Specify the output file
output_file="openmvg_output.txt"

# Record the script start time
start_time=$(date +%s)

# Execute your script content
{
    python SfM_SequentialPipeline.py ~/home/user/data/ImageDataset_SceauxCastle/images \
                                ~/home/user/data/ImageDataset_SceauxCastle/Castle_Incremental_Reconstruction

    # Record the script end time
    end_time=$(date +%s)

    # Calculate the runtime
    run_time=$((end_time - start_time))
    echo "The script runtime is ${run_time} seconds."
} | tee "$output_file"