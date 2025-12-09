#!/bin/bash
set -e

echo "🔧 正在全面修复前端语法错误并同步到 GitHub..."

# 1. 修复 src/components/NewTaskModal.tsx
cat << 'TSX' > src/components/NewTaskModal.tsx
import React, { useState, useEffect } from 'react';
import { X, Link as LinkIcon, Folder, Twitter, Cookie } from 'lucide-react';
import { Platform } from '../types';

interface Props { isOpen: boolean; onClose: () => void; onSubmit: (d: any) => void; }

function FileBrowser({ onSelect, currentPath }: any) {
  const [items, setItems] = useState<any[]>([]);
  const [path, setPath] = useState(currentPath);
  useEffect(() => {
    fetch(`/api/fs/list?path=${encodeURIComponent(path)}`).then(r=>r.json()).then(setItems).catch(()=>{});
  }, [path]);
  return (
    <div className="border rounded-lg bg-gray-50 h-32 overflow-y-auto p-2 text-sm mt-2">
      <div className="px-2 py-1 text-xs text-gray-400 border-b mb-1">{path}</div>
      {items.filter((i:any)=>i.is_dir).map((item:any) => (
        <div key={item.path} onClick={()=>{setPath(item.path);onSelect(item.path)}} 
             className="flex items-center gap-2 p-1 hover:bg-blue-100 cursor-pointer rounded">
          <Folder className="w-4 h-4 text-yellow-500"/><span className="truncate">{item.name}</span>
        </div>
      ))}
    </div>
  );
}

const PLATFORMS = [
  { id: 'weibo', name: 'Weibo', color: 'bg-orange-500' },
  { id: 'x', name: 'X / Twitter', color: 'bg-black' },
  { id: 'xiaohongshu', name: '小红书', color: 'bg-red-500' },
  { id: 'instagram', name: 'Instagram', color: 'bg-pink-600' },
];

export function NewTaskModal({ isOpen, onClose, onSubmit }: Props) {
  const [platform, setPlatform] = useState<Platform>('weibo');
  const [url, setUrl] = useState('');
  const [cookies, setCookies] = useState('');
  const [savePath, setSavePath] = useState('downloads');
  const [showBrowser, setShowBrowser] = useState(false);
  const [format, setFormat] = useState('best');
  
  const [xAuthToken, setXAuthToken] = useState('');
  const [xCt0, setXCt0] = useState('');
  const [weiboScope, setWeiboScope] = useState('all');

  useEffect(() => {
    if (isOpen) {
        fetch('/api/config').then(r => r.json()).then(config => {
            if (config.x_auth_token) setXAuthToken(config.x_auth_token);
            if (config.x_ct0) setXCt0(config.x_ct0);
            if (config.last_cookies) setCookies(config.last_cookies);
        }).catch(()=>{});
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({ 
      platform, url, cookies, save_path: savePath, format_mode: format, 
      x_auth_token: xAuthToken, x_ct0: xCt0, weibo_scope: weiboScope
    });
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 backdrop-blur-sm p-4">
      <div className="bg-white rounded-2xl w-full max-w-xl p-6 shadow-2xl overflow-y-auto max-h-[95vh]">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-bold">新建任务</h2>
          <button onClick={onClose}><X/></button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-5">
          <div className="flex gap-2">
            {PLATFORMS.map(p => (
              <button key={p.id} type="button" onClick={() => setPlatform(p.id as Platform)}
                className={`flex-1 py-2 rounded-lg text-sm font-medium ${platform === p.id ? p.color + ' text-white' : 'bg-gray-100 text-gray-600'}`}>
                {p.name}
              </button>
            ))}
          </div>

          <div className="relative">
            <LinkIcon className="absolute left-3 top-3.5 w-5 h-5 text-gray-400" />
            <input value={url} onChange={e => setUrl(e.target.value)} required 
              placeholder={platform === 'x' ? "输入用户ID (如 elonmusk)..." : "粘贴链接..."}
              className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl outline-none" />
          </div>

          {platform === 'x' && (
            <div className="bg-slate-50 p-4 rounded-xl space-y-3">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                 <input type="text" value={xAuthToken} onChange={e=>setXAuthToken(e.target.value)} placeholder="auth_token" className="w-full p-2 text-xs border rounded bg-white" />
                 <input type="text" value={xCt0} onChange={e=>setXCt0(e.target.value)} placeholder="ct0" className="w-full p-2 text-xs border rounded bg-white" />
              </div>
            </div>
          )}

          {platform === 'weibo' && (
             <div className="space-y-2">
                <div className="flex items-center justify-between">
                    <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
                        <Cookie className="w-4 h-4 text-orange-500" /> <span>Cookies (必填)</span>
                    </label>
                </div>
                <textarea value={cookies} onChange={e => setCookies(e.target.value)} placeholder="粘贴 SUB=... 或 完整Cookie" className="w-full p-3 bg-gray-50 border rounded-xl text-xs h-20" />
             </div>
          )}

          <div>
            <div className="flex gap-2 mb-1">
              <input value={savePath} readOnly className="flex-1 px-3 py-2 bg-gray-100 rounded-lg text-sm font-mono" />
              <button type="button" onClick={() => setShowBrowser(!showBrowser)} className="px-3 bg-gray-200 rounded-lg text-xs font-medium">更改</button>
            </div>
            {showBrowser && <FileBrowser currentPath={savePath} onSelect={setSavePath} />}
          </div>

          <button type="submit" className="w-full py-3 bg-black text-white rounded-xl font-bold shadow-lg">开始下载</button>
        </form>
      </div>
    </div>
  );
}
TSX

# 2. 修复 src/App.tsx
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

# 3. 修复 src/components/Sidebar.tsx
cat << 'TSX' > src/components/Sidebar.tsx
import React from 'react';
import { Home, Settings, Activity } from 'lucide-react';

interface SidebarProps {
  activeView: string;
  onViewChange: (view: string) => void;
}

export function Sidebar({ activeView, onViewChange }: SidebarProps) {
  const menuItems = [
    { id: 'dashboard', icon: Home, label: 'Dashboard' },
    { id: 'tasks', icon: Activity, label: 'Tasks' },
    { id: 'settings', icon: Settings, label: 'Settings' },
  ];

  return (
    <aside className="w-64 bg-white border-r border-gray-100 flex flex-col">
      <div className="p-8">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-black rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-lg">C</span>
          </div>
          <span className="font-semibold text-lg tracking-tight">CMY Tools v1.2.1</span>
        </div>
      </div>
      <nav className="flex-1 px-4 space-y-2">
        {menuItems.map((item) => (
          <button
            key={item.id}
            onClick={() => onViewChange(item.id)}
            className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
              activeView === item.id 
                ? 'bg-gray-900 text-white shadow-lg' 
                : 'text-gray-500 hover:bg-gray-50'
            }`}
          >
            <item.icon className="w-5 h-5" />
            <span className="font-medium">{item.label}</span>
          </button>
        ))}
      </nav>
    </aside>
  );
}
TSX

# 4. 推送到 GitHub
echo "⬆️ 推送修复代码到 GitHub..."
git add .
git commit -m "Final fix for frontend syntax errors"
git push

echo "✅ GitHub 仓库已完全修复！现在请去新服务器更新。"
