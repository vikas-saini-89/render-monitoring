# Setup Guide - Monitoring Stack

This guide provides step-by-step instructions for setting up the monitoring stack in different environments.

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [First-Time Setup](#first-time-setup)
5. [Verification](#verification)
6. [Common Issues](#common-issues)

## System Requirements

### Minimum Requirements (1GB VM)
- CPU: 1 vCore
- RAM: 1GB
- Disk: 10GB free space
- OS: Ubuntu 20.04+ or similar Linux distribution
- Docker: 20.10+
- Docker Compose: 1.29+

### Recommended Requirements (Standard VM)
- CPU: 2 vCores
- RAM: 2GB
- Disk: 20GB free space
- OS: Ubuntu 22.04 LTS
- Docker: 24.0+
- Docker Compose: 2.0+

## Installation

### Step 1: Install Docker

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add your user to the docker group
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
```

### Step 2: Install Docker Compose

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Step 3: Clone/Copy Monitoring Files

```bash
# Create monitoring directory
mkdir -p ~/monitoring
cd ~/monitoring

# Copy all monitoring configuration files to this directory
# - prometheus.yml
# - alert-rules.yml
# - alertmanager.yml
# - docker-compose.yml
# - dashboards/
# - deploy-*.sh
# - validate.sh
```

## Configuration

### Configure Prometheus

Edit `prometheus.yml` to customize:

```yaml
global:
  scrape_interval: 15s  # How often to scrape targets
  evaluation_interval: 15s  # How often to evaluate rules

scrape_configs:
  # Add your application endpoints here
  - job_name: 'my-app'
    static_configs:
      - targets: ['app-host:8080']
```

### Configure Alert Rules

Edit `alert-rules.yml` to customize thresholds:

```yaml
- alert: HighCPUUsage
  expr: cpu_usage > 80  # Adjust threshold
  for: 5m  # Adjust duration
```

### Configure Alertmanager

Edit `alertmanager.yml` to set up notifications. Email alerts are optional and disabled by default; to enable SMTP, uncomment and configure the following example in `alertmanager.yml` and set credentials as secrets in your deployment platform:

```yaml
# receivers:
#   - name: 'email-alerts'
#     email_configs:
#       - to: 'your-team@company.com'
#         from: 'alerts@company.com'
#         smarthost: 'smtp.company.com:587'
#         auth_username: 'alerts@company.com'
#         auth_password: 'your-password'
```

### Configure Grafana

Default credentials (change after first login):
- Username: `admin`
- Password: `admin`

To change default password, edit `docker-compose.yml`:

```yaml
grafana:
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=your-secure-password
```

## First-Time Setup

### Option A: Automated Deployment (1GB VM)

```bash
cd ~/monitoring
./deploy-1gb-vm.sh
```

This script will:
- Install Docker and Docker Compose if needed
- Set up optimized resource limits
- Start all services
- Display access URLs

### Option B: Automated Deployment (Standard VM)

```bash
cd ~/monitoring
./deploy-vm2.sh
```

This script will:
- Verify prerequisites
- Configure Grafana provisioning
- Start all services with full features
- Perform health checks
- Display access information

### Option C: Manual Deployment

```bash
cd ~/monitoring

# Pull images
docker-compose pull

# Start services in detached mode
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

## Verification

### Run Validation Script

```bash
./validate.sh
```

This checks:
- Configuration file syntax
- Docker installation and status
- Running services
- Service endpoints
- Script permissions

### Manual Verification

1. **Check Prometheus**
   ```bash
   curl http://localhost:9090/-/healthy
   # Should return: Prometheus Server is Healthy.
   ```

2. **Check Grafana**
   ```bash
   curl http://localhost:3000/api/health
   # Should return JSON with status
   ```

3. **Check Alertmanager**
   ```bash
   curl http://localhost:9093/-/healthy
   # Should return: OK
   ```

4. **Access Web UIs**
   - Prometheus: http://your-server-ip:9090
   - Grafana: http://your-server-ip:3000
   - Alertmanager: http://your-server-ip:9093

### Import Dashboards to Grafana

1. Log into Grafana (http://your-server-ip:3000)
2. Navigate to Dashboards > Import
3. Click "Upload JSON file"
4. Import each dashboard from the `dashboards/` directory:
   - attendance-pulse.json
   - leave-reconciliation.json
   - streaming-payroll.json
   - system-health.json

## Common Issues

### Issue: Docker daemon not running
```bash
# Start Docker
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker
```

### Issue: Permission denied accessing Docker
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and log back in, or run:
newgrp docker
```

### Issue: Port already in use
```bash
# Check what's using the port
sudo lsof -i :9090  # Replace 9090 with your port

# Stop the conflicting service or change ports in docker-compose.yml
```

### Issue: Service fails to start (memory)
```bash
# Check available memory
free -h

# If low on memory, use the 1GB VM deployment
./deploy-1gb-vm.sh
```

### Issue: Can't access services from external IP
```bash
# Check firewall rules
sudo ufw status

# Allow required ports
sudo ufw allow 9090/tcp  # Prometheus
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 9093/tcp  # Alertmanager
```

### Issue: Grafana shows "No Data"
1. Check Prometheus data source configuration in Grafana
2. Verify Prometheus is scraping targets: http://your-ip:9090/targets
3. Check if metrics are being collected: http://your-ip:9090/graph

## Next Steps

After successful setup:

1. **Change Default Passwords**
   - Update Grafana admin password
   - Secure Prometheus and Alertmanager with authentication

2. **Configure SSL/TLS**
   - Set up reverse proxy (nginx/Apache)
   - Install SSL certificates

3. **Set Up Backups**
   - Configure automated backups for Prometheus data
   - Export Grafana dashboards regularly

4. **Monitor Your Applications**
   - Add your application metrics endpoints to Prometheus
   - Create custom dashboards in Grafana
   - Set up relevant alerts

5. **Review Documentation**
   - Read [README.md](./README.md) for overview
   - Check [IMPLEMENTATION_COMPLETE.md](./IMPLEMENTATION_COMPLETE.md) for details

## Support

If you encounter issues not covered here:
1. Check service logs: `docker-compose logs [service-name]`
2. Run validation: `./validate.sh`
3. Review Prometheus/Grafana documentation
4. Check Docker and system logs

## Maintenance

### Regular Tasks

**Weekly:**
- Check disk space: `df -h`
- Review alert history in Alertmanager
- Verify backup integrity

**Monthly:**
- Update Docker images: `docker-compose pull && docker-compose up -d`
- Review and optimize alert rules
- Clean up old metrics data if needed

**Quarterly:**
- Security audit of access credentials
- Review and update dashboard configurations
- Evaluate resource usage and scaling needs
