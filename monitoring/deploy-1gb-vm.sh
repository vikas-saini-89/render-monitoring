#!/bin/bash

# Deploy Monitoring Stack on 1GB VM
# This script is optimized for minimal resource usage

set -e

echo "=========================================="
echo "Deploying Monitoring Stack on 1GB VM"
echo "=========================================="

# System requirements check
echo "Checking system requirements..."
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
if [ "$TOTAL_MEM" -lt 900 ]; then
    echo "Warning: Less than 1GB RAM available. Some services may not run properly."
fi

# Update system packages
echo "Updating system packages..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# Install Docker Compose if not installed
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create monitoring directory
MONITORING_DIR="/opt/monitoring"
echo "Creating monitoring directory at $MONITORING_DIR..."
sudo mkdir -p $MONITORING_DIR
sudo chown $USER:$USER $MONITORING_DIR

# Copy configuration files
echo "Copying configuration files..."
cp prometheus.yml $MONITORING_DIR/
cp alert-rules.yml $MONITORING_DIR/
cp alertmanager.yml $MONITORING_DIR/
cp docker-compose.yml $MONITORING_DIR/
cp -r dashboards $MONITORING_DIR/

# Navigate to monitoring directory
cd $MONITORING_DIR

# Create minimal docker-compose override for 1GB VM
echo "Creating resource-optimized configuration..."
cat > docker-compose.override.yml <<EOF
version: '3.8'
services:
  prometheus:
    mem_limit: 256m
    cpus: 0.5
  
  grafana:
    mem_limit: 128m
    cpus: 0.3
    
  alertmanager:
    mem_limit: 64m
    cpus: 0.2
    
  node-exporter:
    mem_limit: 32m
    cpus: 0.1
    
  cadvisor:
    mem_limit: 128m
    cpus: 0.2
EOF

# Pull images
echo "Pulling Docker images..."
docker-compose pull

# Start services
echo "Starting monitoring stack..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Verify services
echo "Verifying services..."
docker-compose ps

# Display access information
echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "Prometheus: http://$(curl -s ifconfig.me):9090"
echo "Grafana: http://$(curl -s ifconfig.me):3000"
echo "  Username: admin"
echo "  Password: admin"
echo "Alertmanager: http://$(curl -s ifconfig.me):9093"
echo ""
echo "To view logs: cd $MONITORING_DIR && docker-compose logs -f"
echo "To stop: cd $MONITORING_DIR && docker-compose down"
echo "=========================================="
