#!/bin/bash

# 设置错误时立即退出
set -e

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 错误处理函数
error_exit() {
    log "错误: $1"
    exit 1
}

# 检查命令是否成功执行
check_command() {
    if [ $? -ne 0 ]; then
        error_exit "$1"
    fi
}

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    error_exit "请使用root权限运行此脚本"
fi

# 检查系统要求
log "检查系统要求..."
if ! command -v apt-get &> /dev/null; then
    error_exit "此脚本仅支持Debian/Ubuntu系统"
fi

# 停止Redis服务
log "停止Redis服务..."
systemctl stop redis-server || true
pkill redis-server || true
sleep 2

# 检查Redis是否仍在运行
if pgrep redis-server > /dev/null; then
    error_exit "无法停止Redis进程"
fi

# 卸载Redis
log "卸载Redis..."
apt-get remove --purge redis-server -y
check_command "Redis卸载失败"
apt-get autoremove -y
check_command "自动清理失败"

# 删除Redis相关目录
log "清理Redis目录..."
for dir in /var/lib/redis/ /var/log/redis/ /var/run/redis/ /etc/redis/; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        check_command "无法删除目录 $dir"
    fi
done

# 更新包列表
log "更新包列表..."
apt-get update
check_command "包列表更新失败"

# 安装Redis
log "安装Redis..."
apt-get install -y redis-server
check_command "Redis安装失败"

# 创建必要的目录
log "创建Redis目录..."
for dir in /var/lib/redis /var/log/redis /var/run/redis /etc/redis; do
    mkdir -p "$dir"
    chown redis:redis "$dir"
    chmod 750 "$dir"
done

# 配置Redis
log "配置Redis..."
cat > /etc/redis/redis.conf << 'EOF'
bind 0.0.0.0
port 6379
daemonize no
supervised systemd
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
EOF

# 设置配置文件权限
log "设置Redis权限..."
chown redis:redis /etc/redis/redis.conf
chmod 640 /etc/redis/redis.conf

# 配置系统内存设置
log "配置系统内存设置..."
echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
sysctl vm.overcommit_memory=1
check_command "系统内存设置失败"

# 启动Redis服务
log "启动Redis服务..."
systemctl start redis-server
check_command "Redis服务启动失败"

# 等待服务启动
log "等待Redis服务启动..."
for i in {1..30}; do
    if systemctl is-active --quiet redis-server; then
        break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
        error_exit "Redis服务启动超时"
    fi
done

# 检查Redis状态
log "检查Redis状态..."
systemctl status redis-server
check_command "Redis服务状态异常"

# 检查Redis是否正在监听
log "检查Redis监听状态..."
if ! netstat -tuln | grep -q ":6379"; then
    error_exit "Redis未在端口6379上监听"
fi

# 测试Redis连接
log "测试Redis连接..."
redis-cli ping || error_exit "Redis连接测试失败"

# 测试Redis基本功能
log "测试Redis基本功能..."
redis-cli SET test "Hello Redis" || error_exit "Redis写入测试失败"
redis-cli GET test || error_exit "Redis读取测试失败"

log "Redis配置完成！"
log "主机: localhost"
log "端口: 6379"
log "配置文件: /etc/redis/redis.conf"
log "数据目录: /var/lib/redis"
log "日志文件: /var/log/redis/redis-server.log"
log "PID文件: /var/run/redis/redis-server.pid" 