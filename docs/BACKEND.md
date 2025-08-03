# Backend (FastAPI)

## Обзор
Backend приложения построен на FastAPI с использованием SQLAlchemy ORM и PostgreSQL.

## Структура

### `/app/`
- **`main.py`** - Точка входа приложения, настройка CORS и роутеров
- **`auth.py`** - Аутентификация и JWT токены

### `/app/api/`
API endpoints для всех функций:
- **`auth.py`** - Регистрация, логин, logout
- **`users.py`** - Управление пользователями
- **`templates.py`** - Загрузка и управление шаблонами
- **`acts.py`** - Генерация документов
- **`folders.py`** - Управление папками
- **`logs.py`** - Логирование действий
- **`permissions.py`** - Система прав доступа
- **`settings.py`** - Настройки приложения

### `/app/core/`
- **`config.py`** - Конфигурация приложения
- **`db.py`** - Настройка базы данных
- **`security.py`** - Функции безопасности

### `/app/models/`
SQLAlchemy модели:
- **`user.py`** - Пользователи
- **`template.py`** - Шаблоны документов
- **`placeholder_description.py`** - Описания плейсхолдеров
- **`folder.py`** - Папки
- **`log.py`** - Логи
- **`permission.py`** - Права доступа
- **`settings.py`** - Настройки

### `/app/schemas/`
Pydantic схемы для валидации данных

### `/app/services/`
Бизнес-логика приложения

### `/app/utils/`
- **`number_to_text.py`** - Перевод чисел в русский текст

## Основные функции
- REST API для всех операций
- JWT аутентификация
- CSRF защита
- Валидация данных через Pydantic
- Логирование всех действий
- Система прав доступа
- Генерация документов из шаблонов

## Запуск
```bash
# Разработка
uvicorn app.main:app --reload

# Продакшен
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
``` 