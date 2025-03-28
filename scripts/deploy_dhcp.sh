#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 打印带颜色的信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    print_error "请使用root权限运行此脚本"
    exit 1
fi

# 获取用户输入
read -p "请输入服务器IP地址 (例如: 192.168.85.135): " SERVER_IP
read -p "请输入数据库root密码: " DB_ROOT_PASSWORD
read -p "请输入KEA数据库用户名 (默认: kea): " KEA_DB_USER
KEA_DB_USER=${KEA_DB_USER:-kea}
read -p "请输入KEA数据库密码: " KEA_DB_PASSWORD
read -p "请输入DHCP子网 (例如: 192.168.85.0/24): " DHCP_SUBNET
read -p "请输入DHCP地址池起始IP (例如: 192.168.85.100): " DHCP_POOL_START
read -p "请输入DHCP地址池结束IP (例如: 192.168.85.200): " DHCP_POOL_END
read -p "请输入默认网关IP (例如: 192.168.85.1): " DEFAULT_GATEWAY

# 更新系统
print_info "正在更新系统..."
apt-get update && apt-get upgrade -y

# 安装必要的软件包
print_info "正在安装必要的软件包..."
apt-get install -y kea-common kea-dhcp4-server mariadb-server mariadb-client

# 配置MariaDB
print_info "正在配置MariaDB..."
systemctl start mariadb
systemctl enable mariadb

# 设置MariaDB root密码
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';"

