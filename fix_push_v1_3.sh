#!/bin/bash
set -e

echo "🔧 正在修复语法错误并生成 V1.3 升级脚本..."

# 1. 修复 src/App.tsx (去除错误的转义符)
cat << 'TSX' > src/App.tsx
import React, { useState, useEffect } from 'react';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { TaskList } from './components/TaskList';
import { NewTaskModal } from './components/NewTaskModal';
import { SettingsView } from './components/SettingsView';
import { Login } from './components/Login';
import { Task } from './types';

const API = import.meta.env.DEV ? 'http://localhost:8000' : '';

export default function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [view, setView] = useState('dashboard');
  const [authed, setAuthed] = useState(false);
  const [role, setRole] = useState('guest');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`${API}/api/auth_check`)
      .then(r => r.json())
      .then(data => {
         if (!data.locked) { setAuthed(true); setRole('admin'); } 
         else if (data.authed) { setAuthed(true); setRole(data.role); }
         setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const refresh = async () => {
    try {
      const res = await fetch(`${API}/api/tasks`);
      if (res.ok) setTasks(await res.json());
      else if (res.status === 401) setAuthed(false);
    } catch (e) {}
  };

  useEffect(() => { 
    if (authed && (view === 'dashboard' || view === 'tasks')) {
        refresh(); 
        const i = setInterval(refresh, 2000); 
        return () => clearInterval(i); 
    }
  }, [view, authed]);

  const createTask = async (data: any) => {
    await fetch(`${API}/api/tasks`, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(data)
    });
    refresh(); setView('dashboard');
  };

  const handleLogin = (r: string) => { setRole(r); setAuthed(true); };
  const handleLogout = async () => {
      await fetch(`${API}/api/logout`, { method: 'POST' });
      setAuthed(false); setRole('guest');
  };

  if (loading) return <div className="h-screen flex items-center justify-center">Loading...</div>;
  if (!authed) return <Login onLogin={handleLogin} />;

  return (
    <div className="flex h-screen bg-[#FAFAFA] text-gray-900 font-sans">
      <Sidebar activeView={view} onViewChange={setView} />
      <main className="flex-1 flex flex-col h-screen overflow-hidden">
        <div className="h-16 bg-white/50 backdrop-blur-md border-b border-gray-100 px-8 flex items-center justify-between sticky top-0 z-20">
            <div className="flex items-center gap-4 text-gray-400">
                <span className="text-sm font-medium">V1.2.1 {role === 'guest' ? '(Guest)' : '(Admin)'}</span>
            </div>
            <button onClick={handleLogout} className="text-sm text-red-500 hover:underline">退出</button>
        </div>
        <div className="p-6 md:p-10 flex-1 overflow-y-auto">
           {view === 'settings' ? (
              role === 'admin' ? <SettingsView /> : <div className="text-center p-20 text-gray-400">访客无法访问设置</div>
           ) : (
              <div className="max-w-6xl mx-auto">
                <div className="flex justify-between items-end mb-8">
                  <h1 className="text-3xl font-bold">下载中心</h1>
                  <button onClick={() => setModalOpen(true)} className="px-5 py-2.5 bg-black text-white rounded-xl shadow-lg">+ 新建任务</button>
                </div>
                <TaskList tasks={tasks} onRefresh={refresh} />
              </div>
           )}
        </div>
      </main>
      <NewTaskModal isOpen={modalOpen} onClose={() => setModalOpen(false)} onSubmit={createTask} />
    </div>
  );
}
TSX

# 2. 修复 src/components/TaskList.tsx
cat << 'TSX' > src/components/TaskList.tsx
import React, { useState } from 'react';
import { Task } from '../types';
import { Download, CheckCircle, AlertCircle, Pause, Play, Trash2, ChevronDown, ChevronUp } from 'lucide-react';

const API = '';

