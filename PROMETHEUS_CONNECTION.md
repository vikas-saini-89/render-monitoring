# Prometheus Connection Instructions (for Copilot)

Goal: Connect a Django + Celery (Redis broker) project to Prometheus by exposing metrics endpoints and configuring Prometheus scrape targets.

## 1) Django metrics (django-prometheus)

### Install
- Add `django-prometheus` to requirements.

### Settings
- Add app:
  - `django_prometheus` to `INSTALLED_APPS`.
- Add middleware (order matters):
  - `django_prometheus.middleware.PrometheusBeforeMiddleware` near the top.
  - `django_prometheus.middleware.PrometheusAfterMiddleware` near the bottom.

### URLs
- Add a metrics endpoint:
  - `path("metrics/", include("django_prometheus.urls"))`

### Multiprocess (Gunicorn / uWSGI)
If the server uses multiple workers, configure multiprocess mode:
- Set env var `PROMETHEUS_MULTIPROC_DIR` to a writable dir.
- Ensure the dir is cleaned on startup.
- Use the `django_prometheus` multiprocess setup per docs.

## 2) Celery metrics

### Preferred option: celery-prometheus-exporter
- Run `celery-prometheus-exporter` pointing at the broker URL.
- Exposes metrics on port `9540` by default.
- Ensure the exporter is reachable by Prometheus.

### Alternative
- Use `prometheus_client` directly inside workers.

## 3) Update Prometheus scrape config

Edit [prometheus.yml](prometheus.yml) and add scrape jobs for Django and Celery exporter.

Example:

```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["127.0.0.1:9090"]

  - job_name: "django"
    metrics_path: "/metrics"
    static_configs:
      - targets: ["<DJANGO_HOST>:<DJANGO_PORT>"]

  - job_name: "celery"
    static_configs:
      - targets: ["<CELERY_EXPORTER_HOST>:9540"]
```

## 4) Networking requirements
- Prometheus must be able to reach the Django `/metrics` endpoint and Celery exporter port.
- Open firewall/security group for:
  - Django metrics port
  - Celery exporter port (9540)

## 5) Verification
- Open Prometheus UI and check `Status -> Targets`.
- `django` and `celery` should be `UP`.

## Inputs needed from user
- Django service public or internal hostname/IP and port.
- Celery exporter hostname/IP (same host as workers if local) and port.
- Whether Django is single-process or multi-worker (for multiprocess config).
