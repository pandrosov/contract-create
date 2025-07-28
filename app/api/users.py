from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.db import get_db
from app.models.user import User
from app.schemas.user import UserOut
from app.core.security import require_admin

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return db.query(User).all()

@router.get("/{user_id}", response_model=UserOut)
def get_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    return user 