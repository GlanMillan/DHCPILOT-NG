#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}开始更新环境变量...${NC}"

# 获取服务器IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# 生成随机密码和密钥
DB_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -hex 32)
RNDC_KEY=$(openssl rand -base64 24)

# 更新.env文件中的值
sed -i "s#APP_URL=http://your-server-ip#APP_URL=http://${SERVER_IP}#g" .env
sed -i "s#POSTGRES_PASSWORD=CHANGE_THIS_PASSWORD#POSTGRES_PASSWORD=${DB_PASSWORD}#g" .env
sed -i "s#JWT_SECRET=\$(openssl rand -hex 32)#JWT_SECRET=${JWT_SECRET}#g" .env
sed -i "s#BIND9_RNDC_KEY=\$(openssl rand -base64 24)#BIND9_RNDC_KEY=${RNDC_KEY}#g" .env
sed -i "s#CORS_ORIGINS=\[\"http://your-server-ip\"\]#CORS_ORIGINS=[\"http://${SERVER_IP}\"]#g" .env

# 更新BIND9服务配置
sed -i "s#BIND9_RNDC_HOST=localhost#BIND9_RNDC_HOST=${SERVER_IP}#g" .env

echo -e "${GREEN}环境变量已更新！请保存以下信息：${NC}"
echo -e "服务器IP: ${SERVER_IP}"
echo -e "数据库密码: ${DB_PASSWORD}"
echo -e "JWT密钥: ${JWT_SECRET}"
echo -e "RNDC密钥: ${RNDC_KEY}"

# 设置.env文件权限
chmod 600 .env

echo -e "\n${GREEN}配置完成！现在你可以运行以下命令来启动服务：${NC}"
echo -e "docker compose up -d" 