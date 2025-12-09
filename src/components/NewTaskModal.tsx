import React, { useState, useEffect } from 'react';
import { X, Link as LinkIcon, Folder, Twitter, Cookie } from 'lucide-react';
import { Platform } from '../types';

interface Props { isOpen: boolean; onClose: () => void; onSubmit: (d: any) => void; }

function FileBrowser({ onSelect, currentPath }: any) {
  const [items, setItems] = useState<any[]>([]);
  const [path, setPath] = useState(currentPath);
  useEffect(() => {
    fetch(\`/api/fs/list?path=\${encodeURIComponent(path)}\`).then(r=>r.json()).then(setItems).catch(()=>{});
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
  
  const [xAuthToken, setXAuthToken] = useState('');
  const [xCt0, setXCt0] = useState('');

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
    onSubmit({ platform, url, cookies, save_path: savePath, x_auth_token: xAuthToken, x_ct0: xCt0 });
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
                className={\`flex-1 py-2 rounded-lg text-sm font-medium \${platform === p.id ? p.color + ' text-white' : 'bg-gray-100 text-gray-600'}\`}>
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
                 <input type="text" value={xAuthToken} onChange={e=>setXAuthToken(e.target.value)} placeholder="auth_token (必填)" className="w-full p-2 text-xs border rounded bg-white" />
                 <input type="text" value={xCt0} onChange={e=>setXCt0(e.target.value)} placeholder="ct0 (必填)" className="w-full p-2 text-xs border rounded bg-white" />
              </div>
            </div>
          )}

          {platform === 'weibo' && (
             <div className="space-y-2">
                <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
                    <Cookie className="w-4 h-4 text-orange-500" /> <span>Cookies (必填)</span>
                </label>
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
