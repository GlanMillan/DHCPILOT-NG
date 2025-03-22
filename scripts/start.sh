#!/bin/bash

# 创建必要的目录
mkdir -p kea/conf bind9/conf bind9/zones nginx/conf

# 创建Kea配置文件
cat > kea/conf/kea-dhcp4.conf << 'EOL'
{
    "Dhcp4": {
        "interfaces-config": {
            "interfaces": [ "*" ]
        },
        "control-socket": {
            "socket-type": "unix",
            "socket-name": "/tmp/kea4-ctrl-socket"
        },
        "lease-database": {
            "type": "mysql",
            "name": "dhcp",
            "user": "dhcp",
            "password": "dhcp",
            "host": "db",
            "port": 3306
        },
        "valid-lifetime": 4000,
        "renew-timer": 1000,
        "rebind-timer": 2000,
        "subnet4": [
            {
                "subnet": "192.168.1.0/24",
                "pools": [ { "pool": "192.168.1.100 - 192.168.1.200" } ],
                "option-data": [
                    {
                        "name": "routers",
                        "data": "192.168.1.1"
                    },
                    {
                        "name": "domain-name-servers",
                        "data": "192.168.1.1"
                    }
                ]
            }
        ]
    }
}
EOL

# 创建Kea控制代理配置文件
cat > kea/conf/kea-ctrl-agent.conf << 'EOL'
{
    "Control-agent": {
        "http-host": "0.0.0.0",
        "http-port": 8000,
        "control-sockets": {
            "dhcp4": {
                "socket-type": "unix",
                "socket-name": "/tmp/kea4-ctrl-socket"
            }
        }
    }
}
EOL

# 创建supervisord配置文件
cat > kea/supervisord.conf << 'EOL'
[supervisord]
nodaemon=true

[program:kea-dhcp4]
command=kea-dhcp4 -c /etc/kea/kea-dhcp4.conf
autostart=true
autorestart=true
stderr_logfile=/var/log/kea-dhcp4.err.log
stdout_logfile=/var/log/kea-dhcp4.out.log

[program:kea-ctrl-agent]
command=kea-ctrl-agent -c /etc/kea/kea-ctrl-agent.conf
autostart=true
autorestart=true
stderr_logfile=/var/log/kea-ctrl-agent.err.log
stdout_logfile=/var/log/kea-ctrl-agent.out.log
EOL

# 创建BIND9配置文件
cat > bind9/conf/named.conf << 'EOL'
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";

logging {
    channel default_log {
        file "/var/log/bind/named.log" versions 3 size 5m;
        severity info;
        print-category yes;
        print-severity yes;
        print-time yes;
    };
    category default { default_log; };
};
EOL

cat > bind9/conf/named.conf.options << 'EOL'
options {
    directory "/var/cache/bind";
    listen-on { 0.0.0.0; };
    listen-on-v6 { ::1; };
    allow-query { localhost; };
    recursion yes;
    allow-recursion { localhost; };
    dnssec-enable yes;
    dnssec-validation yes;
    dnssec-lookaside auto;
    auth-nxdomain no;
    version "not disclosed";
};

controls {
    inet 0.0.0.0 port 953
        allow { 0.0.0.0/0; }
        keys { "rndc-key"; };
};
EOL

cat > bind9/conf/named.conf.local << 'EOL'
zone "example.com" {
    type master;
    file "/etc/bind/zones/example.com.zone";
    allow-transfer { none; };
    allow-query { any; };
};
EOL

# 创建Nginx配置文件
cat > nginx/conf/nginx.conf << 'EOL'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # 安全头部
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    server {
        listen 80;
        server_name localhost;

        # Web应用
        location / {
            proxy_pass http://web:8000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }

        # Kea控制接口
        location /kea/ {
            proxy_pass http://kea:8000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
EOL

# 设置权限
chmod 755 kea/conf bind9/conf bind9/zones nginx/conf

# 停止现有服务
docker compose down

# 删除现有镜像
docker rmi dhcpilot-kea dhcpilot-bind9 dhcpilot-nginx

# 重新构建和启动
docker compose up -d --build

# 等待数据库启动
sleep 10

# 运行数据库迁移
docker compose exec web alembic upgrade head

echo "服务已启动！"
echo "Web界面: http://localhost"
echo "Kea DHCP控制: http://localhost/kea/"
echo "BIND9 DNS服务: localhost:53" 