# 创建KEA数据库和用户
print_info "正在创建KEA数据库和用户..."
mysql -u root -p"${DB_ROOT_PASSWORD}" << EOF
CREATE DATABASE IF NOT EXISTS kea;
CREATE USER IF NOT EXISTS '${KEA_DB_USER}'@'localhost' IDENTIFIED BY '${KEA_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON kea.* TO '${KEA_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# 创建KEA数据库表
print_info "正在创建KEA数据库表..."
mysql -u root -p"${DB_ROOT_PASSWORD}" kea << EOF
CREATE TABLE IF NOT EXISTS schema_version (
    version INT PRIMARY KEY,
    minor INT
);

CREATE TABLE IF NOT EXISTS lease4 (
    address INT UNSIGNED PRIMARY KEY,
    hwaddr VARBINARY(20),
    client_id VARBINARY(128),
    valid_lifetime INT UNSIGNED,
    expire TIMESTAMP,
    subnet_id INT UNSIGNED,
    fqdn_fwd BOOLEAN,
    fqdn_rev BOOLEAN,
    hostname VARCHAR(255),
    state INT UNSIGNED
);

CREATE TABLE IF NOT EXISTS lease6 (
    address VARCHAR(39) PRIMARY KEY,
    duid VARBINARY(128),
    valid_lifetime INT UNSIGNED,
    expire TIMESTAMP,
    subnet_id INT UNSIGNED,
    pref_lifetime INT UNSIGNED,
    lease_type INT,
    iaid INT UNSIGNED,
    prefix_len INT UNSIGNED,
    fqdn_fwd BOOLEAN,
    fqdn_rev BOOLEAN,
    hostname VARCHAR(255),
    hwaddr VARBINARY(20),
    hwtype SMALLINT UNSIGNED,
    hwaddr_source INT,
    state INT UNSIGNED
);

CREATE TABLE IF NOT EXISTS lease_hwaddr_source (
    hwaddr_source INT PRIMARY KEY,
    name VARCHAR(40)
);

CREATE TABLE IF NOT EXISTS lease_state (
    state INT UNSIGNED PRIMARY KEY,
    name VARCHAR(40)
);

INSERT INTO lease_hwaddr_source VALUES (0, 'HWADDR_SOURCE_UNKNOWN');
INSERT INTO lease_hwaddr_source VALUES (1, 'HWADDR_SOURCE_DOCSIS_MODEM');
INSERT INTO lease_hwaddr_source VALUES (2, 'HWADDR_SOURCE_ETHERNET_HADDR');
INSERT INTO lease_hwaddr_source VALUES (3, 'HWADDR_SOURCE_DOCSIS_CMTS');
INSERT INTO lease_hwaddr_source VALUES (4, 'HWADDR_SOURCE_DOCSIS_MODEM_BACKUP');
INSERT INTO lease_hwaddr_source VALUES (5, 'HWADDR_SOURCE_DOCSIS_CMTS_BACKUP');
INSERT INTO lease_hwaddr_source VALUES (6, 'HWADDR_SOURCE_DOCSIS_MODEM_CPE');
INSERT INTO lease_hwaddr_source VALUES (7, 'HWADDR_SOURCE_DOCSIS_CMTS_CPE');
INSERT INTO lease_hwaddr_source VALUES (8, 'HWADDR_SOURCE_DOCSIS_MODEM_TAIL');
INSERT INTO lease_hwaddr_source VALUES (9, 'HWADDR_SOURCE_DOCSIS_CMTS_TAIL');
INSERT INTO lease_hwaddr_source VALUES (10, 'HWADDR_SOURCE_DOCSIS_MODEM_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (11, 'HWADDR_SOURCE_DOCSIS_CMTS_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (12, 'HWADDR_SOURCE_DOCSIS_MODEM_TAIL_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (13, 'HWADDR_SOURCE_DOCSIS_CMTS_TAIL_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (14, 'HWADDR_SOURCE_DOCSIS_MODEM_CPE_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (15, 'HWADDR_SOURCE_DOCSIS_CMTS_CPE_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (16, 'HWADDR_SOURCE_DOCSIS_MODEM_DEFINED_CMTS');
INSERT INTO lease_hwaddr_source VALUES (17, 'HWADDR_SOURCE_DOCSIS_CMTS_DEFINED_MODEM');
INSERT INTO lease_hwaddr_source VALUES (18, 'HWADDR_SOURCE_DOCSIS_MODEM_DEFINED_CMTS_CPE');
INSERT INTO lease_hwaddr_source VALUES (19, 'HWADDR_SOURCE_DOCSIS_CMTS_DEFINED_MODEM_CPE');
INSERT INTO lease_hwaddr_source VALUES (20, 'HWADDR_SOURCE_DOCSIS_MODEM_DEFINED_CMTS_TAIL');
INSERT INTO lease_hwaddr_source VALUES (21, 'HWADDR_SOURCE_DOCSIS_CMTS_DEFINED_MODEM_TAIL');
INSERT INTO lease_hwaddr_source VALUES (22, 'HWADDR_SOURCE_DOCSIS_MODEM_DEFINED_CMTS_TAIL_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (23, 'HWADDR_SOURCE_DOCSIS_CMTS_DEFINED_MODEM_TAIL_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (24, 'HWADDR_SOURCE_DOCSIS_MODEM_DEFINED_CMTS_CPE_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (25, 'HWADDR_SOURCE_DOCSIS_CMTS_DEFINED_MODEM_CPE_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (26, 'HWADDR_SOURCE_DOCSIS_MODEM_DEFINED_CMTS_CPE_DEFINED_TAIL');
INSERT INTO lease_hwaddr_source VALUES (27, 'HWADDR_SOURCE_DOCSIS_CMTS_DEFINED_MODEM_CPE_DEFINED_TAIL');
INSERT INTO lease_hwaddr_source VALUES (28, 'HWADDR_SOURCE_DOCSIS_MODEM_DEFINED_CMTS_CPE_DEFINED_TAIL_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (29, 'HWADDR_SOURCE_DOCSIS_CMTS_DEFINED_MODEM_CPE_DEFINED_TAIL_DEFINED');
INSERT INTO lease_hwaddr_source VALUES (30, 'HWADDR_SOURCE_DOCSIS_MODEM_DEFINED_CMTS_CPE_DEFINED_TAIL_DEFINED_MODEM');
INSERT INTO lease_hwaddr_source VALUES (31, 'HWADDR_SOURCE_DOCSIS_CMTS_DEFINED_MODEM_CPE_DEFINED_TAIL_DEFINED_CMTS');

INSERT INTO lease_state VALUES (0, 'STATE_DEFAULT');
INSERT INTO lease_state VALUES (1, 'STATE_DECLINED');
INSERT INTO lease_state VALUES (2, 'STATE_EXPIRED_RECLAIMED');
INSERT INTO lease_state VALUES (3, 'STATE_DOOMED');
EOF

# 创建KEA配置目录
print_info "正在创建KEA配置目录..."
mkdir -p /etc/kea
chown -R kea:kea /etc/kea
chmod 755 /etc/kea

# 创建KEA配置文件
print_info "正在创建KEA配置文件..."
cat > /etc/kea/kea-dhcp4.conf << EOF
{
    "Dhcp4": {
        "interfaces-config": {
            "interfaces": [ "ens33" ]
        },
        "control-socket": {
            "socket-type": "unix",
            "socket-name": "/tmp/kea4-ctrl-socket"
        },
        "lease-database": {
            "type": "mysql",
            "name": "kea",
            "user": "${KEA_DB_USER}",
            "password": "${KEA_DB_PASSWORD}",
            "host": "localhost",
            "port": 3306
        },
        "valid-lifetime": 4000,
        "renew-timer": 1000,
        "rebind-timer": 2000,
        "loggers": [
            {
                "name": "kea-dhcp4",
                "output_options": [
                    {
                        "output": "/var/log/kea/kea-dhcp4.log"
                    }
                ],
                "severity": "DEBUG"
            }
        ],
        "subnet4": [
            {
                "subnet": "${DHCP_SUBNET}",
                "pools": [ { "pool": "${DHCP_POOL_START} - ${DHCP_POOL_END}" } ],
                "option-data": [
                    {
                        "name": "routers",
                        "data": "${DEFAULT_GATEWAY}"
                    },
                    {
                        "name": "domain-name-servers",
                        "data": "${DEFAULT_GATEWAY}, 8.8.8.8"
                    }
                ]
            }
        ]
    }
}
EOF

# 设置配置文件权限
chown kea:kea /etc/kea/kea-dhcp4.conf
chmod 644 /etc/kea/kea-dhcp4.conf

# 创建日志目录
print_info "正在创建日志目录..."
mkdir -p /var/log/kea
chown -R kea:kea /var/log/kea
chmod 755 /var/log/kea
touch /var/log/kea/kea-dhcp4.log
chown kea:kea /var/log/kea/kea-dhcp4.log
chmod 644 /var/log/kea/kea-dhcp4.log

# 重启KEA服务
print_info "正在重启KEA服务..."
systemctl stop kea-dhcp4-server
pkill kea-dhcp4
systemctl start kea-dhcp4-server
systemctl enable kea-dhcp4-server

# 检查服务状态
print_info "正在检查服务状态..."
systemctl status kea-dhcp4-server

# 检查端口监听状态
print_info "正在检查端口监听状态..."
netstat -tuln | grep 67

print_info "部署完成！"
print_info "请检查以下内容："
print_info "1. KEA服务状态是否正常"
print_info "2. 是否正在监听67端口"
print_info "3. 数据库连接是否正常"
print_info "4. 日志文件是否正常记录" 