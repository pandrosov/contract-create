#!/usr/bin/env python3
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.db import SessionLocal, engine, Base
from app.models.user import User
from app.models.folder import Folder
from app.models.template import Template
from app.core.security import get_password_hash

def init_db():
    db = SessionLocal()
    try:
        # Создаем таблицы
        Base.metadata.create_all(bind=engine)
        
        # Проверяем, есть ли уже пользователи
        existing_users = db.query(User).count()
        if existing_users == 0:
            # Создаем администратора
            admin_user = User(
                username="admin",
                email="admin@example.com",
                password_hash=get_password_hash("admin"),
                is_active=True,
                is_admin=True
            )
            db.add(admin_user)
            db.commit()
            print("✅ Администратор создан: admin/admin")
        
        # Проверяем, есть ли уже папки
        existing_folders = db.query(Folder).count()
        if existing_folders == 0:
            # Создаем тестовые папки
            folders = [
                Folder(name="Договоры", created_by=1),
                Folder(name="Шаблоны", created_by=1),
                Folder(name="Архив", created_by=1)
            ]
            for folder in folders:
                db.add(folder)
            db.commit()
            print("✅ Тестовые папки созданы")
        
        print("✅ База данных инициализирована успешно!")
        
    except Exception as e:
        print(f"❌ Ошибка инициализации: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    init_db() 