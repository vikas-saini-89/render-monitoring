#!/usr/bin/env bash
set -euo pipefail

# Cleans the PROMETHEUS_MULTIPROC_DIR on container start.
# Usage: ensure this script is present in the container and run it before starting the app process.
# It is safe to run multiple times; it only removes files inside the directory.

DIR="${PROMETHEUS_MULTIPROC_DIR:-/var/prometheus-multiproc}"

echo "[clean_multiproc_dir] Cleaning multiproc dir: $DIR"

if [ -d "$DIR" ]; then
  # Remove all regular files (don't remove directories to be safe)
  find "$DIR" -mindepth 1 -maxdepth 1 -type f -print -exec rm -f {} + || true
else
  mkdir -p "$DIR"
  echo "[clean_multiproc_dir] Created directory: $DIR"
fi

# Ensure directory is writable
if [ ! -w "$DIR" ]; then
  echo "[clean_multiproc_dir] WARNING: $DIR is not writable by current user"
fi

exit 0
