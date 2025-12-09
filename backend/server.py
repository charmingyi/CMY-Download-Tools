import os
from fastapi import FastAPI, BackgroundTasks, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlmodel import Session, select
from .models import Task, TaskCreate
from .database import create_db_and_tables, engine
from .downloader import process_download, task_events
from .config_manager import load_config, save_config

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

@app.get("/api/config")
def get_config(): return load_config()

@app.post("/api/settings")
def update_settings(data: dict = Body(...)):
    save_config(data)
    return {"status": "ok"}

@app.post("/api/tasks")
def create_task(task_in: TaskCreate, bg: BackgroundTasks):
    with Session(engine) as session:
        task = Task.from_orm(task_in)
        session.add(task)
        session.commit()
        session.refresh(task)
        bg.add_task(process_download, task.id)
        return task

@app.post("/api/tasks/{task_id}/pause")
def pause_task(task_id: int):
    if task_id in task_events: task_events[task_id].set()
    with Session(engine) as session:
        task = session.get(Task, task_id)
        if task:
            task.status = "paused"
            session.add(task)
            session.commit()
    return {"status": "paused"}

@app.post("/api/tasks/{task_id}/resume")
def resume_task(task_id: int, bg: BackgroundTasks):
    with Session(engine) as session:
        task = session.get(Task, task_id)
        if not task: raise HTTPException(404)
        task.status = "pending"
        session.add(task)
        session.commit()
        bg.add_task(process_download, task.id)
    return {"status": "resuming"}

@app.get("/api/tasks")
def get_tasks():
    with Session(engine) as session:
        return session.exec(select(Task).order_by(Task.created_at.desc())).all()

@app.get("/api/fs/list")
def list_files(path: str = "."):
    try:
        real_path = os.path.abspath(path)
        items = []
        parent = os.path.dirname(real_path)
        if parent != real_path: items.append({"name": "..", "path": parent, "is_dir": True})
        for entry in os.scandir(real_path):
            items.append({"name": entry.name, "path": entry.path, "is_dir": entry.is_dir()})
        items.sort(key=lambda x: (not x['is_dir'], x['name']))
        return items
    except: return []

dist_path = os.path.join(os.path.dirname(__file__), "..", "dist")
if os.path.exists(dist_path):
    app.mount("/", StaticFiles(directory=dist_path, html=True), name="static")
