#!/usr/bin/env bash
# oniux-ip-loop.sh
# Run: oniux curl -4 https://icanhazip.com every 15 seconds (keeps ~15s interval,
# accounting for command runtime). Logs timestamp + output to stdout.
# Stops cleanly on SIGINT / SIGTERM.

INTERVAL=15
CMD=('oniux' 'curl' '-4' 'https://icanhazip.com')

# Handle clean shutdown
running=true
_cleanup() {
  running=false
  echo "$(date --iso-8601=seconds)  -> shutting down"
  exit 0
}
trap _cleanup INT TERM

echo "$(date --iso-8601=seconds)  -> starting loop (interval=${INTERVAL}s)"
while $running; do
  start_ts=$(date +%s)

  # Run command and capture output + exit code
  if output="$("${CMD[@]}" 2>&1)"; then
    rc=0
  else
    rc=$?
  fi

  # Print timestamp, exit code, and trimmed output
  echo "$(date --iso-8601=seconds)  exit=${rc}  output=$(echo "$output" | tr -d '\r')"

  # Calculate elapsed and sleep remaining time to keep interval consistent
  now_ts=$(date +%s)
  elapsed=$(( now_ts - start_ts ))
  sleep_for=$(( INTERVAL - elapsed ))
  if [ "$sleep_for" -gt 0 ]; then
    sleep "$sleep_for"
  fi
done
