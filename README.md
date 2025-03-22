# DHCP 管理系统

这是一个基于 FastAPI 和 Vue.js 的 DHCP 管理系统，集成了 Kea DHCP 和 BIND9 DNS 服务。

## 项目结构

```
.
├── src/                    # 源代码目录
│   ├── backend/           # 后端代码
│   │   ├── api/          # API 路由
│   │   ├── models/       # 数据模型
│   │   ├── schemas/      # Pydantic 模型
│   │   ├── services/     # 业务逻辑
│   │   ├── utils/        # 工具函数
│   │   └── main.py       # 主应用入口
│   └── frontend/         # 前端代码
├── alembic/              # 数据库迁移
├── config/               # 配置文件
├── scripts/              # 脚本文件
├── docker-compose.yml    # Docker 编排配置
├── Dockerfile           # 主应用 Dockerfile
├── requirements.txt     # Python 依赖
└── .env                # 环境变量
```

## 功能特性

- DHCP 服务管理（基于 Kea）
- DNS 服务管理（基于 BIND9）
- 用户认证和授权
- API 密钥管理
- 实时监控和日志
- Web 界面管理

## 开发环境设置

1. 克隆项目：
```bash
git clone <repository-url>
cd dhcp-management-system
```

2. 创建环境变量文件：
```bash
cp .env.example .env
```

3. 启动开发环境：
```bash
./start.sh
```

## 服务访问

- Web 界面：http://localhost
- API 文档：http://localhost/docs
- Kea DHCP 控制：http://localhost/kea/
- BIND9 DNS 服务：localhost:53

## 开发指南

### 后端开发

1. 安装依赖：
```bash
pip install -r requirements.txt
```

2. 运行开发服务器：
```bash
uvicorn src.backend.main:app --reload
```

3. 数据库迁移：
```bash
alembic upgrade head
```

### 前端开发

1. 安装依赖：
```bash
cd src/frontend
npm install
```

2. 运行开发服务器：
```bash
npm run dev
```

## 部署

1. 构建 Docker 镜像：
```bash
docker compose build
```

2. 启动服务：
```bash
docker compose up -d
```

## 测试

运行测试：
```bash
pytest
```

## 贡献指南

1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT License

