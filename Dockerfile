FROM alpine:3.19

# Install supervisord and required packages
RUN apk add --no-cache \
    supervisor \
    wget \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Install Prometheus (lightweight)
RUN wget -q https://github.com/prometheus/prometheus/releases/download/v2.48.0/prometheus-2.48.0.linux-amd64.tar.gz && \
    tar xzf prometheus-2.48.0.linux-amd64.tar.gz && \
    mv prometheus-2.48.0.linux-amd64 /opt/prometheus && \
    rm prometheus-2.48.0.linux-amd64.tar.gz

# Install Grafana (lightweight)
RUN wget -q https://dl.grafana.com/oss/release/grafana-10.2.3.linux-amd64.tar.gz && \
    tar xzf grafana-10.2.3.linux-amd64.tar.gz && \
    EXTRACT_DIR=$(tar -tf grafana-10.2.3.linux-amd64.tar.gz | head -1 | cut -f1 -d"/") && \
    mv "$EXTRACT_DIR" /opt/grafana && \
    rm grafana-10.2.3.linux-amd64.tar.gz

# Create grafana user and directories
RUN adduser -D -h /var/lib/grafana grafana && \
    mkdir -p /etc/prometheus /etc/grafana /var/lib/grafana /var/log/grafana /prometheus /etc/supervisor/conf.d && \
    chown -R grafana:grafana /var/lib/grafana /var/log/grafana /etc/grafana /opt/grafana

# Copy configuration files
COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY alert-rules.yml /etc/prometheus/alert-rules.yml
COPY grafana-datasources.yml /etc/grafana/provisioning/datasources/datasources.yml
COPY dashboard-provider.yml /etc/grafana/provisioning/dashboards/dashboard-provider.yml
COPY dashboards /etc/grafana/provisioning/dashboards
COPY grafana.ini /etc/grafana/grafana.ini
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh

RUN chmod +x /start.sh

# Expose Grafana port (primary interface)
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget -q --spider http://localhost:3000/api/health || exit 1

# Run supervisor
CMD ["/start.sh"]
