from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.db import get_db
from app.services.settings_service import SettingsService
from app.api.auth import get_current_user
from app.models.user import User
from pydantic import BaseModel

router = APIRouter(prefix="/settings", tags=["settings"])

class SettingCreate(BaseModel):
    key: str
    value: str
    description: str = None

class SettingUpdate(BaseModel):
    value: str
    description: str = None

class SettingResponse(BaseModel):
    id: int
    key: str
    value: str
    description: str = None
    created_at: str
    updated_at: str = None

@router.get("/")
async def get_settings(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Получает все настройки (только для администраторов)"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Доступ запрещен")
    
    settings_service = SettingsService(db)
    settings = settings_service.get_all_settings()
    
    return {
        "data": [
            {
                "id": setting.id,
                "key": setting.key,
                "value": setting.value,
                "description": setting.description,
                "created_at": setting.created_at.isoformat(),
                "updated_at": setting.updated_at.isoformat() if setting.updated_at else None
            }
            for setting in settings
        ]
    }

@router.get("/{key}")
async def get_setting(
    key: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Получает значение настройки по ключу"""
    settings_service = SettingsService(db)
    value = settings_service.get_setting(key)
    
    if value is None:
        raise HTTPException(status_code=404, detail="Настройка не найдена")
    
    return {"key": key, "value": value}

@router.post("/")
async def create_setting(
    setting: SettingCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Создает новую настройку (только для администраторов)"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Доступ запрещен")
    
    settings_service = SettingsService(db)
    new_setting = settings_service.set_setting(
        key=setting.key,
        value=setting.value,
        description=setting.description
    )
    
    return {
        "id": new_setting.id,
        "key": new_setting.key,
        "value": new_setting.value,
        "description": new_setting.description,
        "created_at": new_setting.created_at.isoformat()
    }

@router.put("/{key}")
async def update_setting(
    key: str,
    setting: SettingUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Обновляет настройку (только для администраторов)"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Доступ запрещен")
    
    settings_service = SettingsService(db)
    updated_setting = settings_service.set_setting(
        key=key,
        value=setting.value,
        description=setting.description
    )
    
    return {
        "id": updated_setting.id,
        "key": updated_setting.key,
        "value": updated_setting.value,
        "description": updated_setting.description,
        "updated_at": updated_setting.updated_at.isoformat() if updated_setting.updated_at else None
    }

@router.delete("/{key}")
async def delete_setting(
    key: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Удаляет настройку (только для администраторов)"""
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Доступ запрещен")
    
    settings_service = SettingsService(db)
    success = settings_service.delete_setting(key)
    
    if not success:
        raise HTTPException(status_code=404, detail="Настройка не найдена")
    
    return {"message": "Настройка успешно удалена"} 