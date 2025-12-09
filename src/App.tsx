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
         if (!data.locked) {
             setAuthed(true); 
             setRole('admin'); 
         } else if (data.authed) {
             setAuthed(true);
             setRole(data.role);
         }
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

  const handleLogin = (r: string) => {
      setRole(r);
      setAuthed(true);
  };

  const handleLogout = async () => {
      await fetch(`${API}/api/logout`, { method: 'POST' });
      setAuthed(false);
      setRole('guest');
  };

  if (loading) return <div className="h-screen flex items-center justify-center">Loading...</div>;
  if (!authed) return <Login onLogin={handleLogin} />;

  return (
    <div className="flex h-screen bg-[#FAFAFA] text-gray-900 font-sans">
      <Sidebar activeView={view} onViewChange={setView} />
      <main className="flex-1 flex flex-col h-screen overflow-hidden">
        <div className="h-16 bg-white/50 backdrop-blur-md border-b border-gray-100 px-8 flex items-center justify-between sticky top-0 z-20">
            <div className="flex items-center gap-4 text-gray-400">
                <span className="text-sm font-medium">V1.2.1 {role === 'guest' ? '(Guest Mode)' : '(Admin)'}</span>
            </div>
            <button onClick={handleLogout} className="text-sm text-red-500 hover:underline">退出登录</button>
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
