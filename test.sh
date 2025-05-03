#!/usr/bin/env bash

# monitor.sh: Monitor CPU and RAM usage for a predefined sequence of commands and record its duration
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
COMMAND="stress --cpu 4 --timeout 60"

# Record start timestamp
START_TS=$(date +%s)

# Initialize or append CSV file
if [ ! -f "$OUTFILE" ]; then
  echo "timestamp,cpu_percent,mem_percent" > "$OUTFILE"
  echo "Created new log file: $OUTFILE"
else
  echo "timestamp,cpu_percent,mem_percent" > "$OUTFILE"
  echo "Appending to existing log file: $OUTFILE"
fi

# Launch the sequence of commands in a single subshell, in background
bash -c "$COMMAND" &
PID=$!

# Monitoring loop
while kill -0 "$PID" 2>/dev/null; do
  TIMESTAMP=$(date +%s.%N)
  CPU=$(mpstat -P ALL 1 1 | awk 'NR==4 {print $3}')
  MEM=$(free | awk '/Mem:/ {print $3/$2*100 "%"}')

  echo "$TIMESTAMP,$CPU,$MEM" >> "$OUTFILE"
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
