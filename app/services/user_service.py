from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserCreate
from app.core.security import get_password_hash

def create_user(db: Session, user: UserCreate) -> User:
    db_user = User(
        username=user.username,
        email=user.email,
        password_hash=get_password_hash(user.password),
        is_active=False,
        is_admin=False
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def create_user_from_dict(db: Session, user_data: dict) -> User:
    """Создает пользователя из словаря"""
    db_user = User(
        username=user_data["username"],
        email=user_data["email"],
        password_hash=get_password_hash(user_data["password"]),
        is_active=user_data.get("is_active", False),
        is_admin=user_data.get("is_admin", False)
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_user_by_username(db: Session, username: str):
    return db.query(User).filter(User.username == username).first()

def get_user_by_id(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()

def activate_user(db: Session, user_id: int, is_active: bool):
    user = get_user_by_id(db, user_id)
    if user:
        user.is_active = is_active
        db.commit()
    return user

def make_admin(db: Session, user_id: int, is_admin: bool):
    """Назначает или снимает права администратора у пользователя"""
    user = get_user_by_id(db, user_id)
    if user:
        user.is_admin = is_admin
        db.commit()
    return user 