from sqlmodel import SQLModel, create_engine
import os

os.makedirs("data", exist_ok=True)
sqlite_file_name = "data/database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"

engine = create_engine(sqlite_url, connect_args={"check_same_thread": False})

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)
