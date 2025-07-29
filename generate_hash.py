#!/usr/bin/env python3
"""
Скрипт для генерации хеша пароля
"""

from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

if __name__ == "__main__":
    password = "Contract2024!"
    hashed = get_password_hash(password)
    print(f"Пароль: {password}")
    print(f"Хеш: {hashed}")
    
    # Проверяем, что хеш работает
    is_valid = pwd_context.verify(password, hashed)
    print(f"Проверка: {is_valid}") 