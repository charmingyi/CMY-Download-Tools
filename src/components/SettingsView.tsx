import React, { useState, useEffect } from 'react';
import { Save, Globe, Lock } from 'lucide-react';

const API = import.meta.env.DEV ? 'http://localhost:8000' : '';

export function SettingsView() {
  const [proxy, setProxy] = useState('');
  const [password, setPassword] = useState('');
  const [msg, setMsg] = useState('');

  useEffect(() => {
    fetch(`${API}/api/config`).then(r => r.json()).then(data => { 
        if(data.proxy_url) setProxy(data.proxy_url); 
    });
  }, []);

  const handleSaveProxy = async () => {
    await fetch(`${API}/api/settings`, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ proxy_url: proxy })
    });
    setMsg('代理设置已保存');
    setTimeout(() => setMsg(''), 2000);
  };

  const handleSavePassword = async () => {
    await fetch(`${API}/api/settings/password`, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ password: password })
    });
    setMsg('密码设置已更新 (刷新生效)');
    setTimeout(() => setMsg(''), 2000);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      <h1 className="text-3xl font-bold mb-2">系统设置</h1>
      
      <div className="bg-white rounded-2xl p-8 border border-gray-100 shadow-sm">
        <h2 className="text-xl font-bold mb-4 flex items-center gap-2"><Globe className="w-5 h-5"/> 网络代理</h2>
        <div className="flex gap-4">
            <input type="text" value={proxy} onChange={e => setProxy(e.target.value)} placeholder="http://127.0.0.1:7890" className="flex-1 p-3 border rounded-xl" />
            <button onClick={handleSaveProxy} className="px-6 bg-black text-white rounded-xl font-bold">保存</button>
        </div>
      </div>

      <div className="bg-white rounded-2xl p-8 border border-gray-100 shadow-sm">
        <h2 className="text-xl font-bold mb-4 flex items-center gap-2"><Lock className="w-5 h-5"/> 安全访问</h2>
        <p className="text-sm text-gray-500 mb-4">设置网页访问密码。留空并保存则关闭密码锁。</p>
        <div className="flex gap-4">
            <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="输入新密码 (留空则清除)" className="flex-1 p-3 border rounded-xl" />
            <button onClick={handleSavePassword} className="px-6 bg-blue-600 text-white rounded-xl font-bold">更新密码</button>
        </div>
      </div>
      
      {msg && <div className="fixed bottom-10 right-10 bg-black text-white px-6 py-3 rounded-xl shadow-lg animate-bounce">{msg}</div>}
    </div>
  );
}
