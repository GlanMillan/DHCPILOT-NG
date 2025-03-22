#!/bin/sh

# 检查是否已经存在密钥文件
if [ ! -f /etc/bind/rndc.key ]; then
    # 生成新的RNDC密钥
    rndc-confgen -a -c /etc/bind/rndc.key
    
    # 设置适当的权限
    chown bind:bind /etc/bind/rndc.key
    chmod 640 /etc/bind/rndc.key
fi

# 提取密钥值并设置为环境变量
RNDC_KEY=$(grep -Po '(?<=secret ")[^"]*' /etc/bind/rndc.key)
export BIND9_RNDC_KEY="$RNDC_KEY"

# 使用环境变量替换named.conf中的密钥
sed -i "s|secret.*|secret \"$RNDC_KEY\";  # 动态生成的密钥|" /etc/bind/named.conf

exec "$@" 