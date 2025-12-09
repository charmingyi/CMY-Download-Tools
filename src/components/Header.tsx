import React from 'react';
import { User } from 'lucide-react';

export function Header() {
  return (
    <header className="h-16 bg-white/50 backdrop-blur-md border-b border-gray-100 px-8 flex items-center justify-between sticky top-0 z-20">
      <div className="flex items-center gap-4 text-gray-400">
        <span className="text-sm font-medium">V1.0 Stable</span>
      </div>
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 bg-black rounded-full flex items-center justify-center text-white">
          <User className="w-4 h-4" />
        </div>
      </div>
    </header>
  );
}
