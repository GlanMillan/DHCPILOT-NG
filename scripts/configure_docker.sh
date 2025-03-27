#!/bin/bash

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 检查Docker是否已安装
if ! command -v docker &> /dev/null; then
    echo "正在安装Docker..."
    apt update
    apt install -y docker.io docker-compose
    systemctl enable docker
    systemctl start docker
fi

# 检查服务是否正在运行
if docker compose ps | grep -q "Up"; then
    echo "正在停止Docker服务..."
    docker compose down
fi

# 检查.env文件是否存在
if [ ! -f .env ]; then
    echo "错误：.env文件不存在，请先运行configure_server.sh"
    exit 1
fi

# 启动Web服务
echo "启动Web服务..."
docker compose up -d

# 等待服务就绪
echo "等待服务就绪..."
sleep 10

# 检查服务状态
echo "检查服务状态..."
docker compose ps

echo "Docker服务配置完成！"
echo "Web服务已启动，请访问 http://localhost 或 http://服务器IP" 