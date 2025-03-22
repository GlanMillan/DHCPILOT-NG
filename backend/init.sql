-- 创建扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 授予dhcp用户对所有表的权限
ALTER DEFAULT PRIVILEGES FOR USER dhcp IN SCHEMA public
    GRANT ALL ON TABLES TO dhcp;
ALTER DEFAULT PRIVILEGES FOR USER dhcp IN SCHEMA public
    GRANT ALL ON SEQUENCES TO dhcp;
GRANT ALL ON SCHEMA public TO dhcp;

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建DHCP配置表
CREATE TABLE IF NOT EXISTS dhcp_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subnet VARCHAR(50) NOT NULL,
    pool_start VARCHAR(15) NOT NULL,
    pool_end VARCHAR(15) NOT NULL,
    gateway VARCHAR(15),
    dns_servers TEXT[],
    lease_time INTEGER DEFAULT 3600,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建DHCP租约表
CREATE TABLE IF NOT EXISTS dhcp_leases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mac_address VARCHAR(17) NOT NULL,
    ip_address VARCHAR(15) NOT NULL,
    hostname VARCHAR(255),
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    subnet_id UUID REFERENCES dhcp_configs(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建DNS记录表
CREATE TABLE IF NOT EXISTS dns_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(10) NOT NULL,
    content TEXT NOT NULL,
    ttl INTEGER DEFAULT 3600,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建审计日志表
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
); 