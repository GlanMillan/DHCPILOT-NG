#!/bin/bash

# 设置错误处理
set -e

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 检查root权限
if [ "$EUID" -ne 0 ]; then 
    log "请使用root权限运行此脚本"
    exit 1
fi

# 生成RNDC密钥
log "生成RNDC密钥..."
rndc-confgen -a -c /etc/bind/rndc.key

# 设置权限
log "设置权限..."
chown bind:bind /etc/bind/rndc.key
chmod 640 /etc/bind/rndc.key

log "RNDC密钥生成完成" 