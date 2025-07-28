from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, folders, templates, users, permissions, logs
from app.core.db import Base, engine
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Contract Management API")

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # Разрешаем запросы с фронтенда
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, tags=["auth"])
app.include_router(folders.router, tags=["folders"])
app.include_router(templates.router, tags=["templates"])
app.include_router(users.router, tags=["users"])
app.include_router(permissions.router, tags=["permissions"])
app.include_router(logs.router, tags=["logs"]) 