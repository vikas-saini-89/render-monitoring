# Quick Start Guide - Render Free Tier

## 🚀 Deploy to Render (Free 512MB)

### Step 1: Push to GitHub
```bash
git add .
git commit -m "Deploy monitoring stack for free tier"
git push origin main
```

### Step 2: Deploy on Render
1. Go to https://dashboard.render.com/
2. Click **"New +"** → **"Blueprint"**
3. Connect your repository: `vikas-saini-89/render-monitoring`
4. Select branch: `main`
5. Click **"Apply"**

### Step 3: Wait for Build
- Build time: ~3-5 minutes
- Service name: `monitoring-stack`
- Plan: Free (512MB RAM)

### Step 4: Access Grafana
- URL: `https://monitoring-stack.onrender.com`
- Username: `admin`
- Password: Found in Render Dashboard → monitoring-stack → Environment → `GF_SECURITY_ADMIN_PASSWORD`

## 📊 Configure Your App

### Update Prometheus Targets
Edit `prometheus.yml`:
```yaml
scrape_configs:
  - job_name: 'django-app'
    static_configs:
      - targets: ['your-app.onrender.com']  # Change this
```

Commit and push - Render auto-deploys!

## ⚠️ Free Tier Limitations
- **Sleeps after 15 min inactivity** (wakes on first request ~30s)
- **No persistent storage** (data resets on restart)
- **512MB RAM** (enough for basic monitoring)
- **750 hours/month free**

## 💡 Tips
- Keep service awake with external monitoring (UptimeRobot, etc.)
- Focus on critical metrics only
- Use longer scrape intervals (60s+)
- Limit retention (7 days, 256MB)

## 📝 File Structure
```
render-monitoring/
├── Dockerfile              # All-in-one container
├── render.yaml            # Render deployment config
├── prometheus.yml         # Metrics collection config
├── grafana-datasources.yml # Auto-configure Prometheus
├── dashboard-provider.yml # Auto-load dashboards
├── supervisord.conf       # Run both services
├── start.sh              # Startup script
└── dashboards/           # Pre-built dashboards
    ├── attendance-pulse.json
    ├── leave-reconciliation.json
    ├── streaming-payroll.json
    └── system-health.json
```

## ✅ Verify Deployment
Once deployed:
1. Visit your Grafana URL
2. Login with admin credentials
3. Check "Dashboards" → Should see 4 pre-loaded dashboards
4. Check "Configuration" → "Data Sources" → Prometheus should be connected

## 🐛 Troubleshooting
- **503 Error?** Service is sleeping, wait 30s
- **No data?** Update prometheus.yml with your app URL
- **Can't login?** Check environment variables in Render dashboard
- **Out of memory?** Reduce scrape frequency or metrics

## 📧 Support
Issues? Check logs in Render dashboard or open GitHub issue.
