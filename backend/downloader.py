import os
import shutil
import json
import subprocess
import re
import threading
import time
import requests
import yt_dlp
from sqlmodel import Session
from .models import Task
from .database import engine
from .config_manager import save_config, load_config

db_lock = threading.Lock()
task_events = {}

def update_db(task_id: int, **kwargs):
    with db_lock:
        try:
            with Session(engine) as session:
                task = session.get(Task, task_id)
                if task:
                    for k, v in kwargs.items(): setattr(task, k, v)
                    session.add(task)
                    session.commit()
                    session.refresh(task)
        except: pass

def append_log(task_id: int, line: str):
    print(f"[Task {task_id}] {line}", flush=True)
    with db_lock:
        try:
            with Session(engine) as session:
                task = session.get(Task, task_id)
                if task:
                    logs = json.loads(task.live_logs or "[]")
                    logs.append(line)
                    if len(logs) > 100: logs = logs[-100:]
                    task.live_logs = json.dumps(logs)
                    if len(line) < 60: task.download_speed = line
                    session.add(task)
                    session.commit()
        except: pass

def clean_ansi(text):
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)

def sanitize_cookie(raw):
    if not raw: return ""
    return raw.replace('\n', '').replace('\r', '').replace('Cookie:', '').strip()

def run_weibo_engine(task_id, task):
    append_log(task_id, "[Weibo] 启动 CMY 图片爬虫 (V1.0)...")
    url = task.url
    base_path = task.save_path
    cookie_str = sanitize_cookie(task.cookies)
    
    uid = ""
    if "weibo.com" in url:
        match = re.search(r'u/(\d+)', url) or re.search(r'weibo.com/(\w+)', url)
        if match: uid = match.group(1)
    if not uid:
        append_log(task_id, "[Error] 无法解析微博 UID")
        return

    global_config = load_config()
    p_url = global_config.get("proxy_url", "")
    proxies = {"http": p_url, "https": p_url} if p_url else None

    headers = {
        "User-Agent": "Mozilla/5.0 (Linux; Android 10; SM-G981B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.162 Mobile Safari/537.36",
        "Referer": f"https://m.weibo.cn/u/{uid}",
        "Cookie": cookie_str,
        "Accept": "application/json"
    }

    try:
        api_url = f"https://m.weibo.cn/api/container/getIndex?type=uid&value={uid}"
        res = requests.get(api_url, headers=headers, proxies=proxies, timeout=15)
        try: data = res.json()
        except: 
            append_log(task_id, "[Fatal] 微博 API 拒绝访问 (请检查 Cookie)")
            return

        if data.get("ok") != 1:
            append_log(task_id, f"[Error] API: {data.get('msg')}")
            return

        screen_name = data["data"]["userInfo"]["screen_name"]
        containerid = None
        for tab in data["data"]["tabsInfo"]["tabs"]:
            if tab["tab_type"] == "weibo":
                containerid = tab["containerid"]
                break
        
        folder_name = f"{uid}_{screen_name}"
        target_dir = os.path.join(base_path, folder_name)
        if not os.path.exists(target_dir): os.makedirs(target_dir, exist_ok=True)
        append_log(task_id, f"[Weibo] 目标目录: {folder_name}")

        page = 1
        new_count = 0
        skip_count = 0
        
        while True:
            if page % 5 == 1: append_log(task_id, f"[Scan] 扫描第 {page} 页...")
            feed_url = f"https://m.weibo.cn/api/container/getIndex?containerid={containerid}&page={page}"
            try:
                r = requests.get(feed_url, headers=headers, proxies=proxies, timeout=15)
                js = r.json()
                if js.get("ok") != 1: break
                cards = js.get("data", {}).get("cards", [])
                if not cards: break

                for card in cards:
                    if card["card_type"] != 9: continue
                    mblog = card["mblog"]
                    bid = mblog["id"]
                    pics = mblog.get("pics", [])
                    if "page_info" in mblog and mblog["page_info"].get("type") == "video":
                         if "page_pic" in mblog["page_info"]:
                             pics.append({"large": {"url": mblog["page_info"]["page_pic"]["url"]}})
                    
                    for idx, pic in enumerate(pics):
                        if "large" in pic:
                            img_url = pic["large"]["url"]
                            ext = img_url.split('.')[-1]
                            if len(ext) > 4: ext = "jpg"
                            fname = f"{bid}_{idx}.{ext}"
                            fpath = os.path.join(target_dir, fname)
                            
                            if os.path.exists(fpath):
                                skip_count += 1
                                continue
                            try:
                                c = requests.get(img_url, headers=headers, proxies=proxies, timeout=10).content
                                with open(fpath, "wb") as f: f.write(c)
                                new_count += 1
                                update_db(task_id, download_speed=f"已保存: {fname}")
                            except: pass
            except Exception as e:
                append_log(task_id, f"[Err] Page {page}: {e}")
            page += 1
            time.sleep(0.5 if new_count == 0 else 1.5)

        update_db(task_id, status="completed", progress=100.0)
        append_log(task_id, f"[Done] 新增: {new_count}, 跳过: {skip_count}")

    except Exception as e:
        append_log(task_id, f"[Fatal] {e}")

