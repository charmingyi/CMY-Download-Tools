import React, { useState } from 'react';
import { Lock, User } from 'lucide-react';

export function Login({ onLogin }: { onLogin: (role: string) => void }) {
  const [pwd, setPwd] = useState('');
  const [err, setErr] = useState('');

  const handleAdminLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
        const res = await fetch('/api/login', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ password: pwd, type: 'admin' })
        });
        if (res.ok) {
            const data = await res.json();
            onLogin(data.role);
        } else {
            setErr('密码错误');
        }
    } catch(e) { setErr('登录失败'); }
  };

  const handleGuestLogin = async () => {
    try {
        const res = await fetch('/api/login', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ type: 'guest' })
        });
        if (res.ok) {
            onLogin('guest');
        }
    } catch(e) { setErr('访客模式不可用'); }
  };

  return (
    <div className="flex h-screen items-center justify-center bg-gray-100">
      <div className="bg-white p-8 rounded-2xl shadow-xl w-full max-w-md">
        <div className="flex justify-center mb-6">
            <div className="p-3 bg-black rounded-full"><Lock className="w-6 h-6 text-white"/></div>
        </div>
        <h2 className="text-center text-xl font-bold mb-6">系统访问受限</h2>
        
        <form onSubmit={handleAdminLogin}>
            <input 
                type="password" 
                value={pwd} 
                onChange={e=>setPwd(e.target.value)} 
                placeholder="请输入管理员密码..."
                className="w-full p-3 border rounded-xl mb-4 focus:ring-2 focus:ring-black outline-none"
            />
            {err && <p className="text-red-500 text-sm mb-4 text-center">{err}</p>}
            <button type="submit" className="w-full py-3 bg-black text-white rounded-xl font-bold hover:bg-gray-800 transition-colors">
                管理员进入
            </button>
        </form>

        <div className="relative my-6">
            <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-gray-200"></div></div>
            <div className="relative flex justify-center text-sm"><span className="px-2 bg-white text-gray-500">或者</span></div>
        </div>

        <button onClick={handleGuestLogin} className="w-full py-3 bg-gray-100 text-gray-700 rounded-xl font-bold hover:bg-gray-200 transition-colors flex items-center justify-center gap-2">
            <User className="w-4 h-4" /> 访客模式 (仅下载)
        </button>
      </div>
    </div>
  );
}
