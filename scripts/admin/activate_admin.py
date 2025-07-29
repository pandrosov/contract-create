#!/usr/bin/env python3
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.db import SessionLocal
from app.models.user import User
from app.models.template import Template
from app.models.folder import Folder

def activate_admin():
    db = SessionLocal()
    try:
        # Находим пользователя admin
        user = db.query(User).filter(User.username == "admin").first()
        if user:
            user.is_active = True
            user.is_admin = True
            db.commit()
            print("✅ Администратор активирован!")
        else:
            print("❌ Пользователь admin не найден")
        
    except Exception as e:
        print(f"❌ Ошибка активации: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    activate_admin() 