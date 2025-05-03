#!/bin/bash

# Specify the output file
output_file="vggsfm_output.txt"

# Record the script start time
start_time=$(date +%s)

# Execute your script content
{
    python demo.py SCENE_DIR=/YOUR_FOLDER camera_type=SIMPLE_RADIAL gr_visualize=True make_reproj_video=True

    # Record the script end time
    end_time=$(date +%s)

    # Calculate the runtime
    run_time=$((end_time - start_time))
    echo "The script runtime is ${run_time} seconds."
} | tee "$output_file"