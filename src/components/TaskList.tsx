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
