#!/usr/bin/env bash

# monitor.sh: Monitor CPU, RAM, GPU usage for a predefined sequence of commands and record its duration
# Usage: ./monitor.sh [-i interval_in_seconds] [-o logfile]

INTERVAL=1
OUTFILE="monitor.log"

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
# You can list multiple commands separated by semicolons (e.g., "cmd1; cmd2; cmd3").
COMMAND="cmd1; cmd2; cmd3"

# Record start timestamp
START_TS=$(date +%s)

# Write CSV header
echo "timestamp,cpu_percent,mem_percent,gpu_util_percent,gpu_mem_used_mb" > "$OUTFILE"

# Launch the sequence of commands in a single subshell, in background
bash -c "$COMMAND" &
PID=$!

# Monitoring loop
while kill -0 "$PID" 2>/dev/null; do
  TIMESTAMP=$(date +%s.%N)
  CPU=$(ps -p "$PID" -o %cpu= | awk '{print $1}')
  MEM=$(ps -p "$PID" -o %mem= | awk '{print $1}')

  # GPU stats via nvidia-smi if available
  if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1)
    GPU_MEM=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -n1)
  else
    GPU_UTIL="N/A"
    GPU_MEM="N/A"
  fi

  echo "$TIMESTAMP,$CPU,$MEM,$GPU_UTIL,$GPU_MEM" >> "$OUTFILE"
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
echo "Total duration: ${DURATION}s (${HMS})"
