from typing import Optional
from datetime import datetime
from sqlmodel import SQLModel, Field

class Task(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    platform: str
    url: str
    status: str = "pending"
    progress: float = 0.0
    download_speed: Optional[str] = "--"
    eta: Optional[str] = "--"
    filename: Optional[str] = None
    save_path: str = "downloads"
    error_message: Optional[str] = None
    live_logs: Optional[str] = "[]"
    created_at: datetime = Field(default_factory=datetime.now)
    
    # Auth & Config
    format_mode: str = "best"
    with_thumbnail: bool = True
    with_subs: bool = False
    cookies: Optional[str] = None
    x_auth_token: Optional[str] = None
    x_ct0: Optional[str] = None
    x_scope: str = "single"
    x_limit: int = 0
    weibo_scope: str = "all"

class TaskCreate(SQLModel):
    platform: str
    url: str
    save_path: str
    format_mode: str = "best"
    with_thumbnail: bool = True
    with_subs: bool = False
    cookies: Optional[str] = None
    x_auth_token: Optional[str] = None
    x_ct0: Optional[str] = None
    x_scope: str = "single"
    x_limit: int = 0
    weibo_scope: str = "all"
