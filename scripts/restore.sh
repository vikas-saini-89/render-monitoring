#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 /path/to/backup-directory-or-tar"
  exit 2
fi

BACKUP_PATH="$1"

# Helper: find docker volume mountpoint for a volume containing the given name
find_volume_mountpoint() {
  name_pattern="$1"
  vol=$(docker volume ls --format '{{.Name}}' | grep -E "$name_pattern" | head -n1 || true)
  if [ -z "$vol" ]; then
    echo ""; return 1
  fi
  mountpoint=$(docker volume inspect "$vol" --format '{{.Mountpoint}}' 2>/dev/null || true)
  if [ -z "$mountpoint" ]; then
    echo ""; return 1
  fi
  echo "$mountpoint"
}

# Restore Prometheus
if ls "$BACKUP_PATH"/prometheus-*.tar.gz >/dev/null 2>&1; then
  PROM_BACKUP=$(ls -t "$BACKUP_PATH"/prometheus-*.tar.gz | head -n1)
  echo "🔁 Restoring Prometheus from $PROM_BACKUP"
  echo "⏸ Stopping Prometheus container..."
  docker-compose stop prometheus || true
  mountpoint=$(find_volume_mountpoint prometheus)
  if [ -z "$mountpoint" ]; then
    echo "❌ Could not find Prometheus volume mountpoint. Ensure the stack has created a volume named like '*prometheus*'."
    exit 1
  fi
  echo "Mountpoint: $mountpoint"
  echo "Extracting backup into volume (may require sudo)..."
  sudo tar xzf "$PROM_BACKUP" -C "$mountpoint" || { echo "Restore failed"; exit 1; }
  echo "✅ Prometheus restored"
else
  echo "ℹ No Prometheus backup found in $BACKUP_PATH"
fi

# Restore Grafana
if ls "$BACKUP_PATH"/grafana-*.tar.gz >/dev/null 2>&1; then
  GRAF_BACKUP=$(ls -t "$BACKUP_PATH"/grafana-*.tar.gz | head -n1)
  echo "🔁 Restoring Grafana from $GRAF_BACKUP"
  echo "⏸ Stopping Grafana container..."
  docker-compose stop grafana || true
  mountpoint=$(find_volume_mountpoint grafana)
  if [ -z "$mountpoint" ]; then
    echo "❌ Could not find Grafana volume mountpoint. Ensure the stack has created a volume named like '*grafana*'."
    exit 1
  fi
  echo "Mountpoint: $mountpoint"
  echo "Extracting backup into volume (may require sudo)..."
  sudo tar xzf "$GRAF_BACKUP" -C "$mountpoint" || { echo "Restore failed"; exit 1; }
  echo "✅ Grafana restored"
else
  echo "ℹ No Grafana backup found in $BACKUP_PATH"
fi

echo "🔁 Restore complete. Start services with: docker-compose up -d"
