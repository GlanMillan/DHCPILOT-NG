#!/bin/bash

# 设置错误处理
set -e

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 错误处理函数
error() {
    log "错误: $1"
    exit 1
}

# 检查root权限
if [ "$EUID" -ne 0 ]; then 
    error "请使用root权限运行此脚本"
fi

# 预处理：清理statoverride
preprocess() {
    log "预处理：清理statoverride..."
    
    # 删除Redis的特定statoverride记录
    log "删除Redis的statoverride记录..."
    dpkg-statoverride --remove /etc/redis/redis.conf 2>/dev/null || true
    
    # 删除所有Redis相关的statoverride
    for path in /var/lib/redis /var/log/redis /var/run/redis /etc/redis; do
        dpkg-statoverride --remove "$path" 2>/dev/null || true
    done
    
    # 删除所有PostgreSQL相关的statoverride
    for path in /var/lib/postgresql /var/log/postgresql /var/run/postgresql /etc/postgresql; do
        dpkg-statoverride --remove "$path" 2>/dev/null || true
    done
    
    # 删除所有BIND9相关的statoverride
    for path in /var/cache/bind /etc/bind /var/run/named; do
        dpkg-statoverride --remove "$path" 2>/dev/null || true
    done
    
    # 删除所有KEA相关的statoverride
    for path in /var/log/kea /etc/kea /var/run/kea; do
        dpkg-statoverride --remove "$path" 2>/dev/null || true
    done
    
    # 删除所有statoverride记录
    dpkg-statoverride --list | while read line; do
        if [[ $line =~ ^/ ]]; then
            path=$(echo $line | awk '{print $1}')
            log "删除statoverride: $path"
            dpkg-statoverride --remove "$path" 2>/dev/null || true
        fi
    done
}

# 检查系统要求
check_requirements() {
    log "检查系统要求..."
    
    # 检查操作系统
    if [ ! -f /etc/debian_version ]; then
        error "此脚本仅支持Debian系统"
    fi
    
    # 检查内存
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ $total_mem -lt 2048 ]; then
        error "系统内存不足，至少需要2GB内存"
    fi
    
    # 检查磁盘空间
    free_space=$(df -m / | awk 'NR==2 {print $4}')
    if [ $free_space -lt 10240 ]; then
        error "磁盘空间不足，至少需要10GB可用空间"
    fi
}

# 停止现有服务
stop_services() {
    log "停止现有服务..."
    
    # 停止Docker服务
    if systemctl is-active --quiet docker; then
        log "停止Docker服务..."
        systemctl stop docker
    fi
    
    # 停止BIND9服务
    if systemctl is-active --quiet named; then
        log "停止BIND9服务..."
        systemctl stop named
    fi
    
    # 停止KEA DHCP服务
    if systemctl is-active --quiet kea-dhcp4-server; then
        log "停止KEA DHCP服务..."
        systemctl stop kea-dhcp4-server
    fi
    
    # 停止PostgreSQL服务
    if systemctl is-active --quiet postgresql; then
        log "停止PostgreSQL服务..."
        systemctl stop postgresql
    fi
    
    # 停止Redis服务
    if systemctl is-active --quiet redis-server; then
        log "停止Redis服务..."
        systemctl stop redis-server
    fi
}

# 安装必要的软件包
install_packages() {
    log "安装必要的软件包..."
    
    # 更新软件包列表
    apt-get update
    
    # 安装BIND9
    log "安装 bind9..."
    apt-get install -y bind9 bind9utils bind9-doc dns-root-data
    
    # 安装KEA DHCP
    log "安装 kea-dhcp4-server..."
    apt-get install -y kea-dhcp4-server kea-common
    
    # 安装PostgreSQL
    log "安装 postgresql..."
    apt-get install -y postgresql postgresql-contrib
    
    # 安装Redis
    log "安装 redis-server..."
    apt-get install -y redis-server redis-tools
    
    # 安装其他工具
    apt-get install -y curl wget net-tools
}

