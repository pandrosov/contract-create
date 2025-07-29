# Contract Management System

Система управления договорами с возможностью создания документов из шаблонов.

## 🚀 Быстрый старт

### Локальная разработка
```bash
# Клонирование репозитория
git clone https://github.com/pandrosov/contract-create.git
cd contract-create

# Запуск в Docker
docker-compose up -d

# Открыть в браузере
http://localhost:3000
```

### Продакшен
```bash
# Развертывание на сервере
./scripts/deployment/deploy_alnilam.sh
```

## 📁 Структура проекта

```
create_document/
├── app/                    # Backend приложение (FastAPI)
│   ├── api/               # API endpoints
│   ├── core/              # Основные модули
│   ├── models/            # Модели данных
│   ├── schemas/           # Pydantic схемы
│   └── services/          # Бизнес-логика
├── frontend/              # Frontend приложение (React)
│   ├── src/               # Исходный код
│   ├── public/            # Статические файлы
│   └── package.json       # Зависимости
├── nginx/                 # Конфигурация Nginx
├── scripts/               # Скрипты управления
│   ├── admin/             # Управление администраторами
│   ├── database/          # Работа с БД
│   ├── deployment/        # Развертывание
│   └── ssl/              # SSL сертификаты
├── docs/                  # Документация
│   ├── deployment/        # Документация по развертыванию
│   └── ssl/              # Документация по SSL
├── templates/             # Шаблоны документов
└── docker-compose.yaml    # Docker конфигурация
```

## 🔧 Основные компоненты

### Backend (FastAPI)
- **Аутентификация**: JWT токены, CSRF защита
- **API**: RESTful endpoints для управления договорами
- **База данных**: PostgreSQL с SQLAlchemy
- **Файлы**: Загрузка и управление шаблонами

### Frontend (React)
- **UI**: Современный интерфейс с Material Design
- **Аутентификация**: Формы входа/регистрации
- **Управление**: Папки, шаблоны, документы
- **Уведомления**: Система уведомлений

### Инфраструктура
- **Docker**: Контейнеризация приложений
- **Nginx**: Reverse proxy, SSL терминация
- **PostgreSQL**: Основная база данных
- **Let's Encrypt**: SSL сертификаты

## 📚 Документация

- [Локальная разработка](docs/LOCAL_DEVELOPMENT.md)
- [Развертывание](docs/deployment/DEPLOYMENT.md)
- [Настройка SSL](docs/ssl/SSL_SETUP.md)
- [Управление БД](docs/deployment/DATABASE_SETUP.md)

## 🛠️ Скрипты

### Администрация
```bash
# Изменение пароля администратора
python scripts/admin/change_admin_password.py

# Генерация хеша пароля
python scripts/admin/generate_hash.py
```

### Развертывание
```bash
# Развертывание на сервере
./scripts/deployment/deploy_alnilam.sh

# Проверка сервера
./scripts/deployment/check_server.sh

# Резервное копирование
./scripts/deployment/backup.sh
```

### База данных
```bash
# Инициализация БД
python scripts/database/init_db.py

# Создание тестового пользователя
python scripts/database/create_test_user.py
```

## 🔐 Безопасность

- **SSL/TLS**: Let's Encrypt сертификаты
- **Аутентификация**: JWT токены с CSRF защитой
- **Пароли**: bcrypt хеширование
- **CORS**: Настроенная политика безопасности

## 📊 Мониторинг

- **Логи**: Docker контейнеры
- **Здоровье**: `/api/health` endpoint
- **SSL**: Автоматическое обновление сертификатов

## 🤝 Вклад в проект

См. [CONTRIBUTING.md](CONTRIBUTING.md) для деталей.

## 📄 Лицензия

См. [LICENSE](LICENSE) файл.

## 🆘 Поддержка

- **Документация**: [docs/](docs/)
- **Issues**: GitHub Issues
- **Скрипты**: [scripts/](scripts/)

---

**Версия**: 1.0.0  
**Статус**: Продакшен готов  
**Последнее обновление**: 2025-07-29 