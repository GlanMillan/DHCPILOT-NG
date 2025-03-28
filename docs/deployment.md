# 部署指南

本文档详细说明了如何部署DHCPLIOT-NG项目的各个组件。

## 部署顺序

1. DHCP服务器部署
2. DNS服务器部署
3. Redis服务器部署

## DHCP服务器部署

### 前置条件
- Debian/Ubuntu系统
- root权限
- 网络连接
- 至少1GB RAM
- 至少10GB磁盘空间

### 部署步骤

1. 下载部署脚本：
```bash
wget https://raw.githubusercontent.com/your-repo/DHCPLIOT-NG/main/scripts/latest/deploy_dhcp.sh
```

2. 添加执行权限：
```bash
chmod +x deploy_dhcp.sh
```

3. 运行部署脚本：
```bash
sudo ./deploy_dhcp.sh
```

4. 按照提示输入必要信息：
   - 服务器IP地址
   - 数据库root密码
   - KEA数据库用户名（默认：kea）
   - KEA数据库密码
   - DHCP子网
   - DHCP地址池起始IP
   - DHCP地址池结束IP
   - 默认网关IP

### 验证部署

1. 检查服务状态：
```bash
systemctl status kea-dhcp4-server
```

2. 检查端口监听：
```bash
netstat -tuln | grep 67
```

3. 检查数据库连接：
```bash
mysql -u kea -p
```

4. 检查日志：
```bash
tail -f /var/log/kea/kea-dhcp4.log
```

## DNS服务器部署

### 前置条件
- Debian/Ubuntu系统
- root权限
- 网络连接
- 至少512MB RAM
- 至少5GB磁盘空间

### 部署步骤

1. 下载部署脚本：
```bash
wget https://raw.githubusercontent.com/your-repo/DHCPLIOT-NG/main/scripts/latest/deploy_dns.sh
```

2. 添加执行权限：
```bash
chmod +x deploy_dns.sh
```

3. 运行部署脚本：
```bash
sudo ./deploy_dns.sh
```

4. 按照提示输入必要信息：
   - 服务器IP地址
   - 域名
   - DNS转发器IP（可选）

### 验证部署

1. 检查服务状态：
```bash
systemctl status bind9
```

2. 检查端口监听：
```bash
netstat -tuln | grep 53
```

3. 检查DNS解析：
```bash
dig @localhost example.com
```

4. 检查日志：
```bash
tail -f /var/log/syslog | grep named
```

## Redis服务器部署

### 前置条件
- Debian/Ubuntu系统
- root权限
- 网络连接
- 至少512MB RAM
- 至少5GB磁盘空间

### 部署步骤

1. 下载部署脚本：
```bash
wget https://raw.githubusercontent.com/your-repo/DHCPLIOT-NG/main/scripts/latest/deploy_redis.sh
```

2. 添加执行权限：
```bash
chmod +x deploy_redis.sh
```

3. 运行部署脚本：
```bash
sudo ./deploy_redis.sh
```

4. 按照提示输入必要信息：
   - Redis端口（默认：6379）
   - Redis密码
   - 最大内存限制

### 验证部署

1. 检查服务状态：
```bash
systemctl status redis-server
```

2. 检查端口监听：
```bash
netstat -tuln | grep 6379
```

3. 测试Redis连接：
```bash
redis-cli ping
```

4. 检查日志：
```bash
tail -f /var/log/redis/redis-server.log
```

## 部署后检查清单

### DHCP服务器
- [ ] 服务状态正常
- [ ] 监听67端口
- [ ] 数据库连接正常
- [ ] 日志记录正常
- [ ] 客户端可以获取IP地址

### DNS服务器
- [ ] 服务状态正常
- [ ] 监听53端口
- [ ] DNS解析正常
- [ ] 日志记录正常
- [ ] 区域文件权限正确

### Redis服务器
- [ ] 服务状态正常
- [ ] 监听6379端口
- [ ] 连接测试成功
- [ ] 日志记录正常
- [ ] 内存限制生效

## 常见问题

### DHCP服务器问题
1. 服务无法启动
   - 检查数据库连接
   - 检查配置文件权限
   - 检查日志文件

2. 客户端无法获取IP
   - 检查网络接口配置
   - 检查DHCP地址池
   - 检查防火墙规则

### DNS服务器问题
1. 服务无法启动
   - 检查配置文件语法
   - 检查区域文件权限
   - 检查端口占用

2. DNS解析失败
   - 检查区域文件配置
   - 检查DNS转发设置
   - 检查日志文件

### Redis服务器问题
1. 服务无法启动
   - 检查配置文件
   - 检查端口占用
   - 检查日志文件

2. 连接失败
   - 检查防火墙规则
   - 检查密码配置
   - 检查网络连接 