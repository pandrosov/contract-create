from fastapi import APIRouter, Depends, HTTPException, status, Response, Request
from sqlalchemy.orm import Session
from fastapi.security import OAuth2PasswordRequestForm
from app.schemas.user import UserCreate, UserOut
from app.services.user_service import create_user, get_user_by_username, activate_user
from app.core.db import get_db
from app.core.security import verify_password, create_access_token, get_current_user, require_admin, generate_csrf_token, CSRF_COOKIE_NAME, JWT_COOKIE_NAME
from app.core.security import check_csrf
from app.models.user import User

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", response_model=UserOut)
def register(user: UserCreate, db: Session = Depends(get_db)):
    if get_user_by_username(db, user.username):
        raise HTTPException(status_code=400, detail="Пользователь с таким именем уже существует")
    return create_user(db, user)

@router.post("/token")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db), response: Response = None):
    user = get_user_by_username(db, form_data.username)
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Неверное имя пользователя или пароль")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Пользователь не активирован администратором")
    access_token = create_access_token(data={"sub": user.username})
    csrf_token = generate_csrf_token()
    # Устанавливаем JWT в httpOnly cookie, CSRF — в обычный cookie
    response = Response()
    response.set_cookie(
        key=JWT_COOKIE_NAME,
        value=access_token,
        httponly=True,
        secure=False,  # В проде обязательно True!
        samesite="lax",
        max_age=60*60*24
    )
    response.set_cookie(
        key=CSRF_COOKIE_NAME,
        value=csrf_token,
        httponly=False,
        secure=False,  # В проде обязательно True!
        samesite="lax",
        max_age=60*60*24
    )
    response.headers["X-CSRF-Token"] = csrf_token  # Можно вернуть и в заголовке
    response.status_code = 200
    return response

@router.post("/logout")
def logout(response: Response):
    response.delete_cookie(JWT_COOKIE_NAME)
    response.delete_cookie(CSRF_COOKIE_NAME)
    return {"msg": "Logged out"}

@router.get("/me", response_model=UserOut)
def get_me(request: Request):
    user = get_current_user(request)
    return user

@router.post("/activate-user")
def activate_user_route(user_id: int, is_active: bool, db: Session = Depends(get_db), request: Request = None):
    # Проверка CSRF для защищённого метода
    check_csrf(request)
    admin = get_current_user(request)
    if not admin.is_admin:
        raise HTTPException(status_code=403, detail="Требуются права администратора")
    user = activate_user(db, user_id, is_active)
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    return {"status": "ok", "user_id": user.id, "is_active": user.is_active} 