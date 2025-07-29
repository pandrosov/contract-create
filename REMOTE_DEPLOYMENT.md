# 🚀 Деплой на удаленный сервер

## 📋 Подготовка к деплою

### 1. Требования к серверу

**Минимальные требования:**
- Ubuntu 20.04+ или CentOS 8+
- Docker 20.10+
- Docker Compose 2.0+
- 2 GB RAM
- 10 GB свободного места
- Открытые порты: 80, 443, 8000

**Рекомендуемые требования:**
- Ubuntu 22.04 LTS
- 4 GB RAM
- 20 GB SSD
- Домен с SSL сертификатом

### 2. Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Перезагрузка для применения изменений
sudo reboot
```

### 3. Клонирование проекта

```bash
# Создание директории для проекта
mkdir -p /opt/contract-manager
cd /opt/contract-manager

# Клонирование репозитория (используем ветку master для production)
git clone -b master https://github.com/pandrosov/contract-create.git .
```

## 🔧 Настройка окружения

### 1. Создание файла .env

```bash
# Копирование примера
cp env.example .env

# Редактирование конфигурации
nano .env
```

**Пример .env для продакшена:**

```env
# Database Configuration
POSTGRES_PASSWORD=your_very_secure_password_123
DATABASE_URL=postgresql://contract_user:your_very_secure_password_123@postgres:5432/contract_db

# Security
SECRET_KEY=your-super-secret-key-change-this-in-production-2024
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS Settings
CORS_ORIGINS=https://your-domain.com,https://www.your-domain.com

# Frontend API URL
REACT_APP_API_URL=https://your-domain.com/api

# Domain Configuration
DOMAIN=your-domain.com

# SSL Certificate Paths
SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
SSL_KEY_PATH=/etc/nginx/ssl/key.pem

# Logging
LOG_LEVEL=INFO
LOG_FILE=/app/logs/app.log

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
BACKUP_PATH=/app/backups
```

### 2. Настройка SSL сертификатов

**Для Let's Encrypt (рекомендуется):**

```bash
# Установка Certbot
sudo apt install certbot python3-certbot-nginx -y

# Получение сертификата
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# Копирование сертификатов
sudo mkdir -p nginx/ssl
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/ssl/key.pem
sudo chown -R $USER:$USER nginx/ssl/
```

**Для самоподписанного сертификата (тестирование):**

```bash
# Создание директории
mkdir -p nginx/ssl

# Генерация сертификата
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/key.pem \
    -out nginx/ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=your-domain.com"
```

## 🚀 Запуск деплоя

### 1. Автоматический деплой

```bash
# Сделать скрипт исполняемым
chmod +x deploy.sh

# Запуск деплоя
./deploy.sh production
```

### 2. Ручной деплой

```bash
# Создание директорий
mkdir -p templates logs backups nginx/logs

# Остановка существующих контейнеров
docker-compose -f docker-compose.prod.yaml down

# Сборка и запуск
docker-compose -f docker-compose.prod.yaml up --build -d

# Ожидание готовности сервисов
sleep 30

# Инициализация базы данных
docker-compose -f docker-compose.prod.yaml exec -T backend python init_db.py
docker-compose -f docker-compose.prod.yaml exec -T backend python activate_admin.py
```

## 🔍 Проверка деплоя

### 1. Проверка контейнеров

```bash
# Статус контейнеров
docker-compose -f docker-compose.prod.yaml ps

# Логи контейнеров
docker-compose -f docker-compose.prod.yaml logs -f
```

### 2. Проверка доступности

```bash
# Проверка фронтенда
curl -I http://localhost
curl -I https://your-domain.com

# Проверка API
curl -I http://localhost:8000/health
curl -I https://your-domain.com/api/health
```

### 3. Проверка базы данных

```bash
# Подключение к базе данных
docker-compose -f docker-compose.prod.yaml exec postgres psql -U contract_user -d contract_db

