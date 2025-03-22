#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 检查系统要求
echo "检查系统要求..."

# 检查操作系统
if [ -f /etc/debian_version ]; then
    echo -e "${GREEN}✓ Debian 系统检查通过${NC}"
else
    echo -e "${RED}× 该脚本仅支持 Debian 系统${NC}"
    exit 1
fi

# 检查Docker版本
if docker --version > /dev/null 2>&1; then
    docker_version=$(docker --version | awk '{print $3}' | cut -d'.' -f1)
    if [ "$docker_version" -ge "20" ]; then
        echo -e "${GREEN}✓ Docker版本检查通过${NC}"
    else
        echo -e "${RED}× Docker版本过低，请升级到20.0或更高版本${NC}"
        exit 1
    fi
else
    echo -e "${RED}× Docker未安装${NC}"
    exit 1
fi

# 检查Docker Compose版本
if docker-compose --version > /dev/null 2>&1; then
    compose_version=$(docker-compose --version | awk '{print $3}' | cut -d'.' -f1)
    if [ "$compose_version" -ge "2" ]; then
        echo -e "${GREEN}✓ Docker Compose版本检查通过${NC}"
    else
        echo -e "${RED}× Docker Compose版本过低，请升级到2.0或更高版本${NC}"
        exit 1
    fi
else
    echo -e "${RED}× Docker Compose未安装${NC}"
    exit 1
fi

# 检查系统资源
echo "检查系统资源..."

# 检查内存
total_mem=$(free -m | awk '/^Mem:/{print $2}')
if [ "$total_mem" -ge 2048 ]; then
    echo -e "${GREEN}✓ 内存大小满足要求 (${total_mem}MB)${NC}"
else
    echo -e "${RED}× 内存不足，建议至少2GB内存${NC}"
    exit 1
fi

# 检查磁盘空间
free_space=$(df -m / | awk 'NR==2 {print $4}')
if [ "$free_space" -ge 10240 ]; then
    echo -e "${GREEN}✓ 磁盘空间满足要求 (${free_space}MB可用)${NC}"
else
    echo -e "${RED}× 磁盘空间不足，建议至少10GB可用空间${NC}"
    exit 1
fi

# 检查必要的工具
echo "检查必要的工具..."
for tool in curl wget git lsof; do
    if command -v $tool > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $tool 已安装${NC}"
    else
        echo -e "${RED}× $tool 未安装${NC}"
        exit 1
    fi
done

# 检查防火墙规则
echo "检查防火墙规则..."
required_ports=(80 53 67 5432 6379)
for port in "${required_ports[@]}"; do
    if ! lsof -i :$port > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 端口 $port 可用${NC}"
    else
        echo -e "${RED}× 端口 $port 已被占用${NC}"
        exit 1
    fi
done

echo -e "\n${GREEN}所有检查通过！可以开始部署了。${NC}"
echo "运行以下命令开始部署："
echo "bash scripts/deploy.sh" 