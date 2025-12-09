import React from 'react';
import { Home, HardDrive, Settings, Activity } from 'lucide-react';

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
          <span className="font-semibold text-lg tracking-tight">CMY Tools</span>
        </div>
      </div>
      
      <nav className="flex-1 px-4 space-y-2">
        {menuItems.map((item) => (
          <button
            key={item.id}
            onClick={() => onViewChange(item.id)}
            className={\`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 \${
              activeView === item.id 
                ? 'bg-gray-900 text-white shadow-lg' 
                : 'text-gray-500 hover:bg-gray-50'
            }\`}
          >
            <item.icon className="w-5 h-5" />
            <span className="font-medium">{item.label}</span>
          </button>
        ))}
      </nav>
    </aside>
  );
}
