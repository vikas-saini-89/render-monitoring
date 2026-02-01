#!/bin/bash
# Deploy monitoring stack on VM 2
# Prerequisites: Docker, Docker Compose installed
# Usage: ./deploy-vm2.sh [environment]

set -e

# Ensure .env exists with resource limits (suitable for a 2GB+ VM)
if [ ! -f .env ]; then
  echo "Creating .env with default resource limits for standard VM..."
  cat > .env <<'EOF'
# Resource limits (memory values accepted by Docker Compose, e.g., 300M)
PROMETHEUS_MEM=300M
GRAFANA_MEM=250M
ALERTMANAGER_MEM=150M
CADVISOR_MEM=100M
NODE_EXPORTER_MEM=20M
NGINX_MEM=50M
EOF
  echo ".env created — edit values if needed."
fi

ENV=${1:-production}
MONITORING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Deploying monitoring stack to VM 2..."
echo "📍 Environment: $ENV"
echo "📂 Monitoring directory: $MONITORING_DIR"

# Verify required files exist
required_files=("prometheus.yml" "alert-rules.yml" "alertmanager.yml" "docker-compose.yml")
for file in "${required_files[@]}"; do
    if [ ! -f "$MONITORING_DIR/$file" ]; then
        echo "❌ Missing required file: $file"
        exit 1
    fi
done
echo "✅ All required files present"

# Create persistent volumes
echo ""
echo "📦 Creating persistent volumes..."
mkdir -p "$MONITORING_DIR/prometheus_data"
mkdir -p "$MONITORING_DIR/alertmanager_data"
chmod 755 "$MONITORING_DIR/prometheus_data"
chmod 755 "$MONITORING_DIR/alertmanager_data"
echo "✅ Volumes created"

# Set environment variables
export POSTGRES_HOST="${POSTGRES_HOST:-1gb-vm.internal}"
export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
export POSTGRES_DB="${POSTGRES_DB:-school_accounting}"
export POSTGRES_USER="${POSTGRES_USER:-postgres}"
export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-}"  # Must be set before running

if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "❌ Error: POSTGRES_PASSWORD environment variable not set"
    echo "   Set it with: export POSTGRES_PASSWORD='your-password'"
    exit 1
fi

# Start the monitoring stack
echo ""
echo "🔨 Starting monitoring stack with docker-compose..."
cd "$MONITORING_DIR"
docker-compose -f docker-compose.yml up -d

# Wait for services to be ready
echo ""
echo "⏳ Waiting for services to be ready (30 seconds)..."
sleep 30

# Verify services are running
echo ""
echo "✅ Verifying services..."

# Check Prometheus
if curl -s http://localhost:9090/-/healthy > /dev/null 2>&1; then
    echo "✅ Prometheus: UP (http://localhost:9090)"
else
    echo "⚠️  Prometheus: Not responding yet"
fi

# Check AlertManager
if curl -s http://localhost:9093/-/healthy > /dev/null 2>&1; then
    echo "✅ AlertManager: UP (http://localhost:9093)"
else
    echo "⚠️  AlertManager: Not responding yet"
fi

# Check postgres-exporter
if curl -s http://localhost:9187 > /dev/null 2>&1; then
    echo "✅ postgres-exporter: UP (http://localhost:9187)"
else
    echo "⚠️  postgres-exporter: Not responding yet"
fi

echo ""
echo "📊 Monitoring Stack Deployed!"
echo ""
echo "🔗 Access Points:"
echo "   - Prometheus: http://$(hostname -I | awk '{print $1}'):9090"
echo "   - AlertManager: http://$(hostname -I | awk '{print $1}'):9093"
echo "   - postgres-exporter: http://$(hostname -I | awk '{print $1}'):9187"
echo ""
echo "📋 Next Steps:"
echo "   1. Configure Grafana data source:"
echo "      URL: http://$(hostname -I | awk '{print $1}'):9090"
echo "   2. Import dashboards from monitoring/dashboards/"
echo "   3. Configure AlertManager notifications in alertmanager.yml"
echo "   4. View logs: docker-compose logs -f"
echo ""
echo "🛑 Stop monitoring stack:"
echo "   cd $MONITORING_DIR && docker-compose down"
