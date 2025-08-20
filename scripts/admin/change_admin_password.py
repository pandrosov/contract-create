#!/usr/bin/env python3
"""
Скрипт для изменения пароля администратора
Использование: python change_admin_password.py
"""

import sys
import os

# Добавляем корневую директорию в path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

# Импортируем только необходимые модули
from app.core.security import get_password_hash
from app.core.db import SessionLocal, Base
from sqlalchemy import Column, Integer, String, Boolean, DateTime
import datetime

# Определяем модель User локально, чтобы избежать проблем с relationships
class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    is_active = Column(Boolean, default=False)
    is_admin = Column(Boolean, default=False)
    date_joined = Column(DateTime, default=datetime.datetime.utcnow)

def change_admin_password(new_password: str):
    """Изменяет пароль администратора"""
    db = SessionLocal()
    try:
        # Находим пользователя admin
        admin_user = db.query(User).filter(User.username == "admin").first()
        
        if not admin_user:
            print("❌ Пользователь 'admin' не найден!")
            return False
        
        # Хешируем новый пароль
        hashed_password = get_password_hash(new_password)
        
        # Обновляем пароль
        admin_user.password_hash = hashed_password
        db.commit()
        
        print(f"✅ Пароль администратора успешно изменен!")
        print(f"Логин: admin")
        print(f"Новый пароль: {new_password}")
        return True
        
    except Exception as e:
        print(f"❌ Ошибка при изменении пароля: {e}")
        db.rollback()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    # Новый пароль (измените на желаемый)
    NEW_PASSWORD = "admin"
    
    print("🔐 Изменение пароля администратора...")
    print(f"Новый пароль: {NEW_PASSWORD}")
    print("-" * 50)
    
    success = change_admin_password(NEW_PASSWORD)
    
    if success:
        print("-" * 50)
        print("✅ Готово! Теперь вы можете войти с новым паролем.")
    else:
        print("-" * 50)
        print("❌ Не удалось изменить пароль.") 