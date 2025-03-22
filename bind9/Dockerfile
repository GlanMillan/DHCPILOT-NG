FROM ubuntu:22.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils && \
    rm -rf /var/lib/apt/lists/*

# 创建必要的目录并设置权限
RUN mkdir -p /var/cache/bind /var/run/named /var/log/bind /run/named && \
    chown -R bind:bind /var/cache/bind /var/run/named /var/log/bind /etc/bind /run/named && \
    chmod 775 /var/cache/bind /var/run/named /var/log/bind /etc/bind /run/named

# 复制配置文件
COPY conf/ /etc/bind/
COPY generate_key.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate_key.sh

# 切换到bind用户
USER bind

EXPOSE 53/tcp 53/udp

ENTRYPOINT ["/usr/local/bin/generate_key.sh"]
CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD dig @localhost localhost || exit 1 