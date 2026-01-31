#!/bin/sh
set -e

echo "Starting monitoring stack..."
echo "Memory limit: 512MB"
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3000"

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
