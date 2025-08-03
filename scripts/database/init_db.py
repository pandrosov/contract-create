#!/usr/bin/env python3
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.db import Base
from app.models.user import User
from app.models.folder import Folder
from app.models.template import Template
from app.models.permission import Permission
from app.models.action_log import ActionLog
from app.models.settings import Settings
from app.models.placeholder_description import PlaceholderDescription
from app.core.security import get_password_hash

# Создаем подключение к базе данных
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://contract_user:secure_password_123@localhost:5432/contract_db")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def init_db():
    try:
        # Создаем все таблицы
        Base.metadata.create_all(bind=engine)
        print("✅ Таблицы созданы успешно")
        
        # Создаем сессию
        db = SessionLocal()
        
        # Проверяем, есть ли уже пользователи
        existing_users = db.query(User).count()
        if existing_users == 0:
            # Создаем админа
            admin_user = User(
                username="admin",
                email="admin@example.com",
                password_hash=get_password_hash("admin"),
                is_active=True,
                is_admin=True
            )
            db.add(admin_user)
            db.commit()
            print("✅ Пользователь admin создан (логин: admin, пароль: admin)")
        else:
            print("ℹ️ Пользователи уже существуют")
        
        # Проверяем, есть ли уже папки
        existing_folders = db.query(Folder).count()
        if existing_folders == 0:
            # Создаем дефолтные папки
            default_folders = [
                Folder(name="Договоры", path="/contracts", created_by=1),
                Folder(name="Шаблоны", path="/templates", created_by=1),
                Folder(name="Архив", path="/archive", created_by=1)
            ]
            for folder in default_folders:
                db.add(folder)
            db.commit()
            print("✅ Дефолтные папки созданы")
        else:
            print("ℹ️ Папки уже существуют")
        
        # Проверяем, есть ли уже настройки
        existing_settings = db.query(Settings).count()
        if existing_settings == 0:
            # Создаем дефолтные настройки
            default_settings = [
                Settings(
                    key="document_help_info",
                    value="Для правильного заполнения документов:\n\n1. Все поля должны быть заполнены корректно\n2. Даты указывать в формате ДД.ММ.ГГГГ\n3. Суммы указывать цифрами\n4. ФИО указывать полностью",
                    description="Информация для помощи при заполнении документов"
                ),
                Settings(
                    key="contract_help_info",
                    value="При заполнении договоров обратите внимание:\n\n- Номер договора должен быть уникальным\n- Сумма указывается цифрами и прописью\n- Дата подписания обязательна\n- Все реквизиты должны быть актуальными",
                    description="Специфичная информация для договоров"
                )
            ]
            for setting in default_settings:
                db.add(setting)
            db.commit()
            print("✅ Дефолтные настройки созданы")
        else:
            print("ℹ️ Настройки уже существуют")
        
        db.close()
        print("✅ База данных инициализирована успешно")
        
    except Exception as e:
        print(f"❌ Ошибка инициализации: {e}")

if __name__ == "__main__":
    init_db()