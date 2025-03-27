# DHCPLIOT-NG

DHCPLIOT-NG是一个基于FastAPI的DHCP和DNS管理系统，提供Web界面来管理DHCP和DNS服务。

## 系统要求

- Python 3.11+
- PostgreSQL 16+
- Redis 7+
- Nginx
- BIND9 (在物理服务器上)
- Kea DHCP (在物理服务器上)

## 快速开始

### 1. 服务器端部署

首先需要在物理服务器上部署BIND9和Kea DHCP服务：

```bash
# 克隆仓库
git clone https://github.com/yourusername/DHCPLIOT-NG.git
cd DHCPLIOT-NG

# 运行服务器部署脚本
sudo ./scripts/deploy_server.sh
```

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
├── scripts/          # 部署脚本
├── bind9/            # BIND9配置（用于服务器部署）
├── kea/              # Kea DHCP配置（用于服务器部署）
├── docker-compose.yml
└── README.md
```

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

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

