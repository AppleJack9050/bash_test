#!/usr/bin/env bash

# monitor_gpu.sh: Monitor CPU, RAM, and GPU usage for a predefined sequence of commands and record its duration
# Usage: ./monitor_gpu.sh [-i interval_in_seconds] [-o logfile]

###############################################################################################
######## remember to add name of monitor file!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
###############################################################################################

INTERVAL=30
OUTFILE="monitor_openmvg_0.log"

show_help() {
  echo "Usage: $0 [-i interval_in_seconds] [-o logfile]"
  echo
  echo "  -i    Sampling interval in seconds (default: $INTERVAL)"
  echo "  -o    Output CSV file (default: $OUTFILE)"
  echo "  -h    Show this help message"
  exit 1
}

# Parse options
while getopts ":i:o:h" opt; do
  case $opt in
    i) INTERVAL="$OPTARG" ;; 
    o) OUTFILE="$OPTARG" ;; 
    h) show_help ;; 
    \?) echo "Invalid option: -$OPTARG" >&2; show_help ;;
    :) echo "Option -$OPTARG requires an argument." >&2; show_help ;;
  esac
done

# Define the commands to run (edit this line below):
# COMMAND="colmap feature_extractor --database_path /home/otter77/colmap_work_dir/database.db --image_path /home/otter77/Dataset/2016-11-28_Howchin-AlphLake_Imagery-Files.beh/JPG"
COMMAND="cd /home/otter77/openMVG/openMVG_Build/software/SfM;
         python SfM_SequentialPipeline.py /home/otter77/Dataset/2016-11-28_Howchin-AlphLake_Imagery-Files.beh/JPG /home/otter77/openmvg_workdir"

# Record start timestamp
START_TS=$(date +%s)

# Initialize or append CSV file
if [ ! -f "$OUTFILE" ]; then
  echo "timestamp,cpu_percent,mem_percent,gpu_util_percent,gpu_mem_used_mb" > "$OUTFILE"
  echo "Created new log file: $OUTFILE"
else
  echo "Appending to existing log file: $OUTFILE"
fi

# Launch the sequence of commands in a single subshell, in background
bash -c "$COMMAND" &
PID=$!

GPU_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)

# Monitoring loop
while kill -0 "$PID" 2>/dev/null; do
  TIMESTAMP=$(date +%s.%N)
  CPU=$(mpstat -P ALL 1 1 | awk 'NR==4 {print $3 "%"}')
  MEM=$(free | awk '/Mem:/ {print $3/$2*100 "%"}')

  # GPU stats via nvidia-smi (requires NVIDIA drivers)
  if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1)
    GPU_MEM=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -n1)
    # Calculate memory usage percentage
    # GPU_MEM_UTIL=$(awk -v used="$GPU_USED" -v total="$GPU_TOTAL" 'BEGIN {printf "%.1f", used/total*100}')
    GPU_MEM_UTIL=$(( GPU_MEM * 100 / GPU_TOTAL ))
  else
    GPU_UTIL="N/A"
    GPU_MEM="N/A"
  fi

  echo "$TIMESTAMP,$CPU,$MEM,$GPU_UTIL%,$GPU_MEM_UTIL%" >> "$OUTFILE"
  sleep "$INTERVAL"
done

# Wait for commands to finish and record exit status
wait "$PID"
EXIT_STATUS=$?
END_TS=$(date +%s)
DURATION=$((END_TS - START_TS))

# Format duration as H:M:S
HMS=$(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))

echo "Sequence exited with status: $EXIT_STATUS"
echo "Total duration: ${DURATION}s (${HMS})" >> "$OUTFILE"
