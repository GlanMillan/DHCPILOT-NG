#!/bin/bash

# 设置错误处理
set -e
trap 'echo "错误发生在第 $LINENO 行"; exit 1' ERR

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 检查Docker是否运行
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log "错误：Docker服务未运行"
        exit 1
    fi
}

# 检查本地服务状态
check_local_services() {
    log "检查本地服务状态..."
    for service in postgresql redis-server; do
        if ! systemctl is-active --quiet $service; then
            log "错误：$service 服务未运行"
            exit 1
        fi
    done
}

# 显示帮助信息
show_help() {
    echo "用法: $0 [命令]"
    echo "可用命令:"
    echo "  start     - 启动Web服务"
    echo "  stop      - 停止Web服务"
    echo "  restart   - 重启Web服务"
    echo "  status    - 显示服务状态"
    echo "  logs      - 显示服务日志"
    echo "  update    - 更新Web服务"
    echo "  backup    - 备份Web服务数据"
    echo "  restore   - 恢复Web服务数据"
    echo "  help      - 显示此帮助信息"
}

# 启动服务
start_services() {
    log "启动Web服务..."
    docker compose up -d
    log "Web服务已启动"
}

# 停止服务
stop_services() {
    log "停止Web服务..."
    docker compose down
    log "Web服务已停止"
}

# 重启服务
restart_services() {
    log "重启Web服务..."
    docker compose restart
    log "Web服务已重启"
}

# 显示状态
show_status() {
    log "显示服务状态..."
    docker compose ps
}

# 显示日志
show_logs() {
    log "显示服务日志..."
    docker compose logs -f
}

# 更新服务
update_services() {
    log "更新Web服务..."
    docker compose pull
    docker compose up -d --build
    log "Web服务已更新"
}

# 备份数据
backup_data() {
    log "备份Web服务数据..."
    BACKUP_DIR="/var/backups/web"
    BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).tar"
    
    mkdir -p "$BACKUP_DIR"
    
    # 备份数据库
    pg_dump -h localhost -U $POSTGRES_USER -d $POSTGRES_DB > "$BACKUP_DIR/db_backup.sql"
    
    # 备份Redis数据
    redis-cli -h localhost -a $POSTGRES_PASSWORD SAVE
    cp /var/lib/redis/dump.rdb "$BACKUP_DIR/redis_backup.rdb"
    
    # 创建备份压缩包
    tar -czf "$BACKUP_FILE" -C "$BACKUP_DIR" db_backup.sql redis_backup.rdb
    
    # 清理临时文件
    rm "$BACKUP_DIR/db_backup.sql" "$BACKUP_DIR/redis_backup.rdb"
    
    log "备份完成：$BACKUP_FILE"
}

# 恢复数据
restore_data() {
    log "恢复Web服务数据..."
    BACKUP_DIR="/var/backups/web"
    
    # 检查备份文件
    if [ ! -d "$BACKUP_DIR" ]; then
        log "错误：备份目录不存在"
        exit 1
    fi
    
    # 列出可用的备份文件
    echo "可用的备份文件："
    ls -l "$BACKUP_DIR"/*.tar
    
    # 选择要恢复的备份文件
    read -p "请输入要恢复的备份文件名: " BACKUP_FILE
    
    if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
        log "错误：备份文件不存在"
        exit 1
    fi
    
    # 停止服务
    stop_services
    
    # 解压备份文件
    tar -xzf "$BACKUP_DIR/$BACKUP_FILE" -C "$BACKUP_DIR"
    
    # 恢复数据库
    psql -h localhost -U $POSTGRES_USER -d $POSTGRES_DB < "$BACKUP_DIR/db_backup.sql"
    
    # 恢复Redis数据
    cp "$BACKUP_DIR/redis_backup.rdb" /var/lib/redis/dump.rdb
    systemctl restart redis-server
    
    # 清理临时文件
    rm "$BACKUP_DIR/db_backup.sql" "$BACKUP_DIR/redis_backup.rdb"
    
    # 启动服务
    start_services
    
    log "数据恢复完成"
}

# 主程序
main() {
    # 检查Docker和本地服务
    check_docker
    check_local_services
    
    # 处理命令
    case "$1" in
        "start")
            start_services
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "update")
            update_services
            ;;
        "backup")
            backup_data
            ;;
        "restore")
            restore_data
            ;;
        "help"|"")
            show_help
            ;;
        *)
            log "错误：未知命令 '$1'"
            show_help
            exit 1
            ;;
    esac
}

# 执行主程序
main "$@" 