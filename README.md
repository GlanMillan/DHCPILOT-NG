# DHCPLIOT-NG

DHCPLIOT-NG是一个基于FastAPI的DHCP和DNS管理系统，提供Web界面来管理DHCP和DNS服务。

## 系统要求

- Python 3.11+
- PostgreSQL 16+
- Redis 7+
- Nginx
- BIND9 (在物理服务器上)
- Kea DHCP (在物理服务器上)
- Docker & Docker Compose

## 快速开始

### 1. 服务器端部署

首先需要在物理服务器上部署BIND9和KEA DHCP服务：

```bash
# 克隆仓库
git clone https://github.com/GlanMillan/DHCPLIOT-NG.git
cd DHCPLIOT-NG

# 运行服务器部署脚本
sudo ./scripts/deploy_server.sh
```

部署脚本会自动完成以下步骤：
1. 安装必要的软件包（BIND9、KEA DHCP、PostgreSQL等）
2. 创建必要的用户和用户组
3. 配置BIND9和KEA DHCP的基本设置
4. 启动Docker服务（数据库、Redis等）
5. 配置数据库
6. 启动所有服务

### 2. 应用服务部署

使用Docker Compose部署应用服务：

```bash
# 复制环境变量文件
cp .env.example .env

# 编辑.env文件，更新以下配置：
# KEA_CTRL_AGENT_URL=http://your-server-ip:8000
# BIND9_RNDC_KEY=your-rndc-key

# 启动服务
docker compose up -d
```

## 配置说明

### BIND9配置

BIND9配置文件位于服务器的`/etc/bind/`目录下：
- named.conf：主配置文件
- named.conf.options：全局选项配置
- named.conf.local：本地区域配置
- named.conf.default-zones：默认区域配置

### Kea DHCP配置

Kea DHCP配置文件位于服务器的`/etc/kea/`目录下：
- kea-dhcp4.conf：DHCPv4服务器配置

### 数据库配置

数据库配置在`.env`文件中：
```
POSTGRES_USER=dhcp
POSTGRES_PASSWORD=dhcp_password
POSTGRES_DB=dhcp_admin
```

## 目录结构

```
.
├── backend/           # FastAPI后端应用
├── frontend/         # 前端应用
├── nginx/            # Nginx配置
├── redis/            # Redis配置
├── scripts/          # 部署和维护脚本
│   ├── configure_server.sh  # 服务器配置脚本
│   ├── reset_server.sh     # 服务器重置脚本
│   ├── maintain_web.sh     # Web服务维护脚本
│   ├── fix_kea_dhcp.sh     # KEA DHCP修复脚本
│   ├── generate_key.sh     # RNDC密钥生成脚本
│   ├── deploy.sh          # 部署脚本（将合并到maintain_web.sh）
│   └── configure_docker.sh # Docker配置脚本（将合并到maintain_web.sh）
├── config/           # 服务器配置文件
│   ├── bind9/       # BIND9配置
│   │   ├── named.conf              # 主配置文件
│   │   ├── named.conf.options      # 全局选项配置
│   │   ├── named.conf.local        # 本地区域配置
│   │   ├── named.conf.default-zones # 默认区域配置
│   │   └── zones/                  # DNS区域文件目录
│   │       └── db.example.com      # 示例区域文件
│   └── kea/         # KEA DHCP配置
│       └── kea-dhcp4.conf          # DHCPv4服务器配置
├── docker-compose.yml              # Docker Compose配置
├── .env                           # 环境变量配置
├── .env.example                   # 环境变量示例
├── alembic.ini                    # 数据库迁移配置
└── README.md                      # 项目说明文档
```

## 部署注意事项

1. 部署顺序
   - 先运行 `deploy_server.sh` 脚本部署服务器端服务
   - 等待所有服务启动完成
   - 再使用 Docker Compose 部署应用服务

2. 数据库配置
   - 确保数据库服务已完全启动
   - 检查数据库连接是否正常
   - 确保数据库用户权限正确

3. 服务检查
   - 使用 `systemctl status` 检查服务状态
   - 检查日志文件排查问题
   - 确保防火墙允许必要端口

4. 常见问题
   - 如果KEA DHCP启动失败，检查数据库连接
   - 如果BIND9启动失败，检查配置文件权限
   - 如果应用服务无法连接，检查网络配置

## 开发

### 后端开发

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
.\venv\Scripts\activate  # Windows

pip install -r requirements.txt
uvicorn app.main:app --reload
```

### 前端开发

```bash
cd frontend
npm install
npm run dev
```

## API文档

启动后端服务后访问：
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 贡献

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

## 许可证

啥是许可证？？？？？

