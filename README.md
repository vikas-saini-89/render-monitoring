# Monitoring Stack for Render (Free Tier Optimized)

A lightweight monitoring solution built with Prometheus and Grafana for tracking HR systems including attendance, leave management, and payroll processing. **Optimized for Render's free tier (512MB RAM)**.

## 🎯 Overview

This monitoring stack provides real-time visibility into:
- **Attendance Tracking**: Monitor daily attendance rates, absenteeism, and late arrivals
- **Leave Management**: Track leave balances, pending requests, and reconciliation status
- **Payroll Processing**: Monitor streaming payroll operations, processing rates, and errors
- **System Health**: Track CPU, memory, disk usage, and service availability

## 📦 Components

### Core Services (All-in-One Container)
- **Prometheus** (Internal Port 9090): Metrics collection
- **Grafana** (Public Port 3000): Visualization and dashboards

### Dashboards
- `attendance-pulse.json`: Real-time attendance monitoring
- `leave-reconciliation.json`: Leave management analytics
- `streaming-payroll.json`: Payroll processing metrics
- `system-health.json`: Infrastructure monitoring

## 🚀 Deployment on Render (Free Tier)

### Quick Deploy
1. Push this repository to GitHub:
   ```bash
   git add .
   git commit -m "Deploy monitoring stack"
   git push origin main
   ```

