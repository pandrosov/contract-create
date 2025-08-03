# Скрипты и утилиты

## Обзор
Система включает набор скриптов для автоматизации различных задач.

## Структура

### `/scripts/deployment/`
Скрипты для деплоя и управления сервером:
- **`deploy_v2.sh`** - Основной скрипт деплоя с backup и rollback
- **`backup_v2.sh`** - Создание резервных копий с сжатием
- **`check_server_v2.sh`** - Комплексная проверка здоровья сервера
- **`cleanup_v2.sh`** - Очистка системы с dry-run режимом

### `/scripts/admin/`
Административные скрипты:
- **`activate_admin.py`** - Активация администратора
- **`change_admin_password.py`** - Смена пароля админа
- **`generate_hash.py`** - Генерация хешей паролей

### `/scripts/database/`
Скрипты для работы с базой данных:
- **`init_db.py`** - Инициализация базы данных
- **`create_test_user.py`** - Создание тестового пользователя
- **`change_admin_password.sql`** - SQL для смены пароля

### `/scripts/ssl/`
Скрипты для SSL сертификатов:
- **`ssl_renew.sh`** - Обновление Let's Encrypt сертификатов

## Основные скрипты

### deploy_v2.sh
```bash
# Деплой с backup
./scripts/deployment/deploy_v2.sh --backup

# Деплой с rollback
./scripts/deployment/deploy_v2.sh --rollback

# Деплой без backup
./scripts/deployment/deploy_v2.sh
```

**Функции:**
- Backup текущей версии
- Обновление кода из Git
- Пересборка Docker контейнеров
- Проверка здоровья сервисов
- Rollback при ошибках

### backup_v2.sh
```bash
# Полный backup с сжатием
./scripts/deployment/backup_v2.sh full --compress

# Backup только базы данных
./scripts/deployment/backup_v2.sh db

# Backup файлов
./scripts/deployment/backup_v2.sh files
```

**Типы backup:**
- **full**: Все данные и конфигурация
- **db**: Только база данных
- **files**: Шаблоны и файлы
- **config**: Конфигурационные файлы

### check_server_v2.sh
```bash
# Базовая проверка
./scripts/deployment/check_server_v2.sh

# Детальная проверка
./scripts/deployment/check_server_v2.sh --detailed

# С уведомлениями
./scripts/deployment/check_server_v2.sh --notify
```

**Проверки:**
- Статус Docker контейнеров
- Здоровье backend API
- Доступность frontend
- SSL сертификаты
- Подключение к базе данных
- Использование диска и памяти
- Логи и ошибки

### cleanup_v2.sh
```bash
# Просмотр что будет удалено
./scripts/deployment/cleanup_v2.sh --all --dry-run

# Очистка Docker ресурсов
./scripts/deployment/cleanup_v2.sh --docker

# Очистка логов
./scripts/deployment/cleanup_v2.sh --logs

# Очистка backup
./scripts/deployment/cleanup_v2.sh --backups
```

## Административные скрипты

### activate_admin.py
```bash
# Активация администратора
python3 scripts/admin/activate_admin.py

# Создание нового админа
python3 scripts/admin/activate_admin.py --create
```

### change_admin_password.py
```bash
# Смена пароля админа
python3 scripts/admin/change_admin_password.py

# Смена пароля конкретного пользователя
python3 scripts/admin/change_admin_password.py --user admin
```

## База данных

### init_db.py
```bash
# Инициализация базы данных
python3 scripts/database/init_db.py

# Создание тестовых данных
python3 scripts/database/init_db.py --test-data
```

## SSL сертификаты

### ssl_renew.sh
```bash
# Обновление SSL сертификатов
./scripts/ssl/ssl_renew.sh

# Проверка сертификатов
./scripts/ssl/ssl_renew.sh --check
```

## Автоматизация

### Cron jobs
```bash
# Ежедневный backup в 2:00
0 2 * * * /path/to/scripts/deployment/backup_v2.sh full --compress

# Проверка здоровья каждый час
0 * * * * /path/to/scripts/deployment/check_server_v2.sh --notify

# Обновление SSL каждые 60 дней
0 0 1 */2 * /path/to/scripts/ssl/ssl_renew.sh
```

## Мониторинг

### Логи скриптов
- **Логи деплоя**: `/var/log/deploy.log`
- **Логи backup**: `/var/log/backup.log`
- **Логи проверок**: `/var/log/health.log`

### Уведомления
- **Email**: При критических ошибках
- **Slack**: Для команды разработки
- **Telegram**: Для администраторов

## Безопасность

### Права доступа
- **Скрипты деплоя**: Только для администраторов
- **Админ скрипты**: Только для root
- **Backup**: Шифрование чувствительных данных

### Валидация
- **Проверка прав**: Перед выполнением
- **Валидация параметров**: Все входные данные
- **Rollback**: При критических ошибках 