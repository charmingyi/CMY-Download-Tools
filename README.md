# CMY Download Tools (V1.0)

## 🚀 部署指南

### 1. 基础环境
\`\`\`bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nodejs npm git wget ffmpeg
\`\`\`

### 2. 克隆与安装
\`\`\`bash
git clone https://github.com/charmingyi/CMY-Download-Tools.git
cd CMY-Download-Tools

# 后端
python3 -m venv venv
source venv/bin/activate
pip install -r backend/requirements.txt
mkdir -p backend/bin
wget -O backend/bin/tmd https://github.com/unkmonster/tmd/releases/latest/download/tmd-Linux-amd64
chmod 777 backend/bin/tmd

# 前端
npm install
npm run build
\`\`\`

### 3. 运行
\`\`\`bash
source venv/bin/activate
uvicorn backend.server:app --host 0.0.0.0 --port 8000
\`\`\`