2. Go to [Render Dashboard](https://dashboard.render.com/)

3. Click **"New +"** → **"Blueprint"**

4. Connect your GitHub repository

5. Render will automatically detect `render.yaml` and deploy the service

6. Wait for deployment to complete (3-5 minutes)

### Access Your Monitoring Stack
- **Grafana URL**: `https://monitoring-stack.onrender.com`

**Admin credentials**: Set the Grafana admin password at deploy time using an environment variable or Docker secret. Example (recommended):

- Using `.env` (local or CI):
```bash
# create a .env file with a secure password
export GF_SECURITY_ADMIN_PASSWORD="$(openssl rand -base64 18)"
# docker-compose will use variables from .env automatically
```

- Using Docker secrets (Swarm):
```bash
# echo "your-super-secret" | docker secret create grafana_admin_password -
# then set in docker-compose (example):
#    secrets:
#      - grafana_admin_password
#    environment:
#      - GF_SECURITY_ADMIN_PASSWORD_FILE=/run/secrets/grafana_admin_password
```

### Important Notes for Free Tier

**Pinned images (production guidance):**
- Prometheus: `prom/prometheus:v2.48.0`
- Alertmanager: `prom/alertmanager:v0.25.0`
- Grafana: `grafana/grafana:10.2.3`
- Node Exporter: `prom/node-exporter:v1.6.1`
- cAdvisor: `gcr.io/cadvisor/cadvisor:v0.47.0`

(Images are pinned in `docker-compose.yml` to provide stability and reproducible upgrades.)
- ⚠️ **Free tier services sleep after 15 minutes of inactivity**
- ⚠️ **No persistent storage** - data resets on service restart
- ⚠️ **512MB RAM limit** - optimized for minimal resource usage
- ⚠️ **Storage retention**: 7 days, max 256MB
- 💡 First request after sleep takes ~30 seconds to wake up

### Configure Your Application Metrics
1. Update `prometheus.yml` with your application URL:
   ```yaml
   scrape_configs:
     - job_name: 'django-app'
       static_configs:
         - targets: ['your-app.onrender.com']
   ```

2. Commit and push changes to auto-deploy

## 🐳 Local Development

### Prerequisites
- Docker 20.10+
- Docker Compose 1.29+
- 512MB+ RAM
- Linux/Unix environment

### Quick Start
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## 📊 Access

After deployment, access the services at:

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://your-ip:3000 | Admin user: `${GF_SECURITY_ADMIN_USER:-admin}`, password: set via `GF_SECURITY_ADMIN_PASSWORD` or Docker secret |
| Prometheus | http://your-ip:9090 | - |
| Alertmanager | http://your-ip:9093 | - |

## 🔔 Alerting

### Alert Categories

**System Alerts**
- High CPU usage (>80%)
- High memory usage (>85%)
- Low disk space (>90%)
- Service down

**HR Alerts**
- Low attendance rate (<70%)
- High absenteeism (>50 employees)
- High pending leave requests (>100)

**Payroll Alerts**
- Processing errors
- Stream failures
- Slow processing

### Alert Routing
Alerts are routed to appropriate teams via:
- Email notifications
- Webhook integrations
- Severity-based escalation

## 🔧 Configuration

### Prometheus
Edit `prometheus.yml` to configure:
- Scrape intervals
- Target endpoints
- Recording rules

### Alertmanager
Edit `alertmanager.yml` to configure:
- Notification receivers
- Route matching
- Inhibition rules

### Alert Rules
Edit `alert-rules.yml` to define:
- Alert conditions
- Thresholds
- Evaluation intervals

## 📈 Metrics

### Attendance Metrics
- `attendance_present`: Number of present employees
- `attendance_absent`: Number of absent employees
- `attendance_late`: Number of late arrivals
- `attendance_total`: Total employee count

### Leave Metrics
- `leave_balance_total`: Total leave days available
- `leave_requests_pending`: Pending leave requests
- `leave_requests_approved`: Approved leave requests
- `leave_taken`: Leave days taken by type

### Payroll Metrics
- `payroll_processed_total`: Total payroll records processed
- `payroll_stream_active`: Active processing streams
- `payroll_errors_total`: Processing errors
- `payroll_amount_processed`: Total amount processed

## 🛠️ Maintenance

### Backup
A simple backup script is provided to snapshot Prometheus and Grafana data. Run it on the host where docker-compose runs.

```bash
# Create a timestamped backup (saved to ./backups)
./scripts/backup.sh

# To restore (will stop services briefly) run:
./scripts/restore.sh /path/to/backups/YYYYMMDD-HHMMSS
```

**Notes:**
- Backups include Prometheus TSDB and Grafana data directory. Test restores in a staging environment before using in production.

### Updates
```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

### Troubleshooting
```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs [service-name]

# Restart a service
docker-compose restart [service-name]

# Run validation
./validate.sh
```

## 📝 Validation

Run the validation script to check configuration:
```bash
./validate.sh
```

This checks:
- Configuration file existence
- YAML/JSON syntax
- Docker installation
- Service health
- Script permissions

## 🔐 Security

### Default Credentials
**Change default passwords immediately after deployment!** Configure the Grafana admin password via environment variable or Docker secrets (see "Access Your Monitoring Stack").

### TLS + Basic Auth (Nginx reverse proxy example)
A lightweight `nginx` reverse proxy is included (sample config in `nginx/conf.d/`) to terminate TLS and enforce basic auth. Steps:

1. Create certificates in `nginx/certs/` (`fullchain.pem` and `privkey.pem`) or point to your cert manager.
2. Create a basic auth file (example):
```bash
# generate htpasswd entry for user 'admin'
docker run --rm httpd:2.4 htpasswd -Bbn admin 'your-password' > nginx/htpasswd
```
3. Start the stack; nginx proxies HTTPS traffic to Grafana and protects it with basic auth.
4. Health endpoint available: `https://<host>/health` (proxies to Grafana/Prometheus health endpoints)

> The included `docker-compose.yml` includes an `nginx` service (commented by default) and an example configuration. Adjust `nginx/conf.d/monitoring.conf` to match your domain and cert setup.

### Best Practices
- Use TLS/SSL for production deployments
- Restrict network access with firewall rules (VPC, security groups)
- Regularly update Docker images
- Enable authentication on all services
- Rotate credentials periodically

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Alertmanager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)

## 🤝 Support

For issues or questions:
1. Check the [SETUP_GUIDE.md](./SETUP_GUIDE.md)
2. Review [IMPLEMENTATION_COMPLETE.md](./IMPLEMENTATION_COMPLETE.md)
3. Run `./validate.sh` to diagnose problems

## 📄 License

See repository root for license information.
