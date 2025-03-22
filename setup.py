#!/usr/bin/env python3
import os
import re
import sys
import secrets
import ipaddress
from pathlib import Path

def generate_secret():
    """生成安全的随机密钥"""
    return secrets.token_hex(32)

def validate_ip(ip):
    """验证IP地址格式"""
    try:
        ipaddress.ip_address(ip)
        return True
    except ValueError:
        return False

def validate_subnet(subnet):
    """验证子网格式"""
    try:
        ipaddress.ip_network(subnet)
        return True
    except ValueError:
        return False

def get_input_with_default(prompt, default=""):
    """获取用户输入，支持默认值"""
    if default:
        user_input = input(f"{prompt} [{default}]: ").strip()
        return user_input if user_input else default
    return input(f"{prompt}: ").strip()

def update_env_file(config):
    """更新.env文件"""
    env_path = Path(".env")
    env_content = env_path.read_text() if env_path.exists() else ""
    
    # 更新环境变量
    env_vars = {
        "APP_URL": f"http://{config['server_ip']}",
        "POSTGRES_PASSWORD": config['db_password'],
        "JWT_SECRET": config['jwt_secret'],
        "BIND9_RNDC_KEY": config['rndc_key'],
        "CORS_ORIGINS": f'["{config["server_ip"]}"]',
        "SMTP_HOST": config['smtp_host'],
        "SMTP_PORT": config['smtp_port'],
        "SMTP_USER": config['smtp_user'],
        "SMTP_PASSWORD": config['smtp_password'],
        "SMTP_FROM": config['smtp_user']
    }
    
    for key, value in env_vars.items():
        pattern = f"^{key}=.*$"
        replacement = f"{key}={value}"
        env_content = re.sub(pattern, replacement, env_content, flags=re.MULTILINE)
    
    env_path.write_text(env_content)

def update_kea_config(config):
    """更新Kea DHCP配置"""
    kea_config_path = Path("kea/conf/kea-dhcp4.conf")
    if not kea_config_path.exists():
        print("Error: kea-dhcp4.conf not found")
        return
    
    content = kea_config_path.read_text()
    kea_config = {
        "subnet": config['dhcp_subnet'],
        "pool": f"{config['dhcp_pool_start']} - {config['dhcp_pool_end']}",
        "routers": config['dhcp_gateway'],
        "domain-name-servers": config['dns_servers']
    }
    
    # 更新子网配置
    content = re.sub(
        r'"subnet": "[^"]*"',
        f'"subnet": "{kea_config["subnet"]}"',
        content
    )
    content = re.sub(
        r'"pool": "[^"]*"',
        f'"pool": "{kea_config["pool"]}"',
        content
    )
    content = re.sub(
        r'"data": "[^"]*"(?=.*routers)',
        f'"data": "{kea_config["routers"]}"',
        content
    )
    content = re.sub(
        r'"data": "[^"]*"(?=.*domain-name-servers)',
        f'"data": "{kea_config["domain-name-servers"]}"',
        content
    )
    
    kea_config_path.write_text(content)

def update_bind_config(config):
    """更新BIND9配置"""
    bind_config_path = Path("bind9/conf/named.conf")
    if not bind_config_path.exists():
        print("Error: named.conf not found")
        return
    
    content = bind_config_path.read_text()
    content = re.sub(
        r'secret "[^"]*"',
        f'secret "{config["rndc_key"]}"',
        content
    )
    
    bind_config_path.write_text(content)

def main():
    """主函数"""
    print("DHCP管理系统配置向导")
    print("=" * 50)
    
    config = {}
    
    # 基本配置
    config['server_ip'] = get_input_with_default(
        "请输入服务器IP地址",
        "localhost"
    )
    while not validate_ip(config['server_ip']):
        print("错误：无效的IP地址格式")
        config['server_ip'] = get_input_with_default("请重新输入服务器IP地址")
    
    # 数据库配置
    config['db_password'] = get_input_with_default(
        "请输入数据库密码",
        "dhcp_password"
    )
    
    # DHCP配置
    config['dhcp_subnet'] = get_input_with_default(
        "请输入DHCP子网 (CIDR格式，如192.168.1.0/24)",
        "192.0.2.0/24"
    )
    while not validate_subnet(config['dhcp_subnet']):
        print("错误：无效的子网格式")
        config['dhcp_subnet'] = get_input_with_default(
            "请重新输入DHCP子网"
        )
    
    network = ipaddress.ip_network(config['dhcp_subnet'])
    default_start = str(network.network_address + 1)
    default_end = str(network.broadcast_address - 1)
    default_gateway = default_start
    
    config['dhcp_pool_start'] = get_input_with_default(
        "请输入DHCP地址池起始IP",
        default_start
    )
    config['dhcp_pool_end'] = get_input_with_default(
        "请输入DHCP地址池结束IP",
        default_end
    )
    config['dhcp_gateway'] = get_input_with_default(
        "请输入网关IP",
        default_gateway
    )
    config['dns_servers'] = get_input_with_default(
        "请输入DNS服务器IP (多个用逗号分隔)",
        "8.8.8.8, 8.8.4.4"
    )
    
    # 安全配置
    config['jwt_secret'] = generate_secret()
    config['rndc_key'] = generate_secret()
    
    # 邮件配置
    print("\n邮件通知配置 (可选)")
    config['smtp_host'] = get_input_with_default("SMTP服务器地址", "smtp.example.com")
    config['smtp_port'] = get_input_with_default("SMTP端口", "587")
    config['smtp_user'] = get_input_with_default("SMTP用户名", "your-email@example.com")
    config['smtp_password'] = get_input_with_default("SMTP密码", "your-smtp-password")
    
    # 更新配置文件
    print("\n正在更新配置文件...")
    try:
        update_env_file(config)
        update_kea_config(config)
        update_bind_config(config)
        print("配置更新完成！")
    except Exception as e:
        print(f"错误：配置更新失败 - {str(e)}")
        return 1
    
    print("\n下一步操作：")
    print("1. 运行 'docker compose up -d' 启动服务")
    print("2. 访问 http://{config['server_ip']} 检查系统是否正常运行")
    print("3. 查看 docker compose logs 检查服务日志")
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 