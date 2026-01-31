# Monitoring Stack for Render

A comprehensive monitoring solution built with Prometheus, Grafana, and Alertmanager for tracking HR systems including attendance, leave management, and payroll processing.

## 🎯 Overview

This monitoring stack provides real-time visibility into:
- **Attendance Tracking**: Monitor daily attendance rates, absenteeism, and late arrivals
- **Leave Management**: Track leave balances, pending requests, and reconciliation status
- **Payroll Processing**: Monitor streaming payroll operations, processing rates, and errors
- **System Health**: Track CPU, memory, disk usage, and service availability

## 📦 Components

### Core Services
- **Prometheus** (Port 9090): Metrics collection and alerting
- **Grafana** (Port 3000): Visualization and dashboards
- **Alertmanager** (Port 9093): Alert routing and notification
- **Node Exporter** (Port 9100): System metrics
- **cAdvisor** (Port 8080): Container metrics

### Dashboards
- `attendance-pulse.json`: Real-time attendance monitoring
- `leave-reconciliation.json`: Leave management analytics
- `streaming-payroll.json`: Payroll processing metrics
- `system-health.json`: Infrastructure monitoring

## 🚀 Quick Start

### Prerequisites
- Docker 20.10+
- Docker Compose 1.29+
- 1GB+ RAM (2GB+ recommended)
- Linux/Unix environment

### Deployment Options

#### Option 1: 1GB VM (Resource Constrained)
```bash
./deploy-1gb-vm.sh
```
Optimized for minimal resource usage with memory limits.

#### Option 2: Standard VM (2GB+)
```bash
./deploy-vm2.sh
```
Full-featured deployment with all services.

### Manual Deployment
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
| Grafana | http://your-ip:3000 | admin / admin |
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
```bash
# Backup Prometheus data
docker-compose exec prometheus tar czf /tmp/prometheus-backup.tar.gz /prometheus

# Backup Grafana dashboards
docker-compose exec grafana tar czf /tmp/grafana-backup.tar.gz /var/lib/grafana
```

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
**Change default passwords immediately after deployment!**

```bash
# Grafana: Access Settings > Users to change admin password
# Or use environment variables in docker-compose.yml:
# - GF_SECURITY_ADMIN_PASSWORD=your-secure-password
```

### Best Practices
- Use TLS/SSL for production deployments
- Restrict network access with firewall rules
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
