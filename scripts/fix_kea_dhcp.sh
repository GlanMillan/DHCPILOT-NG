#!/bin/bash

# 设置错误处理
set -e
trap 'echo "错误发生在第 $LINENO 行"; exit 1' ERR

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    log "错误：请使用root权限运行此脚本"
    exit 1
fi

# 配置变量
DB_USER="dhcp"
DB_PASSWORD="dhcp_password"
DB_NAME="dhcp_admin"

# 检查PostgreSQL服务状态
check_postgresql() {
    log "检查PostgreSQL服务状态..."
    if ! systemctl is-active --quiet postgresql; then
        log "错误：PostgreSQL服务未运行"
        exit 1
    fi
}

# 检查数据库是否存在
check_database() {
    log "检查数据库是否存在..."
    if ! su - postgres -c "psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME"; then
        log "错误：数据库 $DB_NAME 不存在"
        exit 1
    fi
}

# 检查用户是否存在
check_user() {
    log "检查数据库用户是否存在..."
    if ! su - postgres -c "psql -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'\"" | grep -q 1; then
        log "错误：数据库用户 $DB_USER 不存在"
        exit 1
    fi
}

# 初始化KEA DHCP数据库
init_kea_database() {
    log "初始化KEA DHCP数据库..."
    if ! kea-dhcp4-db-init -u $DB_USER -p $DB_PASSWORD -n $DB_NAME -h localhost; then
        log "错误：KEA DHCP数据库初始化失败"
        exit 1
    fi
}

# 检查KEA DHCP配置
check_kea_config() {
    log "检查KEA DHCP配置..."
    if ! kea-dhcp4 -t /etc/kea/kea-dhcp4.conf; then
        log "错误：KEA DHCP配置文件有语法错误"
        exit 1
    fi
}

# 重启KEA DHCP服务
restart_kea_service() {
    log "重启KEA DHCP服务..."
    systemctl restart kea-dhcp4-server
    sleep 5
    
    if ! systemctl is-active --quiet kea-dhcp4-server; then
        log "错误：KEA DHCP服务启动失败"
        systemctl status kea-dhcp4-server
        exit 1
    fi
}

# 主程序
main() {
    log "开始修复KEA DHCP服务..."
    
    # 检查服务状态
    check_postgresql
    check_database
    check_user
    
    # 初始化数据库
    init_kea_database
    
    # 检查配置
    check_kea_config
    
    # 重启服务
    restart_kea_service
    
    log "KEA DHCP服务修复完成"
}

# 执行主程序
main 