#!/bin/bash
set -e

# =================配置区域=================
REPO_URL="https://github.com/charmingyi/CMY-Download-Tools.git"
PROJECT_NAME="CMY-Download-Tools"
PORT=8000
# =========================================

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}🚀 开始部署 $PROJECT_NAME ...${NC}"

# 1. 系统依赖
echo -e "${GREEN}📦 [1/6] 安装系统依赖...${NC}"
if [ -x "$(command -v apt-get)" ]; then
    apt-get update
    apt-get install -y python3 python3-pip python3-venv nodejs npm git wget ffmpeg psmisc
elif [ -x "$(command -v yum)" ]; then
    yum install -y python3 python3-pip git wget ffmpeg psmisc
fi

# 2. 拉取代码
echo -e "${GREEN}⬇️ [2/6] 拉取代码仓库...${NC}"
if [ -d "$PROJECT_NAME" ]; then
    echo "目录已存在，尝试更新..."
    cd $PROJECT_NAME
    git pull
else
    git clone $REPO_URL
    cd $PROJECT_NAME
fi

WORK_DIR=$(pwd)

# 3. 后端环境
echo -e "${GREEN}🐍 [3/6] 配置 Python 环境...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
source venv/bin/activate
pip install -r backend/requirements.txt

# 4. 下载TMD核心
echo -e "${GREEN}⚙️ [4/6] 下载 TMD 核心程序...${NC}"
mkdir -p backend/bin
if [ ! -f "backend/bin/tmd" ]; then
    wget -O backend/bin/tmd https://github.com/unkmonster/tmd/releases/latest/download/tmd-Linux-amd64
fi
chmod 777 backend/bin/tmd

# 5. 前端编译
echo -e "${GREEN}⚛️ [5/6] 编译前端页面...${NC}"
npm install
npm run build

# 6. 系统服务
echo -e "${GREEN}🔧 [6/6] 配置系统服务 (Systemd)...${NC}"
SERVICE_FILE="/etc/systemd/system/cmy-tools.service"

cat <<INI > $SERVICE_FILE
[Unit]
Description=CMY Download Tools Service
After=network.target

[Service]
User=root
WorkingDirectory=$WORK_DIR
ExecStart=$WORK_DIR/venv/bin/uvicorn backend.server:app --host 0.0.0.0 --port $PORT
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
INI

systemctl daemon-reload
systemctl enable cmy-tools
systemctl restart cmy-tools

echo -e "${GREEN}✅ 部署完成！${NC}"
echo -e "${GREEN}🌐 访问地址: http://$(curl -s ifconfig.me):$PORT${NC}"
