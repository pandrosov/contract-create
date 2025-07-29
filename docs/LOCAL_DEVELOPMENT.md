# Локальная разработка

## Запуск локальной среды

### 1. Запуск всех сервисов
```bash
cd create_document
docker-compose up -d
```

### 2. Инициализация базы данных
```bash
docker-compose exec backend python init_db.py
docker-compose exec backend python activate_admin.py
```

### 3. Доступ к приложению
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API документация: http://localhost:8000/docs
- База данных: localhost:5432

## Тестовые данные
- Логин: `admin`
- Пароль: `admin`

## Структура API

### Локальная разработка
В локальной среде API автоматически использует `http://localhost:8000` для запросов.

### Продакшен
В продакшене API использует относительные пути `/api/*` через nginx прокси.

## Переменные окружения

### Frontend
- `REACT_APP_API_URL` - URL для API (по умолчанию определяется автоматически)
- `NODE_ENV` - окружение (development/production)

### Backend
- `DATABASE_URL` - строка подключения к PostgreSQL
- `SECRET_KEY` - секретный ключ для JWT

## Разработка

### Hot Reload
- Frontend: автоматический перезапуск при изменении файлов в `frontend/src/`
- Backend: автоматический перезапуск при изменении файлов в `app/`

### Логи
```bash
# Просмотр логов всех сервисов
docker-compose logs -f

# Просмотр логов конкретного сервиса
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f db
```

### Остановка
```bash
docker-compose down
```

## Отладка

### Проверка статуса контейнеров
```bash
docker-compose ps
```

### Вход в контейнер
```bash
# Backend
docker-compose exec backend bash

# Frontend
docker-compose exec frontend sh

# База данных
docker-compose exec db psql -U contract_user -d contract_db
```

### Проверка API
```bash
# Health check
curl http://localhost:8000/health

# API документация
curl http://localhost:8000/docs
```

## Миграции и изменения БД

### Сброс базы данных
```bash
docker-compose down -v
docker-compose up -d
docker-compose exec backend python init_db.py
docker-compose exec backend python activate_admin.py
```

### Изменение пароля администратора
```bash
docker-compose exec backend python change_admin_password.py
```

## Проблемы и решения

### CORS ошибки
В локальной разработке CORS настроен для `http://localhost:3000`. Если возникают ошибки, проверьте:
1. Frontend запущен на порту 3000
2. Backend запущен на порту 8000
3. В консоли браузера нет ошибок CORS

### Проблемы с базой данных
```bash
# Пересоздание базы
docker-compose down -v
docker-compose up -d db
docker-compose exec backend python init_db.py
```

### Проблемы с зависимостями
```bash
# Пересборка frontend
docker-compose build --no-cache frontend

# Пересборка backend
docker-compose build --no-cache backend
``` 