export function TaskList({ tasks, onRefresh }: { tasks: Task[], onRefresh: () => void }) {
  const [expandedId, setExpandedId] = useState<number | null>(null);

  const handlePause = async (id: number) => {
    await fetch(`${API}/api/tasks/${id}/pause`, { method: 'POST' });
    onRefresh();
  };
  const handleResume = async (id: number) => {
    await fetch(`${API}/api/tasks/${id}/resume`, { method: 'POST' });
    onRefresh();
  };
  const handleDelete = async (id: number) => {
    if(!confirm('确定要删除记录吗？')) return;
    await fetch(`${API}/api/tasks/${id}`, { method: 'DELETE' });
    onRefresh();
  };
  const toggleLogs = (id: number) => setExpandedId(expandedId === id ? null : id);

  if (tasks.length === 0) return <div className="text-center py-10 text-gray-400">暂无任务</div>;

  return (
    <div className="space-y-4">
      {tasks.map((task) => {
        let logs: string[] = [];
        try { logs = JSON.parse(task.live_logs || "[]"); } catch {}
        return (
          <div key={task.id} className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden hover:shadow-md">
            <div className="p-4 flex items-center gap-4">
              <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${
                 task.status === 'completed' ? 'bg-green-100 text-green-600' :
                 task.status === 'error' ? 'bg-red-100 text-red-600' :
                 task.status === 'paused' ? 'bg-yellow-100 text-yellow-600' : 'bg-blue-100 text-blue-600'
              }`}>
                 {task.status === 'completed' ? <CheckCircle className="w-5 h-5"/> :
                  task.status === 'paused' ? <Pause className="w-5 h-5"/> :
                  task.status === 'error' ? <AlertCircle className="w-5 h-5"/> : <Download className="w-5 h-5 animate-pulse"/>}
              </div>
              <div className="flex-1 min-w-0">
                 <div className="flex justify-between mb-1">
                    <h3 className="font-bold text-gray-800 truncate text-sm">{task.url}</h3>
                    <div className="flex items-center gap-2">
                         <span className="text-xs font-mono text-gray-400">{task.status.toUpperCase()}</span>
                         <button onClick={() => toggleLogs(task.id)} className="text-gray-400 hover:text-black">
                            {expandedId === task.id ? <ChevronUp className="w-4 h-4"/> : <ChevronDown className="w-4 h-4"/>}
                         </button>
                    </div>
                 </div>
                 <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden mb-1">
                    <div className={`h-full transition-all duration-500 ${task.status === 'error' ? 'bg-red-500' : 'bg-black'}`} style={{ width: `${task.progress}%` }} />
                 </div>
                 <div className="text-xs text-gray-500 font-mono truncate">
                    {task.error_message ? <span className="text-red-500">{task.error_message}</span> : task.download_speed}
                 </div>
              </div>
              <div className="flex items-center gap-2">
                 {(task.status === 'downloading' || task.status === 'pending') && (
                    <button onClick={() => handlePause(task.id)} className="p-2 bg-yellow-50 text-yellow-600 rounded-lg"><Pause className="w-4 h-4"/></button>
                 )}
                 {(task.status === 'paused' || task.status === 'error') && (
                    <button onClick={() => handleResume(task.id)} className="p-2 bg-green-50 text-green-600 rounded-lg"><Play className="w-4 h-4"/></button>
                 )}
                 <button onClick={() => handleDelete(task.id)} className="p-2 bg-red-50 text-red-500 rounded-lg"><Trash2 className="w-4 h-4"/></button>
              </div>
            </div>
            {expandedId === task.id && (
              <div className="bg-gray-900 p-3 border-t border-gray-800">
                 <div className="font-mono text-[10px] text-green-400 space-y-0.5 h-32 overflow-y-auto">
                    {logs.map((line, i) => <div key={i} className="break-all">{line}</div>)}
                 </div>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
TSX

# 3. 生成 install.sh (包含升级功能)
cat << 'EOF_INSTALL' > install.sh
#!/bin/bash
set -e

REPO_URL="https://github.com/charmingyi/CMY-Download-Tools.git"
PROJECT_NAME="CMY-Download-Tools"
PORT=8000

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

restart_service() {
    echo -e "${GREEN}🔄 重启服务...${NC}"
    pkill -f uvicorn || true
    pkill -f tmd || true
    if systemctl is-active --quiet cmy-tools; then
        systemctl restart cmy-tools
    else
        nohup uvicorn backend.server:app --host 0.0.0.0 --port $PORT > system.log 2>&1 &
    fi
    echo -e "${GREEN}✅ 完成！访问地址: http://$(curl -s ifconfig.me):$PORT${NC}"
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
    
    WORK_DIR=$(pwd)
    SERVICE_FILE="/etc/systemd/system/cmy-tools.service"
    cat <<INI > $SERVICE_FILE
[Unit]
Description=CMY Tools Service
After=network.target
[Service]
User=root
WorkingDirectory=$WORK_DIR
ExecStart=$WORK_DIR/venv/bin/uvicorn backend.server:app --host 0.0.0.0 --port $PORT
Restart=always
[Install]
WantedBy=multi-user.target
INI
    systemctl daemon-reload
    systemctl enable cmy-tools
    systemctl start cmy-tools
    echo -e "${GREEN}✅ 安装并启动完成！${NC}"

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
    restart_service

else
    echo "退出。"
    exit 0
fi
EOF_INSTALL
chmod +x install.sh

# 4. 推送到 GitHub
echo "⬆️ 推送修复到 GitHub..."
git add src/App.tsx src/components/TaskList.tsx install.sh
git commit -m "Fix frontend syntax errors and add upgrade menu script"
git push

echo "✅ 修复完成！现在请去新服务器运行: bash install.sh 并选择 2 (更新升级)"
