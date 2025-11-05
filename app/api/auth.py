from fastapi import APIRouter, Depends, HTTPException, status, Request, Response
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.core.db import get_db
from app.core.security import (
    verify_password, 
    create_access_token, 
    get_current_user,
    generate_csrf_token,
    CSRF_COOKIE_NAME,
    JWT_COOKIE_NAME
)
from app.core.config import settings
from app.models.user import User
from app.schemas.user import UserCreate, UserOut
from app.services.user_service import create_user, get_user_by_username, activate_user
from datetime import timedelta
from pydantic import BaseModel

router = APIRouter(prefix="/auth", tags=["auth"])

class LoginRequest(BaseModel):
    username: str
    password: str

class RegisterRequest(BaseModel):
    username: str
    email: str
    password: str

class ActivateUserRequest(BaseModel):
    user_id: int

def format_datetime(dt):
    """Форматирует дату в читаемый формат для фронтенда"""
    if dt is None:
        return None
    if isinstance(dt, str):
        return dt
    # Форматируем в формат ДД.ММ.ГГГГ ЧЧ:ММ
    return dt.strftime("%d.%m.%Y %H:%M")

@router.post("/login")
async def login(
    login_data: LoginRequest,
    response: Response,
    db: Session = Depends(get_db)
):
    """Авторизация пользователя"""
    user = get_user_by_username(db, login_data.username)
    
    if not user or not verify_password(login_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверное имя пользователя или пароль"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Пользователь не активирован"
        )
    
    # Создаем токен
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, 
        expires_delta=access_token_expires
    )
    
    # Генерируем CSRF токен
    csrf_token = generate_csrf_token()
    
    # Устанавливаем cookies
    response.set_cookie(
        key=JWT_COOKIE_NAME,
        value=access_token,
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )
    response.set_cookie(
        key=CSRF_COOKIE_NAME,
        value=csrf_token,
        httponly=False,
        secure=True,
        samesite="lax",
        max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )
    
    # Форматируем дату для фронтенда
    user_data = {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "is_active": user.is_active,
        "is_admin": user.is_admin,
        "date_joined": format_datetime(user.date_joined)
    }
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user_data,
        "csrf_token": csrf_token
    }

@router.post("/register")
async def register(
    register_data: RegisterRequest,
    db: Session = Depends(get_db)
):
    """Регистрация нового пользователя"""
    # Проверяем, существует ли пользователь
    if get_user_by_username(db, register_data.username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Пользователь с таким именем уже существует"
        )
    
    # Создаем пользователя
    user_create = UserCreate(
        username=register_data.username,
        email=register_data.email,
        password=register_data.password
    )
    
    user = create_user(db, user_create)
    
    return {
        "message": "Пользователь успешно зарегистрирован",
        "user_id": user.id,
        "username": user.username
    }

@router.post("/logout")
async def logout(response: Response):
    """Выход из системы"""
    response.delete_cookie(key=JWT_COOKIE_NAME)
    response.delete_cookie(key=CSRF_COOKIE_NAME)
    return {"message": "Выход выполнен успешно"}

@router.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    """Получение информации о текущем пользователе"""
    user_data = {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "is_active": current_user.is_active,
        "is_admin": current_user.is_admin,
        "date_joined": format_datetime(current_user.date_joined)
    }
    return user_data

@router.get("/csrf-token")
async def get_csrf_token(response: Response):
    """Получение CSRF токена"""
    csrf_token = generate_csrf_token()
    response.set_cookie(
        key=CSRF_COOKIE_NAME,
        value=csrf_token,
        httponly=False,
        secure=True,
        samesite="lax",
        max_age=3600
    )
    return {"csrf_token": csrf_token}

@router.post("/activate-user")
async def activate_user_endpoint(
    activate_data: ActivateUserRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_user)
):
    """Активация пользователя (только для администраторов)"""
    if not admin.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Требуются права администратора"
        )
    
    user = activate_user(db, activate_data.user_id, True)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Пользователь не найден"
        )
    
    return {
        "message": f"Пользователь {user.username} успешно активирован",
        "user_id": user.id
    }