# 配置PostgreSQL
configure_postgresql() {
    log "配置PostgreSQL..."
    
    # 启动PostgreSQL服务
    systemctl start postgresql
    systemctl enable postgresql
    
    # 等待PostgreSQL启动
    sleep 5
    
    # 创建postgres用户（如果不存在）
    if ! getent passwd postgres >/dev/null; then
        log "创建postgres用户..."
        useradd -r -s /bin/bash postgres
        mkdir -p /var/lib/postgresql
        chown postgres:postgres /var/lib/postgresql
    fi
    
    # 初始化PostgreSQL数据库（如果未初始化）
    if [ ! -d "/var/lib/postgresql/15/main" ]; then
        log "初始化PostgreSQL数据库..."
        mkdir -p /var/lib/postgresql/15/main
        chown postgres:postgres /var/lib/postgresql/15/main
        su - postgres -c "initdb -D /var/lib/postgresql/15/main"
    fi
    
    # 创建数据库和用户
    log "创建数据库和用户..."
    su - postgres -c "psql -c \"CREATE USER dhcp WITH PASSWORD 'dhcp_password';\" || true"
    su - postgres -c "psql -c \"CREATE DATABASE dhcp_admin OWNER dhcp;\" || true"
    su - postgres -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE dhcp_admin TO dhcp;\" || true"
    
    # 配置PostgreSQL允许远程连接
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
    echo "host    all             all             0.0.0.0/0               md5" >> /etc/postgresql/*/main/pg_hba.conf
    
    # 重启PostgreSQL服务
    systemctl restart postgresql
}

# 配置BIND9
configure_bind9() {
    log "配置BIND9..."
    
    # 创建必要的目录
    mkdir -p /etc/bind
    mkdir -p /var/cache/bind
    
    # 复制配置文件
    log "复制BIND9配置文件..."
    cp config/bind9/named.conf /etc/bind/
    cp config/bind9/named.conf.options /etc/bind/
    cp config/bind9/named.conf.local /etc/bind/
    cp config/bind9/zones/* /etc/bind/
    
    # 设置权限
    chown -R bind:bind /etc/bind
    chown -R bind:bind /var/cache/bind
    chmod 644 /etc/bind/named.conf
    chmod 644 /etc/bind/named.conf.options
    chmod 644 /etc/bind/named.conf.local
    chmod 644 /etc/bind/zones/*
    
    # 启动BIND9服务
    systemctl enable named
    systemctl start named
}

# 配置KEA DHCP
configure_kea() {
    log "配置KEA DHCP..."
    
    # 创建kea用户和组
    log "创建kea用户和组..."
    useradd -r -s /bin/false kea || true
    groupadd -r kea || true
    
    # 创建必要的目录
    mkdir -p /etc/kea
    mkdir -p /var/log/kea
    
    # 复制配置文件
    log "复制KEA DHCP配置文件..."
    cp config/kea/kea-dhcp4.conf /etc/kea/
    
    # 设置权限
    chown -R kea:kea /etc/kea
    chown -R kea:kea /var/log/kea
    chmod 644 /etc/kea/kea-dhcp4.conf
    
    # 启动KEA DHCP服务
    systemctl start kea-dhcp4-server
    systemctl enable kea-dhcp4-server
}

# 配置Redis
configure_redis() {
    log "配置Redis..."
    
    # 配置Redis允许远程连接
    sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
    echo "requirepass dhcp_redis_password" >> /etc/redis/redis.conf
    
    # 启动Redis服务
    systemctl start redis-server
    systemctl enable redis-server
}

# 生成环境配置文件
generate_env() {
    log "生成环境配置文件..."
    
    # 获取服务器IP地址
    read -p "请输入服务器IP地址（用于KEA_CTRL_AGENT_URL配置）：" SERVER_IP
    
    # 生成.env文件
    cat > .env << EOF
# 应用配置
APP_NAME=DHCPLIOT-NG
APP_ENV=production
APP_DEBUG=false
APP_URL=http://${SERVER_IP}
APP_PORT=8000

# 数据库配置
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dhcp_admin
DB_USER=dhcp
DB_PASSWORD=dhcp_password

# Redis配置
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=dhcp_redis_password

# JWT配置
JWT_SECRET=your_jwt_secret_key
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30

# API配置
API_KEY=your_api_key
API_RATE_LIMIT=100

# KEA DHCP配置
KEA_CTRL_AGENT_URL=http://${SERVER_IP}:8000
EOF
}

# 主函数
main() {
    log "开始配置服务器..."
    
    # 检查系统要求
    check_requirements
    
    # 预处理：清理statoverride
    preprocess
    
    # 停止现有服务
    stop_services
    
    # 安装软件包
    install_packages
    
    # 配置服务
    configure_postgresql
    configure_bind9
    configure_kea
    configure_redis
    
    # 生成环境配置
    generate_env
    
    log "服务器配置完成"
}

# 执行主函数
main