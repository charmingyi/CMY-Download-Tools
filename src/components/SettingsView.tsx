import React, { useState, useEffect } from 'react';
import { Save, Globe } from 'lucide-react';

const API = '';

export function SettingsView() {
  const [proxy, setProxy] = useState('');
  const [msg, setMsg] = useState('');

  useEffect(() => {
    fetch(\`\${API}/api/config\`).then(r => r.json()).then(data => { if(data.proxy_url) setProxy(data.proxy_url); });
  }, []);

  const handleSave = async () => {
    await fetch(\`\${API}/api/settings\`, {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ proxy_url: proxy })
    });
    setMsg('保存成功');
    setTimeout(() => setMsg(''), 2000);
  };

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      <h1 className="text-3xl font-bold mb-2">设置</h1>
      <div className="bg-white rounded-2xl p-8 border border-gray-100 shadow-sm">
        <h2 className="text-xl font-bold mb-4 flex items-center gap-2"><Globe className="w-5 h-5"/> 代理设置</h2>
        <input type="text" value={proxy} onChange={e => setProxy(e.target.value)} placeholder="http://127.0.0.1:7890" className="w-full p-3 border rounded-xl mb-4" />
        <button onClick={handleSave} className="px-6 py-2 bg-black text-white rounded-lg flex items-center gap-2"><Save className="w-4 h-4"/> 保存</button>
        {msg && <span className="ml-4 text-green-600">{msg}</span>}
      </div>
    </div>
  );
}
