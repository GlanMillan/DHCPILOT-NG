#!/bin/bash

# 确保脚本在错误时停止执行
set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}开始部署DHCP管理系统...${NC}"

# 1. 检查必要的软件
echo "检查必要的软件..."
for cmd in docker docker-compose git; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}错误: $cmd 未安装${NC}"
        exit 1
    fi
done

# 2. 创建必要的目录
echo "创建必要的目录..."
mkdir -p docker/{nginx,backend,frontend,kea,bind9}/{conf,logs}
mkdir -p docker/bind9/zones

# 3. 设置环境变量
echo "设置环境变量..."
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "已从.env.example创建.env文件，请检查并修改配置"
    else
        echo -e "${RED}错误: 未找到.env.example文件${NC}"
        exit 1
    fi
fi

# 4. 检查必要的端口
echo "检查端口占用情况..."
for port in 80 53 67 5432 6379; do
    if lsof -i :$port > /dev/null 2>&1; then
        echo -e "${RED}警告: 端口 $port 已被占用${NC}"
        echo "请确保以下端口可用："
        echo "80 (HTTP)"
        echo "53 (DNS)"
        echo "67 (DHCP)"
        echo "5432 (PostgreSQL)"
        echo "6379 (Redis)"
        exit 1
    fi
done

# 5. 配置Docker网络
echo "配置Docker网络..."
docker network create dhcp-network 2>/dev/null || true
docker network create internal --internal 2>/dev/null || true

# 6. 构建和启动服务
echo "构建和启动服务..."
docker-compose build --no-cache
docker-compose up -d

# 7. 检查服务状态
echo "检查服务状态..."
sleep 10  # 等待服务启动
docker-compose ps

# 8. 检查服务健康状态
echo "检查服务健康状态..."
for service in nginx web db kea bind9 redis; do
    health_status=$(docker-compose ps $service | grep "Up" || echo "")
    if [ -z "$health_status" ]; then
        echo -e "${RED}警告: $service 服务可能未正常运行${NC}"
    else
        echo -e "${GREEN}$service 服务运行正常${NC}"
    fi
done

# 9. 显示访问信息
echo -e "\n${GREEN}部署完成！${NC}"
echo "您可以通过以下地址访问服务："
echo "Web界面: http://$(hostname -I | awk '{print $1}')"
echo "API文档: http://$(hostname -I | awk '{print $1}')/api/docs"
echo "DHCP服务: $(hostname -I | awk '{print $1}'):67"
echo "DNS服务: $(hostname -I | awk '{print $1}'):53"

# 10. 显示日志访问方式
echo -e "\n查看服务日志："
echo "整体日志: docker-compose logs -f"
echo "单个服务日志: docker-compose logs -f [服务名]"
echo "例如: docker-compose logs -f web" 