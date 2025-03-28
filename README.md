# DHCPLIOT-NG

DHCPLIOT-NG是一个用于自动化部署和管理DHCP、DNS等网络服务的工具集。本项目提供了一系列脚本，用于快速部署和配置各种网络服务。

## 项目结构

```
DHCPLIOT-NG/
├── README.md                 # 项目说明文档
├── scripts/                  # 脚本目录
│   ├── latest/              # 最新版本的脚本
│   │   ├── deploy_dhcp.sh   # DHCP服务器部署脚本
│   │   ├── deploy_dns.sh    # DNS服务器部署脚本
│   │   ├── deploy_redis.sh  # Redis服务器部署脚本
│   │   └── README.md        # 脚本使用说明
│   └── legacy/              # 旧版本脚本（保留用于参考）
├── config/                  # 配置文件目录
│   ├── kea/                # KEA DHCP配置
│   ├── bind9/              # BIND9 DNS配置
│   └── redis/              # Redis配置
└── docs/                   # 文档目录
    ├── deployment.md       # 部署指南
    ├── configuration.md    # 配置说明
    └── troubleshooting.md  # 故障排除指南
```

## 功能特点

- 自动化部署DHCP服务器（KEA）
- 自动化部署DNS服务器（BIND9）
- 自动化部署缓存服务器（Redis）
- 完整的配置管理
- 详细的部署文档
- 故障排除指南

## 系统要求

- Debian/Ubuntu系统
- root权限
- 网络连接
- 至少2GB RAM
- 至少20GB磁盘空间

## 快速开始

1. 克隆项目：
```bash
git clone https://github.com/your-repo/DHCPLIOT-NG.git
cd DHCPLIOT-NG
```

2. 添加执行权限：
```bash
chmod +x scripts/latest/*.sh
```

3. 部署服务：
```bash
# 部署DHCP服务器
sudo ./scripts/latest/deploy_dhcp.sh

# 部署DNS服务器
sudo ./scripts/latest/deploy_dns.sh

# 部署Redis服务器
sudo ./scripts/latest/deploy_redis.sh
```

## 配置说明

### DHCP服务器配置
- 服务：KEA DHCP
- 数据库：MariaDB
- 端口：67
- 配置目录：/etc/kea
- 日志目录：/var/log/kea

### DNS服务器配置
- 服务：BIND9
- 端口：53
- 配置目录：/etc/bind
- 区域文件：/var/lib/bind

### Redis服务器配置
- 端口：6379
- 配置目录：/etc/redis
- 数据目录：/var/lib/redis

## 维护说明

### 服务管理
```bash
# 查看服务状态
systemctl status kea-dhcp4-server
systemctl status bind9
systemctl status redis-server

# 重启服务
systemctl restart kea-dhcp4-server
systemctl restart bind9
systemctl restart redis-server
```

### 日志查看
```bash
# DHCP日志
tail -f /var/log/kea/kea-dhcp4.log

# DNS日志
tail -f /var/log/syslog | grep named

# Redis日志
tail -f /var/log/redis/redis-server.log
```

### 数据库备份
```bash
# DHCP数据库备份
mysqldump -u root -p kea > kea_backup.sql

# Redis数据备份
redis-cli SAVE
```

## 故障排除

1. 服务无法启动
   - 检查配置文件权限
   - 检查日志文件
   - 检查端口占用

2. 客户端无法获取IP
   - 检查DHCP服务状态
   - 检查网络接口配置
   - 检查防火墙规则

3. DNS解析失败
   - 检查BIND9服务状态
   - 检查区域文件配置
   - 检查DNS转发设置

## 更新日志

### v1.0.0 (2024-03-28)
- 初始版本发布
- 支持KEA DHCP服务器部署
- 支持BIND9 DNS服务器部署
- 支持Redis服务器部署
- 完整的部署文档
- 详细的配置说明
- 故障排除指南

## 贡献指南

1. Fork项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 许可证

本项目采用MIT许可证。详见LICENSE文件。

