#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$(pwd)/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_DIR"

echo "🔐 Creating backups in $BACKUP_DIR"

# Prometheus
if docker-compose ps -q prometheus > /dev/null 2>&1; then
  echo "📦 Backing up Prometheus data..."
  docker-compose exec -T prometheus tar czf - /prometheus > "$BACKUP_DIR/prometheus-$TIMESTAMP.tar.gz"
  echo "  ✓ prometheus-$TIMESTAMP.tar.gz"
else
  echo "⚠ Prometheus container not running, skipping Prometheus backup"
fi

# Grafana
if docker-compose ps -q grafana > /dev/null 2>&1; then
  echo "📦 Backing up Grafana data..."
  docker-compose exec -T grafana tar czf - /var/lib/grafana > "$BACKUP_DIR/grafana-$TIMESTAMP.tar.gz"
  echo "  ✓ grafana-$TIMESTAMP.tar.gz"
else
  echo "⚠ Grafana container not running, skipping Grafana backup"
fi

echo "✅ Backups complete: $BACKUP_DIR"
ls -lh "$BACKUP_DIR" | sed -n '1,10p'
