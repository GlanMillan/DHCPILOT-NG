# 故障排除指南

本文档提供了DHCPLIOT-NG项目中常见问题的解决方案。

## DHCP服务器问题

### 1. 服务无法启动

#### 症状
- systemctl status 显示服务启动失败
- 日志显示错误信息
- 端口未监听

#### 可能原因
1. 数据库连接问题
   - 数据库服务未运行
   - 数据库凭据错误
   - 数据库权限问题

2. 配置文件问题
   - 配置文件语法错误
   - 配置文件权限错误
   - 配置文件路径错误

3. 端口占用
   - 其他DHCP服务正在运行
   - 端口被其他服务占用

#### 解决方案
1. 检查数据库
```bash
# 检查数据库服务状态
systemctl status mariadb

# 测试数据库连接
mysql -u kea -p

# 检查数据库权限
mysql -u root -p -e "SHOW GRANTS FOR 'kea'@'localhost';"
```

2. 检查配置文件
```bash
# 检查配置文件语法
kea-dhcp4 -t /etc/kea/kea-dhcp4.conf

# 检查配置文件权限
ls -l /etc/kea/kea-dhcp4.conf

# 检查日志文件权限
ls -l /var/log/kea/kea-dhcp4.log
```

3. 检查端口占用
```bash
# 检查端口占用
netstat -tuln | grep 67

# 检查进程
ps aux | grep kea-dhcp4
```

### 2. 客户端无法获取IP地址

#### 症状
- 客户端显示"无法获取IP地址"
- DHCP请求未收到响应
- 网络连接失败

#### 可能原因
1. 网络配置问题
   - 网络接口配置错误
   - 子网配置错误
   - 地址池配置错误

2. 防火墙问题
   - DHCP端口被阻止
   - 防火墙规则配置错误

3. 服务配置问题
   - 服务未正确监听接口
   - 地址池已满
   - 租约配置错误

#### 解决方案
1. 检查网络配置
```bash
# 检查网络接口
ip addr show ens33

# 检查DHCP配置
cat /etc/kea/kea-dhcp4.conf

# 检查地址池使用情况
mysql -u kea -p -e "SELECT * FROM lease4;"
```

2. 检查防火墙
```bash
# 检查防火墙状态
ufw status

# 检查iptables规则
iptables -L | grep 67

# 允许DHCP端口
ufw allow 67/udp
```

3. 检查服务配置
```bash
# 检查服务状态
systemctl status kea-dhcp4-server

# 检查日志
tail -f /var/log/kea/kea-dhcp4.log

# 重启服务
systemctl restart kea-dhcp4-server
```

## DNS服务器问题

### 1. 服务无法启动

#### 症状
- BIND9服务启动失败
- 配置文件语法错误
- 权限问题

#### 可能原因
1. 配置文件问题
   - 语法错误
   - 文件权限错误
   - 路径错误

2. 区域文件问题
   - 区域文件语法错误
   - 区域文件权限错误
   - 区域文件不存在

3. 系统资源问题
   - 内存不足
   - 磁盘空间不足
   - 端口占用

#### 解决方案
1. 检查配置文件
```bash
# 检查配置文件语法
named-checkconf /etc/bind/named.conf

# 检查配置文件权限
ls -l /etc/bind/

# 检查日志
tail -f /var/log/syslog | grep named
```

2. 检查区域文件
```bash
# 检查区域文件语法
named-checkzone example.com /etc/bind/db.example.com

# 检查区域文件权限
ls -l /var/lib/bind/

# 检查区域文件内容
cat /etc/bind/db.example.com
```

3. 检查系统资源
```bash
# 检查内存使用
free -h

# 检查磁盘空间
df -h

# 检查端口占用
netstat -tuln | grep 53
```

### 2. DNS解析失败

#### 症状
- 域名无法解析
- 解析超时
- 返回错误结果

#### 可能原因
1. 区域配置问题
   - 区域文件配置错误
   - 区域传输失败
   - 区域更新问题

2. 转发器问题
   - 转发器配置错误
   - 转发器不可用
   - 网络连接问题

