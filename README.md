# CMY Download Tools (V1.0)

一个基于 Web 的极简社交媒体下载器，专为个人媒体归档设计。

## ✨ 功能特点

* **X (Twitter)**: 使用 TMD 内核，支持 `User Media` 批量下载，自动隔离环境，支持代理。
* **微博 (Weibo)**: 内置 Python 爬虫，**只抓取高清原图**（无视视频报错），支持无限翻页和增量更新（跳过已下载）。
* **配置记忆**: 自动记住你的 Token 和 Cookies。
* **Web 界面**: 响应式管理面板，实时黑色终端日志。

---

## 🚀 极速部署指南 (Quick Start)

支持在任何 **Debian / Ubuntu** 新服务器上一键安装。

### 方法一：一键脚本 (推荐)

复制下面的命令在服务器终端运行，全程自动安装环境、依赖并启动服务。

\`\`\`bash
# 下载并运行安装脚本
wget https://raw.githubusercontent.com/charmingyi/CMY-Download-Tools/main/install.sh -O install.sh && chmod +x install.sh && bash install.sh
\`\`\`

### 方法二：手动部署

<details>
<summary>点击展开手动步骤</summary>

1. **安装基础环境**
   \`\`\`bash
   sudo apt update
   sudo apt install -y python3 python3-pip python3-venv nodejs npm git wget ffmpeg
   \`\`\`

2. **克隆代码**
   \`\`\`bash
   git clone https://github.com/charmingyi/CMY-Download-Tools.git
   cd CMY-Download-Tools
   \`\`\`

3. **后端部署**
   \`\`\`bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r backend/requirements.txt
   
   mkdir -p backend/bin
   wget -O backend/bin/tmd https://github.com/unkmonster/tmd/releases/latest/download/tmd-Linux-amd64
   chmod 777 backend/bin/tmd
   \`\`\`

4. **前端编译**
   \`\`\`bash
   npm install
   npm run build
   \`\`\`

5. **启动服务**
   \`\`\`bash
   uvicorn backend.server:app --host :: --port 8000
   \`\`\`
</details>

---

## 📖 使用指南

1.  **设置代理 (重要)**: 首次进入网页，点击左侧 \`Settings\`，填入你的代理地址 (如 \`http://127.0.0.1:7890\`)。X 和微博抓取都需要它。
2.  **下载 X**: 选择 \`X\`，输入 \`@用户名\`，填入 \`auth_token\` 和 \`ct0\`。
3.  **下载微博**: 选择 \`Weibo\`，输入主页链接，**必须在 Cookie 栏填入 \`SUB=xxxx...\`**。

