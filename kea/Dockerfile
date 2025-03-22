FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    kea \
    kea-dhcp4-server \
    kea-admin \
    kea-ctrl-agent \
    curl \
    supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/run/kea /run/kea \
    && chown -R _kea:_kea /var/run/kea /run/kea

COPY conf/kea-dhcp4.conf /etc/kea/
COPY conf/kea-ctrl-agent.conf /etc/kea/

# 添加supervisor配置
COPY conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 67/udp 8000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8000/status || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"] 