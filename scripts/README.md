# 最新配置脚本

本目录包含最新的服务配置脚本，用于自动化部署和配置各种服务。

## 脚本列表

### configure_redis.sh
Redis服务配置脚本，功能包括：
- 卸载和重新安装Redis
- 配置远程连接
- 设置内存限制
- 配置持久化
- 设置权限
- 启动和测试服务

### configure_bind9.sh
BIND9 DNS服务配置脚本，功能包括：
- 卸载和重新安装BIND9
- 配置DNS转发器（223.5.5.5和8.8.8.8）
- 创建示例区域文件
- 设置权限
- 配置递归查询
- 启动和测试服务

### configure_kea.sh
KEA DHCP服务配置脚本，功能包括：
- 卸载和重新安装KEA DHCP
- 配置PostgreSQL数据库集成
- 配置DDNS更新
- 设置地址池和子网
- 配置DHCP选项
- 设置权限
- 启动和测试服务

## 使用方法

1. 为脚本添加执行权限：
```bash
chmod +x scripts/latest/*.sh
```

2. 使用root权限运行脚本：
```bash
sudo ./scripts/latest/configure_redis.sh
sudo ./scripts/latest/configure_bind9.sh
sudo ./scripts/latest/configure_kea.sh
```

## 注意事项

1. 所有脚本都需要root权限运行
2. 脚本会自动停止和卸载现有服务
3. 脚本会创建必要的目录和配置文件
4. 脚本会进行语法检查和功能测试
5. 如果遇到错误，脚本会立即停止并显示错误信息
6. KEA DHCP配置需要先确保PostgreSQL服务正常运行

## 配置说明

### Redis配置
- 监听地址：0.0.0.0
- 端口：6379
- 最大内存：2GB
- 持久化：RDB和AOF
- 密码：通过环境变量设置

### BIND9配置
- 监听地址：所有接口
- 端口：53
- DNS转发器：223.5.5.5和8.8.8.8
- 递归查询：启用
- 示例区域：example.com

### KEA DHCP配置
- 监听地址：所有接口
- 端口：67
- 数据库：PostgreSQL
- 子网：192.168.1.0/24
- 地址池：192.168.1.100 - 192.168.1.200
- 租约时间：4000秒
- 续约时间：1000秒
- 重新绑定时间：2000秒
- DDNS更新：启用
- 日志级别：INFO

# DHCP服务器自动部署脚本

这个脚本用于自动部署KEA DHCP服务器，包括MariaDB数据库配置和KEA DHCP服务配置。

## 功能特点

- 自动安装必要的软件包
- 配置MariaDB数据库
- 创建KEA数据库和用户
- 创建必要的数据库表
- 配置KEA DHCP服务
- 设置日志记录
- 自动检查服务状态

## 系统要求

- Debian/Ubuntu系统
- root权限
- 网络连接

## 使用方法

1. 下载脚本：
```bash
wget https://raw.githubusercontent.com/your-repo/DHCPLIOT-NG/main/scripts/latest/deploy_dhcp.sh
```

2. 添加执行权限：
```bash
chmod +x deploy_dhcp.sh
```

3. 运行脚本：
```bash
sudo ./deploy_dhcp.sh
```

4. 按照提示输入必要的信息：
   - 服务器IP地址
   - 数据库root密码
   - KEA数据库用户名（默认为kea）
   - KEA数据库密码
   - DHCP子网
   - DHCP地址池起始IP
   - DHCP地址池结束IP
   - 默认网关IP

## 配置说明

### 数据库配置
- 数据库名：kea
- 默认用户名：kea
- 端口：3306

### DHCP配置
- 接口：ens33
- 租约时间：4000秒
- 续约时间：1000秒
- 重新绑定时间：2000秒

### 日志配置
- 日志文件：/var/log/kea/kea-dhcp4.log
- 日志级别：DEBUG

## 检查部署

部署完成后，请检查以下内容：

1. KEA服务状态：
```bash
systemctl status kea-dhcp4-server
```

2. 端口监听状态：
```bash
netstat -tuln | grep 67
```

3. 数据库连接：
```bash
mysql -u kea -p
```

4. 日志文件：
```bash
tail -f /var/log/kea/kea-dhcp4.log
```

## 常见问题

1. 如果服务无法启动，检查：
   - 数据库连接是否正常
   - 配置文件权限是否正确
   - 日志文件权限是否正确

2. 如果客户端无法获取IP地址，检查：
   - 网络接口配置是否正确
   - DHCP地址池是否配置正确
   - 防火墙是否允许DHCP流量

## 维护说明

1. 查看服务状态：
```bash
systemctl status kea-dhcp4-server
```

2. 重启服务：
```bash
systemctl restart kea-dhcp4-server
```

3. 查看日志：
```bash
tail -f /var/log/kea/kea-dhcp4.log
```

4. 备份数据库：
```bash
mysqldump -u root -p kea > kea_backup.sql
```

## 更新日志

### v1.0.0 (2024-03-28)
- 初始版本发布
- 支持自动部署KEA DHCP服务器
- 支持MariaDB数据库配置
- 支持自定义DHCP配置 