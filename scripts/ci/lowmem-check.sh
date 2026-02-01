#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/env-file (e.g. .env.lowmem.example or .env)"
  exit 2
fi
ENVFILE="$1"

if [ ! -f "$ENVFILE" ]; then
  echo "Env file not found: $ENVFILE"
  exit 2
fi

# shellcheck disable=SC1090
source "$ENVFILE"

mem_total_mb=0
for var in PROMETHEUS_MEM GRAFANA_MEM ALERTMANAGER_MEM CADVISOR_MEM NODE_EXPORTER_MEM NGINX_MEM; do
  val="${!var:-0}"
  if [[ $val =~ ^([0-9]+)M$ ]]; then
    mem_mb=${BASH_REMATCH[1]}
  elif [[ $val =~ ^([0-9]+)G$ ]]; then
    mem_mb=$((BASH_REMATCH[1]*1024))
  else
    mem_mb=0
  fi
  mem_total_mb=$((mem_total_mb + mem_mb))
done

echo "Estimated total service memory from $ENVFILE: ${mem_total_mb}MB"

if [ $mem_total_mb -gt 500 ]; then
  echo "ERROR: Total configured memory (${mem_total_mb}MB) exceeds allowed 500MB for low-memory profile"
  exit 1
fi

# Ensure docker-compose doesn't use :latest
if grep -n ":latest" docker-compose.yml >/dev/null 2>&1; then
  echo "ERROR: docker-compose.yml contains ':latest' image tags. Please pin image versions."
  exit 1
fi

echo "Low-memory check passed"
