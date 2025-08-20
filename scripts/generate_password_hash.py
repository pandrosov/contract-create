#!/usr/bin/env python3
"""
Скрипт для генерации правильного хеша пароля для admin пользователя
"""

import bcrypt
import sys

def generate_password_hash(password: str) -> str:
    """Генерирует bcrypt хеш для пароля"""
    # Кодируем пароль в bytes
    password_bytes = password.encode('utf-8')
    
    # Генерируем соль и хеш
    salt = bcrypt.gensalt(rounds=12)
    password_hash = bcrypt.hashpw(password_bytes, salt)
    
    return password_hash.decode('utf-8')

def verify_password(password: str, password_hash: str) -> bool:
    """Проверяет пароль против хеша"""
    password_bytes = password.encode('utf-8')
    hash_bytes = password_hash.encode('utf-8')
    
    return bcrypt.checkpw(password_bytes, hash_bytes)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Использование: python3 scripts/generate_password_hash.py <пароль>")
        sys.exit(1)
    
    password = sys.argv[1]
    
    print(f"Генерация хеша для пароля: {password}")
    
    # Генерируем хеш
    password_hash = generate_password_hash(password)
    print(f"Хеш: {password_hash}")
    
    # Проверяем хеш
    is_valid = verify_password(password, password_hash)
    print(f"Проверка хеша: {'✅ Успешно' if is_valid else '❌ Ошибка'}")
    
    # Выводим SQL для обновления
    print("\nSQL для обновления пароля admin:")
    print(f"UPDATE users SET password_hash = '{password_hash}' WHERE username = 'admin';")
    
    # Выводим для init.sql
    print("\nДля init.sql:")
    print(f"'{password_hash}'")
