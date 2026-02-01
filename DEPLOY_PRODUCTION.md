Production deployment notes

Postgres for Grafana (recommended)

Why Postgres?
- SQLite has locking issues under concurrent writes. Postgres is production-grade, reliable, and works well on managed providers.

How to configure Grafana to use Postgres
- Set the following environment variables in your Render/host environment (examples):
  - GF_DATABASE_TYPE=postgres
  - GF_DATABASE_HOST=postgres:5432
  - GF_DATABASE_NAME=grafana
  - GF_DATABASE_USER=grafana
  - GF_DATABASE_PASSWORD=supersecret

Example Render service notes
- Create a managed Postgres on Render and attach it to your Grafana service.
- Set the env variables above in the service settings.

Optional: Migrate SQLite -> Postgres
- Grafana provides migration tools / guides to move dashboards and data. For minimal deployments, you can re-seed datasources and dashboards using provisioning files.

Quick tips
- Keep `GF_SECURITY_ADMIN_PASSWORD` as an environment variable or secret.
- Use persistent storage for Prometheus TSDB and Grafana data dirs.
- Add CI that builds the image and validates `/api/health` and `/-/healthy` endpoints.

Docker Compose note
- If you deploy using `docker-compose`, use the compose-specific Grafana datasource: `grafana-datasources-compose.yml`.
- The compose datasource uses the Prometheus service hostname (`http://prometheus:9090`) so Grafana can reach Prometheus across containers.
