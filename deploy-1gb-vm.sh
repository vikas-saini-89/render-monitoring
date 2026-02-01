#!/bin/bash
# Deploy monitoring exporters on 1GB VM
# Prerequisites: sudo access, curl
# Usage: ./deploy-1gb-vm.sh [skip-node-exporter]

set -e

SKIP_NODE_EXPORTER=${1:-false}
VM_IP=$(hostname -I | awk '{print $1}')

echo "🚀 Deploying monitoring exporters on 1GB VM..."
echo "📍 VM IP: $VM_IP"

# =============================================================================
# 1. Deploy node-exporter (system metrics)
# =============================================================================
if [ "$SKIP_NODE_EXPORTER" != "skip-node-exporter" ]; then
    echo ""
    echo "📊 Installing node-exporter..."
    
    # Check if already installed
    if command -v node_exporter &> /dev/null; then
        echo "✅ node-exporter already installed"
    else
        # Download and install node-exporter
        NODEEXP_VERSION="1.6.1"
        NODEEXP_FILE="node_exporter-${NODEEXP_VERSION}.linux-amd64.tar.gz"
        NODEEXP_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODEEXP_VERSION}/${NODEEXP_FILE}"
        
        cd /tmp
        echo "⬇️  Downloading node-exporter v$NODEEXP_VERSION..."
        curl -sL "$NODEEXP_URL" -o "$NODEEXP_FILE"
        
        echo "📦 Extracting..."
        tar xzf "$NODEEXP_FILE"
        
        echo "📝 Installing to /usr/local/bin..."
        sudo mv "node_exporter-${NODEEXP_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
        rm -rf "node_exporter-${NODEEXP_VERSION}.linux-amd64" "$NODEEXP_FILE"
        
        echo "✅ node-exporter installed"
    fi
    
    # Create systemd service
    echo "🔧 Creating systemd service..."
    sudo tee /etc/systemd/system/node-exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/node_exporter \\
    --collector.textfile.directory=/var/lib/node_exporter/textfile_collector \\
    --collector.systemd \\
    --collector.processes

SyslogIdentifier=node-exporter
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    echo "✅ Systemd service created"
    
    # Create textfile collector directory
    sudo mkdir -p /var/lib/node_exporter/textfile_collector
    sudo chown nobody:nogroup /var/lib/node_exporter/textfile_collector
    
    # Enable and start
    sudo systemctl daemon-reload
    sudo systemctl enable node-exporter
    sudo systemctl start node-exporter
    
    # Verify
    sleep 2
    if sudo systemctl is-active --quiet node-exporter; then
        echo "✅ node-exporter started successfully"
        echo "   Endpoint: http://$VM_IP:9100/metrics"
    else
        echo "❌ Failed to start node-exporter"
        sudo systemctl status node-exporter
        exit 1
    fi
fi

# =============================================================================
# 2. Verify django-prometheus is running
# =============================================================================
echo ""
echo "🍃 Verifying Django prometheus metrics..."
DJANGO_PORT="${DJANGO_PORT:-8000}"
if curl -s "http://localhost:$DJANGO_PORT/metrics" > /dev/null; then
    echo "✅ Django /metrics endpoint responding"
    echo "   Endpoint: http://$VM_IP:$DJANGO_PORT/metrics"
    
    # Show first few metrics
    echo ""
    echo "📊 Sample metrics:"
    curl -s "http://localhost:$DJANGO_PORT/metrics" | head -20
else
    echo "⚠️  Django /metrics endpoint not responding"
    echo "   Make sure Django is running on port $DJANGO_PORT"
fi

# =============================================================================
# 3. Setup Flower for Celery monitoring
# =============================================================================
echo ""
echo "🌸 Setting up Flower for Celery monitoring..."

# Check if flower is installed
if python -c "import flower" 2>/dev/null; then
    echo "✅ Flower already installed"
else
    echo "📦 Installing Flower..."
    pip install --quiet flower prometheus-client
    echo "✅ Flower installed"
fi

# Create Flower systemd service
echo "🔧 Creating Flower systemd service..."
sudo tee /etc/systemd/system/flower.service > /dev/null <<'EOF'
[Unit]
Description=Flower - Celery Monitoring Tool
After=network.target redis.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/home/app
Environment="CELERY_BROKER_URL=redis://localhost:6379/0"
Environment="CELERY_RESULT_BACKEND=redis://localhost:6379/1"
ExecStart=/usr/local/bin/flower \
    --broker=redis://localhost:6379/0 \
    --result_backend=redis://localhost:6379/1 \
    --port=5555 \
    --persistent=True \
    --db=/tmp/flower.db

SyslogIdentifier=flower
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Flower systemd service created"

# Enable and start Flower (if not already running)
sudo systemctl daemon-reload
if ! sudo systemctl is-active --quiet flower; then
    sudo systemctl enable flower
    sudo systemctl start flower
    
    # Wait for startup
    sleep 3
fi

# Verify Flower
if curl -s "http://localhost:5555/metrics" > /dev/null 2>&1; then
    echo "✅ Flower metrics endpoint responding"
    echo "   Endpoint: http://$VM_IP:5555/metrics"
else
    echo "⚠️  Flower metrics endpoint not responding"
    echo "   Status: $(sudo systemctl is-active flower)"
fi

# =============================================================================
# 4. Verify Centrifugo stats endpoint
# =============================================================================
echo ""
echo "🔴 Verifying Centrifugo stats endpoint..."
CENTRIFUGO_PORT="${CENTRIFUGO_PORT:-8000}"
if curl -s "http://localhost:$CENTRIFUGO_PORT/api/stats" > /dev/null; then
    echo "✅ Centrifugo /api/stats endpoint responding"
    echo "   Endpoint: http://$VM_IP:$CENTRIFUGO_PORT/api/stats"
else
    echo "⚠️  Centrifugo /api/stats endpoint not responding"
    echo "   Make sure Centrifugo is running"
fi

# =============================================================================
# 5. Verify PostgreSQL connectivity
# =============================================================================
echo ""
echo "🗄️  Verifying PostgreSQL connectivity..."
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
if pg_isready -h localhost -p "$POSTGRES_PORT" > /dev/null 2>&1; then
    echo "✅ PostgreSQL accessible"
    echo "   Connection: localhost:$POSTGRES_PORT"
else
    echo "⚠️  PostgreSQL not responding on port $POSTGRES_PORT"
    echo "   postgres-exporter on VM 2 will attempt remote connection"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ MONITORING EXPORTERS DEPLOYED"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📊 Metrics Endpoints Available on 1GB VM:"
echo "   • Node Exporter:   http://$VM_IP:9100/metrics"
echo "   • Django App:      http://$VM_IP:$DJANGO_PORT/metrics"
echo "   • Flower:          http://$VM_IP:5555/metrics"
echo "   • Centrifugo:      http://$VM_IP:$CENTRIFUGO_PORT/api/stats"
echo ""
echo "🔍 Next Steps:"
echo "   1. Deploy monitoring stack on VM 2 (run deploy-vm2.sh)"
echo "   2. Verify Prometheus can scrape these endpoints:"
echo "      curl http://<vm2-ip>:9090/api/v1/query?query=up"
echo "   3. Add Render Grafana data source pointing to VM 2 Prometheus"
echo "   4. Import dashboards from monitoring/dashboards/"
echo ""
echo "🛑 Stop Services:"
echo "   sudo systemctl stop node-exporter flower"
echo "   sudo systemctl disable node-exporter flower"
echo ""
