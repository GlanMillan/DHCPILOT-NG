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

# 停止BIND9服务
log "停止BIND9服务..."
systemctl stop bind9 || true
pkill named || true
sleep 2

# 检查BIND9是否仍在运行
if pgrep named > /dev/null; then
    error_exit "无法停止BIND9进程"
fi

# 卸载BIND9
log "卸载BIND9..."
apt-get remove --purge bind9 bind9utils -y
check_command "BIND9卸载失败"
apt-get autoremove -y
check_command "自动清理失败"

# 删除BIND9相关目录
log "清理BIND9目录..."
for dir in /etc/bind/ /var/cache/bind/ /var/run/named/; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        check_command "无法删除目录 $dir"
    fi
done

# 更新包列表
log "更新包列表..."
apt-get update
check_command "包列表更新失败"

# 安装BIND9
log "安装BIND9..."
apt-get install -y bind9 bind9utils
check_command "BIND9安装失败"

# 创建必要的目录
log "创建BIND9目录..."
for dir in /var/cache/bind /var/run/named /etc/bind/zones; do
    mkdir -p "$dir"
    chown bind:bind "$dir"
    chmod 750 "$dir"
done

# 配置BIND9
log "配置BIND9..."
cat > /etc/bind/named.conf.options << 'EOF'
options {
        directory "/var/cache/bind";
        listen-on { any; };
        listen-on-v6 { any; };
        allow-query { any; };
        recursion yes;
        dnssec-validation auto;
        auth-nxdomain no;
        version "not available";
        forwarders {
                223.5.5.5;
                8.8.8.8;
        };
};
EOF

# 创建本地配置文件
log "创建本地配置文件..."
cat > /etc/bind/named.conf.local << 'EOF'
zone "example.com" {
        type master;
        file "/etc/bind/zones/db.example.com";
        allow-transfer { none; };
        allow-query { any; };
};
EOF

# 创建示例区域文件
log "创建示例区域文件..."
cat > /etc/bind/zones/db.example.com << 'EOF'
$TTL    604800
@       IN      SOA     ns1.example.com. admin.example.com. (
                     2024032701         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.example.com.
ns1     IN      A       127.0.0.1
www     IN      A       192.168.1.100
mail    IN      A       192.168.1.101
ftp     IN      A       192.168.1.102
EOF

# 设置文件权限
log "设置BIND9权限..."
chown -R bind:bind /etc/bind
chmod 640 /etc/bind/named.conf.options
chmod 640 /etc/bind/named.conf.local
chmod 640 /etc/bind/zones/db.example.com

# 检查配置文件语法
log "检查配置文件语法..."
named-checkconf /etc/bind/named.conf
check_command "BIND9配置文件语法错误"

# 检查区域文件语法
log "检查区域文件语法..."
named-checkzone example.com /etc/bind/zones/db.example.com
check_command "区域文件语法错误"

# 启动BIND9服务
log "启动BIND9服务..."
systemctl start bind9
check_command "BIND9服务启动失败"

# 等待服务启动
log "等待BIND9服务启动..."
for i in {1..30}; do
    if systemctl is-active --quiet bind9; then
        break
    fi
    sleep 1
    if [ $i -eq 30 ]; then
        error_exit "BIND9服务启动超时"
    fi
done

# 检查BIND9状态
log "检查BIND9状态..."
systemctl status bind9
check_command "BIND9服务状态异常"

# 检查BIND9是否正在监听
log "检查BIND9监听状态..."
if ! netstat -tuln | grep -q ":53"; then
    error_exit "BIND9未在端口53上监听"
fi

# 测试DNS解析
log "测试DNS解析..."
dig @localhost example.com || error_exit "DNS解析测试失败"
dig @localhost www.example.com || error_exit "DNS解析测试失败"
dig @localhost mail.example.com || error_exit "DNS解析测试失败"
dig @localhost ftp.example.com || error_exit "DNS解析测试失败"

log "BIND9配置完成！"
log "主机: localhost"
log "端口: 53"
log "配置文件: /etc/bind/named.conf"
log "区域文件: /etc/bind/zones/db.example.com"
log "缓存目录: /var/cache/bind"
log "PID文件: /var/run/named/named.pid" 