# Проверка таблиц
\dt
SELECT * FROM users;
```

## 🔧 Управление сервисами

### 1. Основные команды

```bash
# Просмотр логов
docker-compose -f docker-compose.prod.yaml logs -f

# Остановка сервисов
docker-compose -f docker-compose.prod.yaml down

# Перезапуск сервисов
docker-compose -f docker-compose.prod.yaml restart

# Обновление сервисов
git pull origin master
docker-compose -f docker-compose.prod.yaml up --build -d
```

### 2. Резервное копирование

```bash
# Создание бэкапа
docker-compose -f docker-compose.prod.yaml exec postgres pg_dump -U contract_user contract_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Восстановление из бэкапа
docker-compose -f docker-compose.prod.yaml exec -T postgres psql -U contract_user -d contract_db < backup_file.sql
```

### 3. Мониторинг

```bash
# Использование ресурсов
docker stats

# Проверка дискового пространства
df -h

# Проверка памяти
free -h
```

## 🔒 Безопасность

### 1. Настройка файрвола

```bash
# Установка UFW
sudo apt install ufw -y

# Настройка правил
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 2. Обновление паролей

```bash
# Изменение пароля базы данных
# Отредактируйте .env файл и перезапустите сервисы

# Изменение пароля админа через веб-интерфейс
# Войдите как admin/admin и измените пароль
```

### 3. Настройка автоматических обновлений

```bash
# Создание cron задачи для обновления SSL
sudo crontab -e

# Добавьте строку для обновления Let's Encrypt сертификатов
0 12 * * * /usr/bin/certbot renew --quiet && cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /opt/contract-manager/nginx/ssl/cert.pem && cp /etc/letsencrypt/live/your-domain.com/privkey.pem /opt/contract-manager/nginx/ssl/key.pem && docker-compose -f /opt/contract-manager/docker-compose.prod.yaml restart nginx
```

## 🐛 Устранение неполадок

### 1. Проблемы с подключением

```bash
# Проверка портов
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
sudo netstat -tlnp | grep :8000

# Проверка DNS
nslookup your-domain.com
```

### 2. Проблемы с Docker

```bash
# Очистка Docker
docker system prune -a

# Перезапуск Docker
sudo systemctl restart docker
```

### 3. Проблемы с базой данных

```bash
# Проверка подключения к БД
docker-compose -f docker-compose.prod.yaml exec postgres pg_isready -U contract_user

# Сброс базы данных (осторожно!)
docker-compose -f docker-compose.prod.yaml exec postgres dropdb -U contract_user contract_db
docker-compose -f docker-compose.prod.yaml exec postgres createdb -U contract_user contract_db
docker-compose -f docker-compose.prod.yaml exec -T backend python init_db.py
```

## 📞 Поддержка

Если возникли проблемы:

1. **Проверьте логи:** `docker-compose -f docker-compose.prod.yaml logs -f`
2. **Проверьте статус контейнеров:** `docker-compose -f docker-compose.prod.yaml ps`
3. **Проверьте конфигурацию:** убедитесь, что .env файл настроен правильно
4. **Проверьте сеть:** убедитесь, что порты открыты и DNS настроен

## 🎯 Результат

После успешного деплоя у вас будет:

- ✅ **Фронтенд:** https://your-domain.com
- ✅ **API:** https://your-domain.com/api
- ✅ **Админ панель:** admin/admin
- ✅ **SSL сертификат:** автоматически обновляется
- ✅ **Резервное копирование:** настроено
- ✅ **Мониторинг:** доступен

## 📋 Информация о версии

**Текущая версия:** v1.1.0
**Ветка для production:** master
**Основные улучшения:**
- 🎨 Красивые страницы входа и регистрации
- ✅ Валидация форм в реальном времени
- 🔔 Система уведомлений
- 📱 Адаптивный дизайн
- 🔒 Улучшенная безопасность

**Готово к использованию! 🚀** 