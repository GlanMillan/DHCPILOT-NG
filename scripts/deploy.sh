#!/bin/bash

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请使用root权限运行此脚本"
    exit 1
fi

# 设置脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

# 配置本地服务器
echo "开始配置本地服务器..."
bash scripts/configure_server.sh

# 检查本地服务器配置是否成功
if [ $? -ne 0 ]; then
    echo "本地服务器配置失败，请检查错误信息"
    exit 1
fi

# 配置Docker服务
echo "开始配置Docker服务..."
bash scripts/configure_docker.sh

# 检查Docker服务配置是否成功
if [ $? -ne 0 ]; then
    echo "Docker服务配置失败，请检查错误信息"
    exit 1
fi

echo "部署完成！"
echo "所有服务已启动，请检查服务状态" 