3. 缓存问题
   - 缓存损坏
   - 缓存过期
   - 缓存配置错误

#### 解决方案
1. 检查区域配置
```bash
# 检查区域状态
rndc status

# 检查区域传输
rndc retransfer example.com

# 检查区域文件
cat /etc/bind/db.example.com
```

2. 检查转发器
```bash
# 测试转发器连接
dig @8.8.8.8 example.com

# 检查转发器配置
cat /etc/bind/named.conf.options

# 检查网络连接
ping 8.8.8.8
```

3. 检查缓存
```bash
# 清除缓存
rndc flush

# 检查缓存统计
rndc stats

# 重启服务
systemctl restart bind9
```

## Redis服务器问题

### 1. 服务无法启动

#### 症状
- Redis服务启动失败
- 配置文件错误
- 权限问题

#### 可能原因
1. 配置文件问题
   - 语法错误
   - 文件权限错误
   - 路径错误

2. 系统资源问题
   - 内存不足
   - 磁盘空间不足
   - 端口占用

3. 权限问题
   - 用户权限错误
   - 目录权限错误
   - SELinux限制

#### 解决方案
1. 检查配置文件
```bash
# 检查配置文件语法
redis-cli -h localhost -p 6379 ping

# 检查配置文件权限
ls -l /etc/redis/redis.conf

# 检查日志
tail -f /var/log/redis/redis-server.log
```

2. 检查系统资源
```bash
# 检查内存使用
free -h

# 检查磁盘空间
df -h

# 检查端口占用
netstat -tuln | grep 6379
```

3. 检查权限
```bash
# 检查用户权限
id redis

# 检查目录权限
ls -l /var/lib/redis/

# 检查SELinux状态
getenforce
```

### 2. 连接失败

#### 症状
- 客户端无法连接
- 连接超时
- 认证失败

#### 可能原因
1. 网络问题
   - 防火墙阻止
   - 网络连接问题
   - 绑定地址错误

2. 认证问题
   - 密码错误
   - 认证配置错误
   - 用户权限问题

3. 配置问题
   - 端口配置错误
   - 绑定地址配置错误
   - 保护模式配置错误

#### 解决方案
1. 检查网络
```bash
# 检查防火墙
ufw status

# 检查网络连接
ping localhost

# 检查端口监听
netstat -tuln | grep 6379
```

2. 检查认证
```bash
# 测试连接
redis-cli -h localhost -p 6379 -a your_password ping

# 检查密码配置
cat /etc/redis/redis.conf | grep requirepass

# 重置密码
redis-cli
> CONFIG SET requirepass "new_password"
```

3. 检查配置
```bash
# 检查Redis配置
redis-cli CONFIG GET *

# 检查绑定地址
cat /etc/redis/redis.conf | grep bind

# 检查保护模式
cat /etc/redis/redis.conf | grep protected-mode
```

## 通用问题

### 1. 日志分析

#### 系统日志
```bash
# 查看系统日志
journalctl -u kea-dhcp4-server
journalctl -u bind9
journalctl -u redis-server
```

#### 应用日志
```bash
# DHCP日志
tail -f /var/log/kea/kea-dhcp4.log

# DNS日志
tail -f /var/log/syslog | grep named

# Redis日志
tail -f /var/log/redis/redis-server.log
```

### 2. 性能监控

#### 系统监控
```bash
# CPU使用率
top

# 内存使用
free -h

# 磁盘使用
df -h
```

#### 服务监控
```bash
# 进程状态
ps aux | grep -E "kea-dhcp4|named|redis"

# 端口监听
netstat -tuln

# 连接数
netstat -an | grep -E "67|53|6379"
```

### 3. 备份恢复

#### 数据库备份
```bash
# DHCP数据库备份
mysqldump -u root -p kea > kea_backup.sql

# Redis数据备份
redis-cli SAVE
```

#### 配置文件备份
```bash
# 备份配置文件
cp /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.bak
cp /etc/bind/named.conf /etc/bind/named.conf.bak
cp /etc/redis/redis.conf /etc/redis/redis.conf.bak
``` 