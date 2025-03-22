FROM ubuntu:22.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils && \
    rm -rf /var/lib/apt/lists/*

# 创建必要的目录并设置权限
RUN mkdir -p /var/cache/bind /var/run/named /var/log/bind /run/named /etc/bind/keys && \
    chown -R bind:bind /var/cache/bind /var/run/named /var/log/bind /etc/bind /run/named /etc/bind/keys && \
    chmod 775 /var/cache/bind /var/run/named /var/log/bind /etc/bind /run/named /etc/bind/keys

# 复制配置文件
COPY conf/ /etc/bind/
COPY generate_key.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate_key.sh && \
    chown -R bind:bind /usr/local/bin/generate_key.sh

# 切换到root用户运行（因为需要生成key文件）
USER root

# 创建启动脚本
RUN echo '#!/bin/bash\n\
/usr/local/bin/generate_key.sh\n\
chown -R bind:bind /var/cache/bind /var/run/named /var/log/bind /etc/bind /run/named /etc/bind/keys\n\
chmod 775 /var/cache/bind /var/run/named /var/log/bind /etc/bind /run/named /etc/bind/keys\n\
exec /usr/sbin/named -g -c /etc/bind/named.conf -u bind' > /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/start.sh

EXPOSE 53/tcp 53/udp

ENTRYPOINT ["/usr/local/bin/start.sh"]

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD dig @localhost localhost || exit 1 