#!/usr/bin/env python3

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.security import get_password_hash
from app.models.user import User
from app.core.db import SessionLocal

def change_admin_password():
    db = SessionLocal()
    try:
        user = db.query(User).filter(User.username == 'admin').first()
        if user:
            user.hashed_password = get_password_hash('Contract2024!')
            db.commit()
            print("✅ Admin password updated successfully!")
            print("New password: Contract2024!")
        else:
            print("❌ Admin user not found")
    except Exception as e:
        print(f"❌ Error updating password: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    change_admin_password() 