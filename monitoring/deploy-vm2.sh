#!/bin/bash

# Deploy Monitoring Stack on VM2 (Standard Deployment)
# This script is for standard resource VMs (2GB+ RAM)

set -e

echo "=========================================="
echo "Deploying Monitoring Stack on VM2"
echo "=========================================="

# Check prerequisites
echo "Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Set deployment directory
DEPLOY_DIR="/opt/monitoring-vm2"
echo "Setting up deployment directory: $DEPLOY_DIR"
sudo mkdir -p $DEPLOY_DIR
sudo chown $USER:$USER $DEPLOY_DIR

# Copy all monitoring files
echo "Copying monitoring configuration..."
cp prometheus.yml $DEPLOY_DIR/
cp alert-rules.yml $DEPLOY_DIR/
cp alertmanager.yml $DEPLOY_DIR/
cp docker-compose.yml $DEPLOY_DIR/
cp -r dashboards $DEPLOY_DIR/

# Navigate to deployment directory
cd $DEPLOY_DIR

# Configure Grafana datasource provisioning
echo "Configuring Grafana datasources..."
mkdir -p provisioning/datasources
cat > provisioning/datasources/prometheus.yml <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
EOF

# Configure Grafana dashboard provisioning
echo "Configuring Grafana dashboards..."
mkdir -p provisioning/dashboards
cat > provisioning/dashboards/default.yml <<EOF
apiVersion: 1

providers:
  - name: 'Default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

# Update docker-compose with Grafana provisioning
echo "Updating Docker Compose configuration..."
cat >> docker-compose.yml <<EOF

  # Additional configuration for Grafana provisioning
  grafana:
    volumes:
      - ./provisioning/datasources:/etc/grafana/provisioning/datasources
EOF

# Pull latest images
echo "Pulling latest Docker images..."
docker-compose pull

# Start the monitoring stack
echo "Starting monitoring services..."
docker-compose up -d

# Wait for services to initialize
echo "Waiting for services to initialize..."
sleep 20

# Health checks
echo "Performing health checks..."
for i in {1..10}; do
    if curl -s http://localhost:9090/-/healthy > /dev/null; then
        echo "✓ Prometheus is healthy"
        break
    fi
    echo "Waiting for Prometheus... ($i/10)"
    sleep 3
done

for i in {1..10}; do
    if curl -s http://localhost:3000/api/health > /dev/null; then
        echo "✓ Grafana is healthy"
        break
    fi
    echo "Waiting for Grafana... ($i/10)"
    sleep 3
done

# Get public IP
PUBLIC_IP=$(curl -s ifconfig.me || echo "localhost")

# Display summary
echo ""
echo "=========================================="
echo "Deployment Successful!"
echo "=========================================="
echo ""
echo "Services are now available:"
echo ""
echo "📊 Prometheus:"
echo "   URL: http://$PUBLIC_IP:9090"
echo "   Status: http://$PUBLIC_IP:9090/targets"
echo ""
echo "📈 Grafana:"
echo "   URL: http://$PUBLIC_IP:3000"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "🔔 Alertmanager:"
echo "   URL: http://$PUBLIC_IP:9093"
echo ""
echo "📡 Node Exporter:"
echo "   URL: http://$PUBLIC_IP:9100/metrics"
echo ""
echo "🐳 cAdvisor:"
echo "   URL: http://$PUBLIC_IP:8080"
echo ""
echo "=========================================="
echo "Useful Commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop stack: docker-compose down"
echo "  Restart: docker-compose restart"
echo "=========================================="

# Save deployment info
cat > deployment-info.txt <<EOF
Deployment Date: $(date)
Deployment Directory: $DEPLOY_DIR
Public IP: $PUBLIC_IP
Prometheus: http://$PUBLIC_IP:9090
Grafana: http://$PUBLIC_IP:3000
Alertmanager: http://$PUBLIC_IP:9093
EOF

echo ""
echo "Deployment information saved to: $DEPLOY_DIR/deployment-info.txt"
