#!/bin/sh
set -e

echo "Starting monitoring stack..."
echo "Memory limit: 512MB"
echo "Prometheus: http://127.0.0.1:9090"
echo "Grafana: http://${PORT:-3000} (PORT env: ${PORT:-3000})"

# Start supervisord
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
