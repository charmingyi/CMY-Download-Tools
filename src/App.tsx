import React, { useState, useEffect } from 'react';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { TaskList } from './components/TaskList';
import { NewTaskModal } from './components/NewTaskModal';
import { SettingsView } from './components/SettingsView';
import { Task } from './types';

const API = import.meta.env.DEV ? 'http://localhost:8000' : '';

export default function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [modalOpen, setModalOpen] = useState(false);
  const [view, setView] = useState('dashboard');

  const refresh = async () => {
    try {
      const res = await fetch(\`\${API}/api/tasks\`);
      if (res.ok) setTasks(await res.json());
    } catch (e) {}
  };

  useEffect(() => { 
    if (view === 'dashboard' || view === 'tasks') {
        refresh(); 
        const i = setInterval(refresh, 2000); 
        return () => clearInterval(i); 
    }
  }, [view]);

  const createTask = async (data: any) => {
    await fetch(\`\${API}/api/tasks\`, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify(data)
    });
    refresh(); setView('dashboard');
  };

  return (
    <div className="flex h-screen bg-[#FAFAFA] text-gray-900 font-sans">
      <Sidebar activeView={view} onViewChange={setView} />
      <main className="flex-1 flex flex-col h-screen overflow-hidden">
        <Header />
        <div className="p-6 md:p-10 flex-1 overflow-y-auto">
           {view === 'settings' ? <SettingsView /> : (
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
