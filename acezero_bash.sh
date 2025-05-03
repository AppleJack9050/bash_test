#!/bin/bash

# Specify the output file
output_file="ace0_output.txt"

# Record the script start time
start_time=$(date +%s)

# Execute your script content
{
    
    # running ACE0 with an initial guess for the focal length
    python ace_zero.py "/path/to/some/images/*.jpg" result_folder --use_external_focal_length <focal_length>

    # running ACE mapping with pose refinement enabled
    python train_ace.py "/path/to/some/images/*.jpg" result_folder/ace_network.pt --pose_files "/path/to/some/images/*.txt" --pose_refinement mlp --pose_refinement_wait 5000 --use_external_focal_length <focal_length> --refine_calibration False

    # re-estimate poses of all images
    python register_mapping.py "/path/to/some/images/*.jpg" result_folder/ace_network.pt --use_external_focal_length <focal_length> --session ace_network

    # Record the script end time
    end_time=$(date +%s)

    # Calculate the runtime
    run_time=$((end_time - start_time))
    echo "The script runtime is ${run_time} seconds."
} | tee "$output_file"