#!/usr/bin/env python3
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.db import Base
from app.models.user import User
from app.models.folder import Folder
from app.models.template import Template
from app.models.permission import Permission
from app.core.security import get_password_hash

# Создаем подключение к базе данных
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://contract_user:secure_password_123@localhost:5432/contract_db")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def create_test_user():
    try:
        db = SessionLocal()
        
        # Проверяем, существует ли уже тестовый пользователь
        existing_user = db.query(User).filter(User.username == 'testuser').first()
        if existing_user:
            print("ℹ️ Тестовый пользователь уже существует")
            return
        
        # Создаем тестового пользователя
        test_user = User(
            username='testuser',
            email='test@example.com',
            password_hash=get_password_hash('password123'),
            is_active=False,
            is_admin=False
        )
        db.add(test_user)
        db.commit()
        print("✅ Тестовый пользователь создан:")
        print("   Логин: testuser")
        print("   Пароль: password123")
        print("   Статус: Неактивен (требует активации администратором)")
        
        db.close()
        
    except Exception as e:
        print(f"❌ Ошибка создания тестового пользователя: {e}")

if __name__ == "__main__":
    create_test_user() 