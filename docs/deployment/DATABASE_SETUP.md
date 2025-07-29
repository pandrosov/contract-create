# 🗄️ Настройка базы данных PostgreSQL

## 📋 Ваша текущая конфигурация

- **Сервер:** 178.172.173.68
- **Существующие контейнеры PostgreSQL:**
  - `postgres_db` на порту 5432
  - `wb_db` на порту 5436
  - `mysklad_db` на порту 5433
  - `tiktok_db` на порту 5441
  - `amazon_db` на порту 5438
  - `nano_bot` на порту 5435

## 🎯 Рекомендуемое решение

Для проекта Contract Manager мы создадим отдельный контейнер PostgreSQL на порту **5437**.

## 🚀 Быстрая настройка

### 1. Подключение к серверу

```bash
ssh user@178.172.173.68
```

### 2. Создание отдельного контейнера PostgreSQL

```bash
# Создаем контейнер для нашего проекта
docker run -d \
  --name contract-postgres \
  -e POSTGRES_DB=contract_db \
  -e POSTGRES_USER=contract_user \
  -e POSTGRES_PASSWORD=your_very_secure_password_123 \
  -p 5437:5432 \
  -v contract_postgres_data:/var/lib/postgresql/data \
  postgres:15
```

### 3. Проверка создания

```bash
# Проверяем, что контейнер запущен
docker ps --filter "name=contract-postgres"

# Проверяем подключение к базе данных
docker exec -it contract-postgres psql -U contract_user -d contract_db -c "SELECT version();"
```

## 🔧 Альтернативный способ через скрипт

### 1. Клонирование проекта

```bash
# Создаем директорию для проекта
mkdir -p /opt/contract-manager
cd /opt/contract-manager

# Клонируем проект
git clone -b master https://github.com/pandrosov/contract-create.git .
```

### 2. Запуск скрипта настройки

```bash
# Делаем скрипт исполняемым
chmod +x setup_docker_db.sh

# Запускаем настройку базы данных
./setup_docker_db.sh
```

## 📝 Настройка .env файла

После создания базы данных обновите `.env` файл:

```env
# Database Configuration
POSTGRES_PASSWORD=your_very_secure_password_123
DATABASE_URL=postgresql://contract_user:your_very_secure_password_123@postgres:5432/contract_db

# Security
SECRET_KEY=your-super-secret-key-change-this-in-production-2024
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS Settings
CORS_ORIGINS=https://contract.alnilam.by,https://www.contract.alnilam.by

# Frontend API URL
REACT_APP_API_URL=https://contract.alnilam.by/api

# Domain Configuration
DOMAIN=contract.alnilam.by
```

## 🔍 Проверка настройки

### 1. Проверка контейнера

```bash
# Статус контейнера
docker ps --filter "name=contract-postgres"

# Логи контейнера
docker logs contract-postgres
```

### 2. Проверка подключения

```bash
# Подключение к базе данных
docker exec -it contract-postgres psql -U contract_user -d contract_db

# Внутри psql можно выполнить:
\du  # список пользователей
\l   # список баз данных
\dt  # список таблиц (после инициализации)
\q   # выход
```

### 3. Проверка портов

```bash
# Проверка занятых портов
sudo netstat -tlnp | grep :5437
```

## 🛠️ Управление базой данных

### Основные команды

```bash
# Остановка контейнера
docker stop contract-postgres

# Запуск контейнера
docker start contract-postgres

# Перезапуск контейнера
docker restart contract-postgres

# Удаление контейнера (осторожно!)
docker stop contract-postgres
docker rm contract-postgres
```

### Резервное копирование

```bash
# Создание бэкапа
docker exec contract-postgres pg_dump -U contract_user contract_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Восстановление из бэкапа
docker exec -i contract-postgres psql -U contract_user -d contract_db < backup_file.sql
```

### Просмотр данных

```bash
# Подключение к базе данных
docker exec -it contract-postgres psql -U contract_user -d contract_db

# Полезные команды в psql:
SELECT * FROM users;           # просмотр пользователей
SELECT * FROM folders;         # просмотр папок
SELECT * FROM templates;       # просмотр шаблонов
SELECT * FROM permissions;     # просмотр прав доступа
```

## 🔒 Безопасность

### 1. Смена пароля

```bash
# Подключение к PostgreSQL
docker exec -it contract-postgres psql -U contract_user -d contract_db

# Смена пароля
ALTER USER contract_user WITH PASSWORD 'new_secure_password';
```

### 2. Ограничение доступа

```bash
# Проверка подключений
docker exec contract-postgres psql -U contract_user -d contract_db -c "SELECT * FROM pg_stat_activity;"
```

## 🐛 Устранение проблем

### 1. Контейнер не запускается

```bash
# Проверка логов
docker logs contract-postgres

# Проверка портов
sudo netstat -tlnp | grep :5437

# Пересоздание контейнера
docker stop contract-postgres
docker rm contract-postgres
./setup_docker_db.sh
```

### 2. Проблемы с подключением

```bash
# Проверка сети Docker
docker network ls

# Проверка подключения к контейнеру
docker exec contract-postgres pg_isready -U contract_user -d contract_db
```

### 3. Проблемы с данными

```bash
# Проверка объема данных
docker volume ls
docker volume inspect contract_postgres_data

# Очистка данных (осторожно!)
docker stop contract-postgres
docker volume rm contract_postgres_data
./setup_docker_db.sh
```

## 📊 Мониторинг

### 1. Использование ресурсов

```bash
# Статистика контейнера
docker stats contract-postgres

# Размер данных
du -sh /var/lib/docker/volumes/contract_postgres_data/_data
```

### 2. Логи

```bash
# Просмотр логов в реальном времени
docker logs -f contract-postgres

# Просмотр последних 100 строк
docker logs --tail 100 contract-postgres
```

## ✅ Результат

После успешной настройки у вас будет:

- ✅ **Отдельный контейнер PostgreSQL** для проекта
- ✅ **Порт 5437** (не конфликтует с существующими)
- ✅ **Пользователь contract_user** с правами на базу contract_db
- ✅ **Персистентные данные** в Docker volume
- ✅ **Готовность к деплою** приложения

**База данных готова для использования! 🚀** 