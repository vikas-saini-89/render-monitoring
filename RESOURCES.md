# Resource Usage Estimates (Free Tier 512MB)

## Memory Breakdown

| Service | RAM Usage | Notes |
|---------|-----------|-------|
| Prometheus | ~150-200MB | With 7-day retention, 256MB max storage |
| Grafana | ~100-150MB | Lightweight, no plugins |
| Supervisord | ~5-10MB | Process manager |
| Alpine Linux | ~5MB | Base OS |
| **Total** | **~260-365MB** | **Fits in 512MB** ✅ |

## Disk Usage

| Component | Size | Notes |
|-----------|------|-------|
| Prometheus binaries | ~80MB | Metrics engine |
| Grafana binaries | ~150MB | Dashboard UI |
| Alpine packages | ~20MB | OS tools |
| Config files | ~1MB | Your configs |
| **Total Image** | **~250MB** | Docker image size |

## Runtime Storage

| Data | Size | Retention |
|------|------|-----------|
| Metrics data | 0-256MB | 7 days max |
| Grafana data | ~10MB | Settings, sessions |
| Logs | ~5MB | Rolling logs |
| **Total Runtime** | **~20-270MB** | Ephemeral (resets on restart) |

## Performance Optimizations

### Prometheus
- ✅ Scrape interval: 60s (reduced from 15s)
- ✅ Retention: 7 days (reduced from 15 days)
- ✅ Storage limit: 256MB (prevents memory bloat)
- ✅ Disabled unnecessary exporters

### Grafana
- ✅ No external plugins
- ✅ Minimal provisioning
- ✅ Basic authentication only

### Network
- ✅ Single container (no network overhead)
- ✅ Internal communication via localhost
- ✅ Only Grafana exposed (port 3000)

## Expected Metrics Capacity

With 256MB storage and 60s scrape interval:
- **~7 days** of metrics history
- **~1000-2000 time series** (depending on cardinality)
- **~100-200K samples** total

Perfect for:
- ✅ Small to medium applications (1-5 services)
- ✅ Basic infrastructure monitoring
- ✅ HR/business metrics dashboards
- ✅ Development/staging environments

**Not suitable for:**
- ❌ High-cardinality metrics (millions of series)
- ❌ Multiple production applications
- ❌ Long-term data retention (>7 days)
- ❌ Heavy traffic monitoring (>1000 req/s)

## Free Tier Limits

Render Free Tier:
- 🆓 512MB RAM
- 🆓 750 hours/month
- 🆓 Sleeps after 15 min inactivity
- 🆓 No persistent storage
- 🆓 1 service per account (without credit card)

## Cost to Upgrade

If you outgrow free tier:
- **Starter ($7/month)**: 512MB RAM, no sleep, persistent storage
- **Standard ($25/month)**: 2GB RAM, better performance
- **Pro ($85/month)**: 8GB RAM, production-ready

Current setup optimized for: **FREE TIER** 🎉
