#!/usr/bin/env python3
"""
Скрипт для изменения пароля администратора
Использование: python change_admin_password.py
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Импортируем все модели для правильной инициализации
from app.models import user, folder, template
from app.core.security import get_password_hash
from app.models.user import User
from app.core.db import SessionLocal

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
        admin_user.hashed_password = hashed_password
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
    NEW_PASSWORD = "Contract2024!"
    
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