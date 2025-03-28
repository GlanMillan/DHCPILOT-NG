# 配置说明

本文档详细说明了DHCPLIOT-NG项目中各个组件的配置选项。

## DHCP服务器配置

### 配置文件位置
- 主配置文件：`/etc/kea/kea-dhcp4.conf`
- 日志文件：`/var/log/kea/kea-dhcp4.log`

### 主要配置项

#### 数据库配置
```json
"lease-database": {
    "type": "mysql",
    "name": "kea",
    "user": "kea",
    "password": "your_password",
    "host": "localhost",
    "port": 3306
}
```

#### 接口配置
```json
"interfaces-config": {
    "interfaces": [ "ens33" ]
}
```

#### 租约配置
```json
"valid-lifetime": 4000,
"renew-timer": 1000,
"rebind-timer": 2000
```

#### 子网配置
```json
"subnet4": [
    {
        "subnet": "192.168.85.0/24",
        "pools": [ { "pool": "192.168.85.100 - 192.168.85.200" } ],
        "option-data": [
            {
                "name": "routers",
                "data": "192.168.85.1"
            },
            {
                "name": "domain-name-servers",
                "data": "192.168.85.1, 8.8.8.8"
            }
        ]
    }
]
```

### 配置说明

1. 数据库配置
   - type：数据库类型（mysql）
   - name：数据库名称
   - user：数据库用户名
   - password：数据库密码
   - host：数据库主机地址
   - port：数据库端口

2. 接口配置
   - interfaces：要监听的网络接口列表

3. 租约配置
   - valid-lifetime：IP地址租约有效期（秒）
   - renew-timer：续约时间（秒）
   - rebind-timer：重新绑定时间（秒）

4. 子网配置
   - subnet：子网地址和掩码
   - pools：可用IP地址池
   - option-data：DHCP选项配置

## DNS服务器配置

### 配置文件位置
- 主配置文件：`/etc/bind/named.conf`
- 选项配置：`/etc/bind/named.conf.options`
- 本地区域：`/etc/bind/named.conf.local`
- 默认区域：`/etc/bind/named.conf.default-zones`
- 区域文件：`/var/lib/bind/`

### 主要配置项

#### 选项配置
```bind
options {
    directory "/var/cache/bind";
    listen-on { any; };
    listen-on-v6 { any; };
    allow-query { any; };
    recursion yes;
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
};
```

#### 区域配置
```bind
zone "example.com" {
    type master;
    file "/etc/bind/db.example.com";
    allow-transfer { none; };
};
```

### 配置说明

1. 选项配置
   - directory：区域文件目录
   - listen-on：监听地址
   - allow-query：允许查询的客户端
   - recursion：是否允许递归查询
   - forwarders：DNS转发器

2. 区域配置
   - type：区域类型（master/slave）
   - file：区域文件路径
   - allow-transfer：允许区域传输的服务器

## Redis服务器配置

### 配置文件位置
- 主配置文件：`/etc/redis/redis.conf`
- 日志文件：`/var/log/redis/redis-server.log`

### 主要配置项

```conf
# 基本配置
port 6379
bind 127.0.0.1
protected-mode yes

# 内存配置
maxmemory 2gb
maxmemory-policy allkeys-lru

# 持久化配置
save 900 1
save 300 10
save 60 10000

# 日志配置
loglevel notice
logfile /var/log/redis/redis-server.log

# 安全配置
requirepass your_password
```

### 配置说明

1. 基本配置
   - port：监听端口
   - bind：绑定地址
   - protected-mode：保护模式

2. 内存配置
   - maxmemory：最大内存限制
   - maxmemory-policy：内存满时的策略

3. 持久化配置
   - save：RDB持久化配置
   - appendonly：AOF持久化配置

4. 日志配置
   - loglevel：日志级别
   - logfile：日志文件路径

5. 安全配置
   - requirepass：访问密码

## 配置最佳实践

### DHCP配置最佳实践

1. 租约时间设置
   - 根据网络规模设置合适的租约时间
   - 续约时间通常为租约时间的25%
   - 重新绑定时间通常为租约时间的50%

2. 地址池规划
   - 预留足够的IP地址
   - 考虑网络增长需求
   - 避免地址冲突

3. 选项配置
   - 配置正确的默认网关
   - 设置合适的DNS服务器
   - 根据需要添加其他选项

### DNS配置最佳实践

1. 区域配置
   - 使用适当的区域类型
   - 配置区域传输限制
   - 定期更新区域文件

2. 安全配置
   - 限制递归查询
   - 配置访问控制
   - 使用DNSSEC

3. 性能优化
   - 配置合适的缓存
   - 使用转发器
   - 优化查询响应

### Redis配置最佳实践

1. 内存管理
   - 设置合理的内存限制
   - 选择合适的淘汰策略
   - 监控内存使用情况

2. 持久化配置
   - 根据需求选择持久化方式
   - 配置合适的保存频率
   - 定期备份数据

3. 安全配置
   - 设置强密码
   - 限制访问地址
   - 启用保护模式 