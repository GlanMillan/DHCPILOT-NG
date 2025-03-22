#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认配置
DB_PASSWORD=""

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -h, --help                显示帮助信息"
    echo "  -p, --password PASSWORD   设置数据库密码"
    echo
    echo "示例:"
    echo "  $0 --password mypassword  使用指定密码部署"
    echo "  $0                        使用交互式配置"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -p|--password)
                if [ -n "$2" ]; then
                    DB_PASSWORD=$2
                    shift 2
                else
                    print_error "密码参数缺失"
                    exit 1
                fi
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查并创建必要的目录
setup_directories() {
    print_info "正在创建必要的目录..."
    
    # 创建配置目录
    mkdir -p kea/conf bind9/conf nginx/conf backend/app frontend/src logs
    mkdir -p bind9/zones bind9/logs
    
    print_info "目录创建完成"
}

# 生成配置文件
generate_configs() {
    print_info "正在生成配置文件..."
    
    # 如果指定了数据库密码，则直接使用
    if [ -n "$DB_PASSWORD" ]; then
        # 更新.env文件中的数据库密码
        if [ -f ".env" ]; then
            sed -i "s/^POSTGRES_PASSWORD=.*$/POSTGRES_PASSWORD=$DB_PASSWORD/" .env
            print_info "已更新数据库密码"
        else
            echo "POSTGRES_PASSWORD=$DB_PASSWORD" > .env
            print_info "已创建.env文件并设置数据库密码"
        fi
    fi
    
    # 确保BIND9配置文件存在
    if [ ! -f "bind9/conf/named.conf" ]; then
        print_warn "BIND9配置文件不存在，正在创建..."
        cat > bind9/conf/named.conf <<EOL
options {
    directory "/var/cache/bind";
    
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    dnssec-validation auto;
    auth-nxdomain no;
    listen-on { any; };
    listen-on-v6 { any; };
    allow-query { any; };
    allow-recursion { any; };
    
    max-cache-size 256M;
    max-ncache-ttl 3600;
};

zone "example.com" {
    type master;
    file "/var/cache/bind/db.example.com";
    allow-update { key "rndc-key"; };
};

key "rndc-key" {
    algorithm hmac-sha256;
    secret "WILL_BE_REPLACED_AT_STARTUP";  # 这个值会在容器启动时被替换
};
EOL
    fi
    
    print_info "配置文件生成完成"
}

# 设置文件权限
setup_permissions() {
    print_info "正在设置文件权限..."
    
    # 设置日志目录权限
    chmod -R 755 logs
    
    # 设置配置文件权限
    chmod 600 .env 2>/dev/null || true
    chmod -R 644 kea/conf/* 2>/dev/null || true
    chmod -R 644 bind9/conf/* 2>/dev/null || true
    chmod -R 644 nginx/conf/* 2>/dev/null || true
    
    # 设置BIND9目录权限
    chmod -R 755 bind9/zones 2>/dev/null || true
    chmod -R 755 bind9/logs 2>/dev/null || true
    
    print_info "权限设置完成"
}

# 启动服务
start_services() {
    print_info "正在启动服务..."
    
    # 停止现有服务
    docker compose down -v
    
    # 构建并启动服务
    docker compose up -d --build
    
    if [ $? -ne 0 ]; then
        print_error "服务启动失败"
        exit 1
    fi
    
    print_info "服务启动完成"
}

# 检查服务状态
check_services() {
    print_info "正在检查服务状态..."
    
    # 等待服务启动
    sleep 10
    
    # 检查容器状态
    containers=$(docker compose ps -q)
    for container in $containers; do
        status=$(docker inspect --format='{{.State.Status}}' $container)
        name=$(docker inspect --format='{{.Name}}' $container)
        if [ "$status" != "running" ]; then
            print_error "容器 $name 未正常运行"
            print_error "请检查日志: docker compose logs $name"
            exit 1
        fi
    done
    
    print_info "所有服务运行正常"
}

# 显示完成信息
show_completion() {
    print_info "部署完成！"
    echo
    echo "下一步操作："
    echo "1. 访问 Web 界面: http://localhost"
    echo "2. 检查服务日志: docker compose logs -f"
    echo "3. 查看服务状态: docker compose ps"
    echo
    echo "如需帮助，请参考 SETUP.md 文件"
}

# 主函数
main() {
    echo "DHCP管理系统部署脚本"
    echo "====================="
    
    # 解析命令行参数
    parse_args "$@"
    
    # 执行部署步骤
    setup_directories
    generate_configs
    setup_permissions
    start_services
    check_services
    show_completion
}

# 脚本入口
main "$@" 