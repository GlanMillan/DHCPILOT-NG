#!/bin/bash

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 设置变量
BIND9_CONF_DIR="/etc/bind"
BIND9_ZONES_DIR="/var/cache/bind"
BIND9_LOGS_DIR="/var/log/bind"
KEA_CONF_DIR="/etc/kea"
KEA_LOGS_DIR="/var/log/kea"
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="dhcp_admin"
DB_USER="dhcp"
DB_PASSWORD="dhcp_password"

# 安装必要的软件包
echo "正在安装必要的软件包..."
apt-get update
apt-get install -y bind9 bind9utils kea-dhcp4-server kea-common kea-dhcp4-server postgresql postgresql-contrib

# 配置BIND9
echo "正在配置BIND9..."
mkdir -p $BIND9_ZONES_DIR $BIND9_LOGS_DIR
chown -R bind:bind $BIND9_ZONES_DIR $BIND9_LOGS_DIR
chmod 775 $BIND9_ZONES_DIR $BIND9_LOGS_DIR

# 生成RNDC密钥
rndc-confgen -a -c $BIND9_CONF_DIR/rndc.key
chown bind:bind $BIND9_CONF_DIR/rndc.key
chmod 640 $BIND9_CONF_DIR/rndc.key

# 配置Kea DHCP
echo "正在配置Kea DHCP..."
mkdir -p $KEA_LOGS_DIR
chown -R kea:kea $KEA_LOGS_DIR
chmod 775 $KEA_LOGS_DIR

# 创建数据库和用户
echo "正在配置数据库..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"

# 复制配置文件
echo "正在复制配置文件..."
cp bind9/conf/named.conf $BIND9_CONF_DIR/
cp bind9/conf/named.conf.options $BIND9_CONF_DIR/
cp bind9/conf/named.conf.local $BIND9_CONF_DIR/
cp bind9/conf/named.conf.default-zones $BIND9_CONF_DIR/
cp kea/conf/kea-dhcp4.conf $KEA_CONF_DIR/

# 设置权限
chown -R bind:bind $BIND9_CONF_DIR
chown -R kea:kea $KEA_CONF_DIR
chmod 644 $BIND9_CONF_DIR/*.conf
chmod 644 $KEA_CONF_DIR/*.conf

# 重启服务
echo "正在重启服务..."
systemctl restart bind9
systemctl restart kea-dhcp4-server
systemctl enable bind9
systemctl enable kea-dhcp4-server

# 检查服务状态
echo "检查服务状态..."
systemctl status bind9
systemctl status kea-dhcp4-server

echo "部署完成！"
echo "请确保更新.env文件中的以下配置："
echo "KEA_CTRL_AGENT_URL=http://localhost:8000"
echo "BIND9_RNDC_KEY=$(cat $BIND9_CONF_DIR/rndc.key | grep secret | awk '{print $2}')" 