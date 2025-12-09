#!/bin/bash
set -e

REPO_URL="https://github.com/charmingyi/CMY-Download-Tools.git"
PROJECT_NAME="CMY-Download-Tools"
# [关键变更] 默认监听 :: (同时支持 IPv6 和 IPv4)
PORT=8000
BIND_HOST="::" 

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}    CMY Download Tools 一键管理脚本      ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo "1. 全新安装 (Install New)"
echo "2. 更新升级 (Update/Fix)"
echo "3. 退出 (Exit)"
read -p "请输入数字 [1-3]: " choice

install_deps() {
    echo -e "${GREEN}📦 安装系统依赖...${NC}"
    if [ -x "$(command -v apt-get)" ]; then
        apt-get update
        apt-get install -y python3 python3-pip python3-venv nodejs npm git wget ffmpeg psmisc
    elif [ -x "$(command -v yum)" ]; then
        yum install -y python3 python3-pip git wget ffmpeg psmisc
    fi
}

setup_backend() {
    echo -e "${GREEN}🐍 配置后端...${NC}"
    if [ ! -d "venv" ]; then python3 -m venv venv; fi
    source venv/bin/activate
    pip install -r backend/requirements.txt
    
    mkdir -p backend/bin
    if [ ! -f "backend/bin/tmd" ]; then
        echo "⬇️ 下载 TMD 核心..."
        wget -O backend/bin/tmd https://github.com/unkmonster/tmd/releases/latest/download/tmd-Linux-amd64
    fi
    chmod 777 backend/bin/tmd
}

build_frontend() {
    echo -e "${GREEN}⚛️ 编译前端...${NC}"
    npm install
    npm run build
}

# [关键变更] 提取出配置服务函数，并在更新时也调用它
setup_service() {
    echo -e "${GREEN}🔧 配置系统服务 (IPv6支持)...${NC}"
    WORK_DIR=$(pwd)
    SERVICE_FILE="/etc/systemd/system/cmy-tools.service"

    # 强制覆盖旧配置
    cat <<INI > $SERVICE_FILE
[Unit]
Description=CMY Tools Service
After=network.target
[Service]
User=root
WorkingDirectory=$WORK_DIR
# 使用 :: 监听
ExecStart=$WORK_DIR/venv/bin/uvicorn backend.server:app --host $BIND_HOST --port $PORT
Restart=always
[Install]
WantedBy=multi-user.target
INI

    systemctl daemon-reload
    systemctl enable cmy-tools
    # 重启服务以应用新配置
    systemctl restart cmy-tools
}

if [ "$choice" == "1" ]; then
    echo -e "${GREEN}🚀 开始全新安装...${NC}"
    install_deps
    if [ -d "$PROJECT_NAME" ]; then
        echo "目录已存在，请先删除或选择升级。"
        exit 1
    fi
    git clone $REPO_URL
    cd $PROJECT_NAME
    setup_backend
    build_frontend
    setup_service
    echo -e "${GREEN}✅ 安装完成！访问: http://[::]:$PORT${NC}"

elif [ "$choice" == "2" ]; then
    echo -e "${GREEN}🚀 开始更新...${NC}"
    if [ ! -d "$PROJECT_NAME" ] && [ ! -f "package.json" ]; then
        echo "❌ 未找到项目文件夹，请在项目根目录运行或选择全新安装。"
        exit 1
    fi
    
    if [ -d "$PROJECT_NAME" ]; then cd $PROJECT_NAME; fi
    
    echo "⬇️ 拉取最新代码..."
    git stash
    git pull
    
    setup_backend
    build_frontend
    
    # [关键] 更新时强制重写服务配置 (解决端口监听问题)
    setup_service
    
    echo -e "${GREEN}✅ 升级完成！访问: http://[::]:$PORT${NC}"

else
    echo "退出。"
    exit 0
fi
