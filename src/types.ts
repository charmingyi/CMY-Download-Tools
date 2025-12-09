export type Platform = 'weibo' | 'x' | 'instagram' | 'telegram' | 'xiaohongshu' | 'youtube';
export interface Task {
  id: number;
  platform: Platform;
  url: string;
  status: 'pending' | 'downloading' | 'completed' | 'error' | 'paused';
  progress: number;
  download_speed: string;
  eta: string;
  filename?: string;
  error_message?: string;
  save_path: string;
  live_logs?: string;
}
