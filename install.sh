#!/bin/bash
set -e

REPO_URL="https://github.com/charmingyi/CMY-Download-Tools.git"
PROJECT_NAME="CMY-Download-Tools"

# 默认配置
DEFAULT_PORT=8000
DEFAULT_HOST="::"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}    CMY Download Tools 一键管理脚本      ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo "1. 全新安装 (Install New)"
echo "2. 更新升级 (Update/Fix)"
echo "3. 修改配置 (修改端口/监听IP)"
echo "4. 退出 (Exit)"
read -p "请输入数字 [1-4]: " choice

# --- 辅助函数 ---
get_current_config() {
    SERVICE_FILE="/etc/systemd/system/cmy-tools.service"
    if [ -f "$SERVICE_FILE" ]; then
        CURRENT_PORT=$(grep -oP '(?<=--port )\d+' $SERVICE_FILE || echo "$DEFAULT_PORT")
        # 提取 host，兼容 IPv6 格式
        CURRENT_HOST=$(grep -oP '(?<=--host )[^ ]+' $SERVICE_FILE || echo "$DEFAULT_HOST")
    else
        CURRENT_PORT=$DEFAULT_PORT
        CURRENT_HOST=$DEFAULT_HOST
    fi
}

update_service_config() {
    local NEW_HOST=$1
    local NEW_PORT=$2
    SERVICE_FILE="/etc/systemd/system/cmy-tools.service"
    WORK_DIR=$(pwd)
    
    echo -e "${GREEN}🔧 更新系统服务配置...${NC}"
    echo "Host: $NEW_HOST, Port: $NEW_PORT"

    cat <<INI > $SERVICE_FILE
[Unit]
Description=CMY Tools Service
After=network.target
[Service]
User=root
WorkingDirectory=$WORK_DIR
ExecStart=$WORK_DIR/venv/bin/uvicorn backend.server:app --host $NEW_HOST --port $NEW_PORT
Restart=always
[Install]
WantedBy=multi-user.target
INI

    systemctl daemon-reload
    systemctl enable cmy-tools
    systemctl restart cmy-tools
    echo -e "${GREEN}✅ 服务已重启!${NC}"
    
    # 提示访问地址
    if [ "$NEW_HOST" == "::" ]; then
        echo -e "访问地址 (IPv6): http://[::1]:$NEW_PORT (请使用你的公网 IPv6)"
    else
        echo -e "访问地址 (IPv4): http://$(curl -s ifconfig.me):$NEW_PORT"
    fi
}

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

# --- 菜单逻辑 ---

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
    
    # 默认安装使用 :: (双栈) 和 8000
    update_service_config "::" "8000"

elif [ "$choice" == "2" ]; then
    echo -e "${GREEN}🚀 开始更新...${NC}"
    if [ -d "$PROJECT_NAME" ]; then cd $PROJECT_NAME; fi
    
    echo "⬇️ 拉取最新代码..."
    git stash
    git pull
    setup_backend
    build_frontend
    
    # 更新时保留当前配置
    get_current_config
    update_service_config "$CURRENT_HOST" "$CURRENT_PORT"

elif [ "$choice" == "3" ]; then
    if [ -d "$PROJECT_NAME" ]; then cd $PROJECT_NAME; fi
    get_current_config
    
    echo -e "${YELLOW}当前配置: Host=$CURRENT_HOST, Port=$CURRENT_PORT${NC}"
    echo "请选择监听模式:"
    echo "1. :: (推荐, 同时支持 IPv4 + IPv6)"
    echo "2. 0.0.0.0 (仅支持 IPv4)"
    echo "3. 127.0.0.1 (仅限本地反代用)"
    read -p "选择 [1-3] (留空保持不变): " host_choice
    
    NEW_HOST=$CURRENT_HOST
    case $host_choice in
        1) NEW_HOST="::" ;;
        2) NEW_HOST="0.0.0.0" ;;
        3) NEW_HOST="127.0.0.1" ;;
    esac
    
    read -p "请输入端口 [默认 $CURRENT_PORT]: " port_input
    NEW_PORT=${port_input:-$CURRENT_PORT}
    
    update_service_config "$NEW_HOST" "$NEW_PORT"

else
    echo "退出。"
    exit 0
fi
