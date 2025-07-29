from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, folders, templates, users, permissions, logs
from app.core.db import Base, engine
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Contract Management API",
    description="API для системы управления договорами",
    version="1.0.0",
    openapi_version="3.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",  # Разработка
        "https://contract.alnilam.by",  # Продакшен
        "https://www.contract.alnilam.by",  # Продакшен с www
        "https://178.172.138.229",  # IP адрес
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    """Health check endpoint for deployment scripts"""
    return {"status": "healthy", "service": "contract-management-api"}

app.include_router(auth.router, tags=["auth"])
app.include_router(folders.router, tags=["folders"])
app.include_router(templates.router, tags=["templates"])
app.include_router(users.router, tags=["users"])
app.include_router(permissions.router, tags=["permissions"])
app.include_router(logs.router, tags=["logs"]) 