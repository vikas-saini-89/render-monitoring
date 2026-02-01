#!/bin/sh
# wait-for-prometheus.sh <timeout_seconds>
# Wait for Prometheus to become healthy, with a timeout (default 60s)
TIMEOUT=${1:-60}
COUNT=0
while [ $COUNT -lt "$TIMEOUT" ]; do
  if wget -q --spider http://127.0.0.1:9090/-/healthy; then
    echo "Prometheus is healthy"
    exit 0
  fi
  sleep 1
  COUNT=$((COUNT+1))
done
echo "Timed out waiting for Prometheus after ${TIMEOUT}s"
exit 1
