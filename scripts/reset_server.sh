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

# 清理dpkg statoverride
clean_statoverride() {
    log "清理dpkg statoverride..."
    
    # 删除所有statoverride记录
    dpkg-statoverride --list | while read line; do
        if [[ $line =~ ^/ ]]; then
            path=$(echo $line | awk '{print $1}')
            log "删除statoverride: $path"
            dpkg-statoverride --remove "$path" 2>/dev/null || true
        fi
    done
    
    # 特别处理Redis相关的statoverride
    for path in /var/lib/redis /var/log/redis /var/run/redis /etc/redis; do
        dpkg-statoverride --remove "$path" 2>/dev/null || true
    done
    
    # 特别处理PostgreSQL相关的statoverride
    for path in /var/lib/postgresql /var/log/postgresql /var/run/postgresql /etc/postgresql; do
        dpkg-statoverride --remove "$path" 2>/dev/null || true
    done
    
    # 特别处理BIND9相关的statoverride
    for path in /var/cache/bind /etc/bind /var/run/named; do
        dpkg-statoverride --remove "$path" 2>/dev/null || true
    done
    
    # 特别处理KEA相关的statoverride
    for path in /var/log/kea /etc/kea /var/run/kea; do
        dpkg-statoverride --remove "$path" 2>/dev/null || true
    done
}

# 停止服务
stop_services() {
    log "停止服务..."
    
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

# 卸载软件包
uninstall_packages() {
    log "卸载软件包..."
    
    # 卸载BIND9相关包
    if dpkg -l | grep -q "^ii  bind9 "; then
        apt-get remove -y bind9 bind9utils bind9-doc dns-root-data
        apt-get autoremove -y
    fi
    
    # 卸载KEA DHCP相关包
    if dpkg -l | grep -q "^ii  kea-dhcp4-server "; then
        apt-get remove -y kea-dhcp4-server kea-common
        apt-get autoremove -y
    fi
    
    # 卸载PostgreSQL相关包
    if dpkg -l | grep -q "^ii  postgresql "; then
        apt-get remove -y postgresql postgresql-contrib
        apt-get autoremove -y
    fi
    
    # 卸载Redis相关包
    if dpkg -l | grep -q "^ii  redis-server "; then
        apt-get remove -y redis-server redis-tools
        apt-get autoremove -y
    fi
}

# 清理配置文件
clean_configs() {
    log "清理配置文件..."
    
    # 清理BIND9配置
    rm -rf /etc/bind/* 2>/dev/null || true
    rm -rf /var/cache/bind/* 2>/dev/null || true
    
    # 清理KEA DHCP配置
    rm -rf /etc/kea/* 2>/dev/null || true
    
    # 清理PostgreSQL数据
    rm -rf /var/lib/postgresql/* 2>/dev/null || true
    rm -rf /var/log/postgresql/* 2>/dev/null || true
    
    # 清理Redis数据
    rm -rf /var/lib/redis/* 2>/dev/null || true
    rm -rf /var/log/redis/* 2>/dev/null || true
}

# 清理用户和组
clean_users() {
    log "清理用户和组..."
    
    # 删除kea用户和组
    if id "kea" &>/dev/null; then
        userdel -r kea
    fi
    if getent group "kea" >/dev/null; then
        groupdel kea
    fi
    
    # 删除postgres用户和组
    if id "postgres" &>/dev/null; then
        userdel -r postgres
    fi
    if getent group "postgres" >/dev/null; then
        groupdel postgres
    fi
    
    # 删除redis用户和组
    if id "redis" &>/dev/null; then
        userdel -r redis
    fi
    if getent group "redis" >/dev/null; then
        groupdel redis
    fi
}

# 清理Docker资源
clean_docker() {
    log "清理Docker资源..."
    
    if command -v docker &> /dev/null; then
        # 停止所有容器
        if [ "$(docker ps -aq)" ]; then
            docker stop $(docker ps -aq)
            docker rm $(docker ps -aq)
        fi
        
        # 删除所有镜像
        if [ "$(docker images -q)" ]; then
            docker rmi $(docker images -q)
        fi
        
        # 清理卷和网络
        docker volume prune -f
        docker network prune -f
    fi
}

# 禁用系统服务
disable_services() {
    log "禁用系统服务..."
    
    for service in named kea-dhcp4-server postgresql redis-server; do
        if systemctl is-enabled $service &>/dev/null; then
            systemctl disable $service
        fi
    done
}

# 重置防火墙规则
reset_firewall() {
    log "重置防火墙规则..."
    
    if command -v ufw &> /dev/null; then
        ufw --force reset
        ufw --force disable
    fi
}

# 主函数
main() {
    log "开始重置服务器..."
    
    # 确认操作
    read -p "此操作将删除所有配置和数据，是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "操作已取消"
        exit 1
    fi
    
    # 执行清理操作
    stop_services
    clean_docker
    clean_configs
    clean_users
    clean_statoverride
    disable_services
    reset_firewall
    uninstall_packages
    
    log "服务器重置完成"
}

# 执行主函数
main 