# Deploy Celery Prometheus Exporter (VM: 10.0.0.193)

This document describes recommended ways to run a Celery Prometheus exporter on the VM (`10.0.0.193`) where your Redis broker is accessible.

Security: Do not commit secrets. Provide `REDIS_URL` via environment variables, systemd drop-in, Docker secrets, or similar.

Option A — Run with Docker (recommended)

1. Create a small `docker-compose.yml` on the VM (example):

```yaml
version: '3.8'
services:
  celery-exporter:
    image: python:3.11-slim
    environment:
      - REDIS_URL=${REDIS_URL}
    command: >
      sh -c "pip install celery-prometheus-exporter && celery-prometheus-exporter --broker ${REDIS_URL} --port 9540"
    ports:
      - "9540:9540"
    restart: unless-stopped
```

2. Export the `REDIS_URL` in a `.env` file (on the VM) or pass it into the container using your secret method.

3. Start the exporter:

```bash
docker compose up -d
```

4. Verify locally on the VM:

```bash
curl http://localhost:9540/metrics
```

Option B — Run as a systemd service (simple, no Docker)

1. Install a virtualenv and the exporter on the VM:

```bash
python -m venv /opt/celery-exporter/venv
. /opt/celery-exporter/venv/bin/activate
pip install celery-prometheus-exporter
```

2. Create a systemd service `/etc/systemd/system/celery-exporter.service`:

```ini
[Unit]
Description=Celery Prometheus Exporter
After=network.target

[Service]
Environment=REDIS_URL=redis://:password@10.0.0.193:6380/0
ExecStart=/opt/celery-exporter/venv/bin/celery-prometheus-exporter --broker $REDIS_URL --port 9540
Restart=always
User=youruser

[Install]
WantedBy=multi-user.target
```

3. Start and enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now celery-exporter
```

4. Verify with:

```bash
curl http://localhost:9540/metrics
```

Prometheus configuration

- I updated `prometheus.yml` in this repo to scrape `10.0.0.193:9540`.
- If your Prometheus runs elsewhere, ensure it can reach `10.0.0.193:9540` on the network/firewall.

Grafana

- I added `dashboards/celery.json` to this repo. Grafana will pick it up if provisioning uses `./dashboards` (already configured).

If you want, I can also:
- Provide a ready-to-run `docker-compose` file for the VM (with instructions to pass `REDIS_URL`),
- Add a systemd unit file to the repo as a template,
- Or remotely deploy the exporter if you give me access to that VM.
