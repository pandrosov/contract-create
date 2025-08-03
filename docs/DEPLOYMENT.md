# Деплой и развертывание

## Обзор
Система использует Docker и Docker Compose для контейнеризации и развертывания.

## Структура

### Docker файлы
- **`docker-compose.yaml`** - Конфигурация для разработки
- **`docker-compose.prod.yaml`** - Конфигурация для продакшена
- **`app/Dockerfile`** - Сборка backend контейнера
- **`frontend/Dockerfile`** - Сборка frontend контейнера
- **`nginx/nginx.conf`** - Конфигурация Nginx

### Скрипты деплоя
- **`scripts/deployment/deploy_v2.sh`** - Основной скрипт деплоя
- **`scripts/deployment/backup_v2.sh`** - Создание резервных копий
- **`scripts/deployment/check_server_v2.sh`** - Проверка здоровья сервера
- **`scripts/deployment/cleanup_v2.sh`** - Очистка системы

## Сервисы

### Backend (FastAPI)
- **Порт**: 8000
- **База данных**: PostgreSQL
- **ORM**: SQLAlchemy
- **Аутентификация**: JWT токены

### Frontend (React)
- **Порт**: 3000 (разработка), 80 (продакшен)
- **Сборка**: Production build в Nginx контейнере
- **Статические файлы**: Обслуживаются Nginx

### Database (PostgreSQL)
- **Порт**: 5432
- **Данные**: Сохраняются в Docker volumes
- **Инициализация**: Автоматическая через скрипты

### Nginx (Reverse Proxy)
- **Порт**: 80, 443 (SSL)
- **SSL**: Let's Encrypt сертификаты
- **Статические файлы**: Frontend build

## Команды деплоя

### Разработка
```bash
# Запуск всех сервисов
docker-compose up -d

# Просмотр логов
docker-compose logs -f

# Остановка
docker-compose down
```

### Продакшен
```bash
# Деплой с backup
./scripts/deployment/deploy_v2.sh --backup

# Проверка здоровья
./scripts/deployment/check_server_v2.sh --detailed

# Создание backup
./scripts/deployment/backup_v2.sh full --compress

# Очистка системы
./scripts/deployment/cleanup_v2.sh --all
```

## Мониторинг

### Health Checks
- **Backend**: `GET /api/health`
- **Frontend**: `GET /`
- **Database**: Подключение и запросы

### Логи
- **Docker logs**: `docker-compose logs -f`
- **Nginx logs**: `/var/log/nginx/`
- **Application logs**: Внутри контейнеров

### Метрики
- **CPU/Memory**: Docker stats
- **Disk usage**: df -h
- **Network**: netstat -tulpn

## Безопасность

### SSL/TLS
- **Let's Encrypt**: Автоматическое обновление сертификатов
- **HSTS**: HTTP Strict Transport Security
- **CORS**: Настроен для домена

### Firewall
- **Порты**: 80, 443, 22 (SSH)
- **Docker**: Изолированные сети
- **Nginx**: Rate limiting

## Backup и восстановление

### Типы backup
- **Full**: Все данные и конфигурация
- **Database**: Только база данных
- **Files**: Шаблоны и файлы
- **Config**: Конфигурационные файлы

### Автоматизация
- **Cron jobs**: Ежедневные backup
- **Retention**: Хранение 30 дней
- **Compression**: gzip сжатие
- **Upload**: Возможность загрузки в облако

## Troubleshooting

### Частые проблемы
1. **Port conflicts**: Проверить занятые порты
2. **Database connection**: Проверить настройки БД
3. **SSL certificates**: Проверить срок действия
4. **Disk space**: Очистить старые backup

### Команды диагностики
```bash
# Проверка контейнеров
docker ps -a

# Проверка логов
docker-compose logs [service]

# Проверка сети
docker network ls

# Проверка volumes
docker volume ls
``` 