def run_tmd_engine(task_id, task, pause_event):
    append_log(task_id, "[TMD] 启动 V1.0 引擎...")
    tmd_bin = os.path.join(os.path.dirname(__file__), "bin", "tmd")
    if not os.path.exists(tmd_bin): raise Exception("缺少 TMD 二进制")
    
    target = task.url.strip()
    username = target.split('/')[-1].replace("@", "") if '/' in target else target.replace("@", "")
    
    save_path = os.path.abspath(task.save_path)
    if not os.path.exists(save_path): os.makedirs(save_path, exist_ok=True)
    append_log(task_id, f"[TMD] 目标: {save_path}")

    db_file = os.path.join(save_path, "download.db")
    if os.path.exists(db_file): 
        try: os.remove(db_file)
        except: pass

    env = os.environ.copy()
    env["HOME"] = save_path
    
    conf = load_config()
    if conf.get("proxy_url"):
        p = conf["proxy_url"]
        env["HTTP_PROXY"] = p
        env["HTTPS_PROXY"] = p
        env["ALL_PROXY"] = p
        append_log(task_id, f"[TMD] 代理: {p}")

    cmd = [tmd_bin, "--user", username]
    update_db(task_id, status="downloading", progress=1.0)
    
    try:
        process = subprocess.Popen(
            cmd, cwd=save_path, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            env=env, text=True, bufsize=1
        )
    except Exception as e: raise e

    try:
        if process.stdin:
            payload = f"{save_path}\n{task.x_auth_token}\n{task.x_ct0}\n5\n\n"
            process.stdin.write(payload)
            process.stdin.flush()
            process.stdin.close()
            append_log(task_id, "[TMD] 认证注入")
    except: pass

    has_data = False
    for line in process.stdout:
        if pause_event.is_set(): process.terminate(); raise Exception("Stopped")
        line = line.strip()
        if not line: continue
        clean = clean_ansi(line)
        if "enter" in clean.lower() and ":" in clean: continue
        append_log(task_id, clean)
        if "Download" in clean or "saved" in clean: has_data = True

    process.wait()
    final_dir = os.path.join(save_path, username)
    if os.path.exists(final_dir):
        update_db(task_id, status="completed", progress=100.0)
        append_log(task_id, f"[Success] 文件夹: {username}")
    elif has_data:
        update_db(task_id, status="completed", progress=100.0)
    else:
        update_db(task_id, status="completed", progress=100.0)
        append_log(task_id, "[Info] 完成")

class MyLogger:
    def __init__(self, task_id): self.task_id = task_id
    def debug(self, msg): pass
    def info(self, msg): append_log(self.task_id, msg)
    def warning(self, msg): append_log(self.task_id, f"[Warn] {msg}")
    def error(self, msg): append_log(self.task_id, f"[Err] {msg}")

def run_generic_engine(task_id, task):
    append_log(task_id, "[Generic] 启动 yt-dlp...")
    opts = {
        'outtmpl': f'{task.save_path}/%(uploader)s/%(title).100s.%(ext)s',
        'logger': MyLogger(task_id),
        'quiet': False, 'ignoreerrors': True, 'nocheckcertificate': True
    }
    try:
        with yt_dlp.YoutubeDL(opts) as ydl: ydl.download([task.url])
        update_db(task_id, status="completed", progress=100.0)
    except Exception as e: raise e

def process_download(task_id: int):
    pause_event = threading.Event()
    task_events[task_id] = pause_event
    
    with Session(engine) as session:
        task = session.get(Task, task_id)
        if not task: return
        updates = {}
        if task.platform == 'x' and task.x_auth_token:
            updates.update({"x_auth_token": task.x_auth_token, "x_ct0": task.x_ct0})
        if task.cookies: updates.update({"last_cookies": task.cookies})
        if updates: save_config(updates)
        platform = task.platform

    try:
        if platform == 'x':
            run_tmd_engine(task_id, task, pause_event)
        elif platform == 'weibo':
            run_weibo_engine(task_id, task)
        else:
            run_generic_engine(task_id, task)

    except Exception as e:
        msg = str(e)
        status = "paused" if "Stopped" in msg else "error"
        update_db(task_id, status=status, error_message=msg[:100])
        append_log(task_id, f"[Error] {msg}")
    finally:
        if task_id in task_events: del task_events[task_id]
