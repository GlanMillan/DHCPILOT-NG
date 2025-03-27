 # BIND9和KEA DHCP服务器安装指南

本文档提供了在Ubuntu 22.04 LTS服务器上安装和配置BIND9和KEA DHCP的详细步骤。

## 系统要求

- Ubuntu 22.04 LTS或更高版本
- 至少2GB RAM
- 至少20GB可用磁盘空间
- root或具有sudo权限的用户

## 1. 系统更新

首先更新系统包：

```bash
sudo apt update
sudo apt upgrade -y
```

## 2. 安装BIND9

### 2.1 安装BIND9软件包

```bash
sudo apt install -y bind9 bind9utils
```

### 2.2 配置BIND9

1. 创建必要的目录：

```bash
sudo mkdir -p /var/cache/bind
sudo mkdir -p /var/log/bind
sudo chown -R bind:bind /var/cache/bind
sudo chown -R bind:bind /var/log/bind
sudo chmod 775 /var/cache/bind
sudo chmod 775 /var/log/bind
```

2. 生成RNDC密钥：

```bash
sudo rndc-confgen -a -c /etc/bind/rndc.key
sudo chown bind:bind /etc/bind/rndc.key
sudo chmod 640 /etc/bind/rndc.key
```

3. 配置BIND9主配置文件：

```bash
sudo nano /etc/bind/named.conf
```

添加以下内容：

```conf
include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
include "/etc/bind/rndc.key";

options {
    directory "/var/cache/bind";
    listen-on { 127.0.0.1; };
    listen-on-v6 { ::1; };
    allow-query { localhost; };
    recursion yes;
    dnssec-validation auto;
    auth-nxdomain no;
    version "not currently available";
};
```

4. 配置本地区域文件：

```bash
sudo nano /etc/bind/named.conf.local
```

添加以下内容：

```conf
zone "example.com" {
    type master;
    file "/etc/bind/zones/db.example.com";
    allow-transfer { none; };
    allow-query { any; };
};
```

5. 创建区域文件：

```bash
sudo mkdir -p /etc/bind/zones
sudo nano /etc/bind/zones/db.example.com
```

添加以下内容：

```conf
$TTL    604800
@       IN      SOA     ns1.example.com. admin.example.com. (
                     2024031001         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.example.com.
ns1     IN      A       127.0.0.1
```

6. 设置权限：

```bash
sudo chown -R bind:bind /etc/bind
sudo chmod 644 /etc/bind/*.conf
sudo chmod 644 /etc/bind/zones/*
```

7. 启动BIND9服务：

```bash
sudo systemctl enable bind9
sudo systemctl restart bind9
```

8. 检查BIND9状态：

```bash
sudo systemctl status bind9
```

## 3. 安装KEA DHCP

### 3.1 安装KEA DHCP软件包

```bash
sudo apt install -y kea-dhcp4-server kea-common
```

### 3.2 配置KEA DHCP

1. 创建日志目录：

```bash
sudo mkdir -p /var/log/kea
sudo chown -R kea:kea /var/log/kea
sudo chmod 775 /var/log/kea
```

2. 配置KEA DHCP：

```bash
sudo nano /etc/kea/kea-dhcp4.conf
```

添加以下内容：

```json
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
            "type": "postgresql",
            "name": "dhcp_admin",
            "user": "dhcp",
            "password": "dhcp_password",
            "host": "localhost",
            "port": 5432
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
                        "data": "192.168.1.1, 8.8.8.8"
                    }
                ]
            }
        ],
        "loggers": [
            {
                "name": "kea-dhcp4",
                "output_options": [
                    {
                        "output": "/var/log/kea/kea-dhcp4.log"
                    }
                ],
                "severity": "INFO"
            }
        ]
    }
}
```

3. 设置权限：

```bash
sudo chown -R kea:kea /etc/kea
sudo chmod 644 /etc/kea/*.conf
```

4. 启动KEA DHCP服务：

```bash
sudo systemctl enable kea-dhcp4-server
sudo systemctl restart kea-dhcp4-server
```

5. 检查KEA DHCP状态：

```bash
sudo systemctl status kea-dhcp4-server
```

## 4. 配置防火墙

如果服务器启用了防火墙，需要开放必要的端口：

```bash
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 67/udp
sudo ufw allow 68/udp
```

## 5. 验证安装

### 5.1 验证BIND9

```bash
# 检查BIND9是否正在运行
sudo systemctl status bind9

# 测试DNS解析
dig @localhost example.com
```

### 5.2 验证KEA DHCP

```bash
# 检查KEA DHCP是否正在运行
sudo systemctl status kea-dhcp4-server

# 检查日志
sudo tail -f /var/log/kea/kea-dhcp4.log
```

## 6. 故障排除

### 6.1 BIND9常见问题

1. 如果BIND9无法启动，检查日志：
```bash
sudo journalctl -u bind9
```

2. 检查配置文件语法：
```bash
sudo named-checkconf /etc/bind/named.conf
```

3. 检查区域文件语法：
```bash
sudo named-checkzone example.com /etc/bind/zones/db.example.com
```

### 6.2 KEA DHCP常见问题

1. 如果KEA DHCP无法启动，检查日志：
```bash
sudo journalctl -u kea-dhcp4-server
```

2. 检查配置文件语法：
```bash
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
```

## 7. 安全建议

1. 定期更新系统和软件包
2. 限制DNS查询来源
3. 使用强密码
4. 定期备份配置文件
5. 监控系统日志
6. 配置防火墙规则

## 8. 维护建议

1. 定期检查日志文件大小
2. 监控系统资源使用情况
3. 定期备份配置和数据
4. 保持系统更新
5. 定期检查服务状态