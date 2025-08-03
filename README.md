# Contract Management System

## 🎉 Версия 2.0.0

Система управления контрактами и документами с автоматической генерацией документов из шаблонов.

## 🚀 Быстрый старт

### Локальная разработка
```bash
# Клонирование репозитория
git clone https://github.com/pandrosov/contract-create.git
cd contract-create

# Запуск в Docker
docker-compose up -d

# Доступ к приложению
# Frontend: http://localhost:3000
# Backend: http://localhost:8000
# API Docs: http://localhost:8000/api/docs
```

### Продакшен деплой
```bash
# Деплой с backup
./scripts/deployment/deploy_v2.sh --backup

# Проверка здоровья сервера
./scripts/deployment/check_server_v2.sh --detailed

# Создание backup
./scripts/deployment/backup_v2.sh full --compress
```

## 📋 Основные функции

### ✨ Новое в версии 2.0
- **Управление описаниями плейсхолдеров** - Добавление описаний к полям шаблонов
- **Улучшенная функция перевода чисел** - Правильное русское склонение
- **Новые скрипты деплоя** - Улучшенная автоматизация

### 🔧 Основные возможности
- **Загрузка и управление шаблонами** - Поддержка .docx файлов
- **Генерация документов** - Автоматическое заполнение шаблонов
- **Система аутентификации** - JWT токены и CSRF защита
- **Управление пользователями** - Регистрация, активация, роли
- **Система папок** - Организация документов
- **Логирование** - Отслеживание всех действий
- **Система прав** - Детальное управление доступом

## 🏗️ Архитектура

### Backend (FastAPI)
- **FastAPI** - Современный Python веб-фреймворк
- **SQLAlchemy** - ORM для работы с базой данных
- **PostgreSQL** - Реляционная база данных
- **JWT** - Аутентификация и авторизация

### Frontend (React)
- **React 18** - Современный JavaScript фреймворк
- **React Router** - Навигация между страницами
- **Axios** - HTTP клиент для API
- **Context API** - Управление состоянием

### Инфраструктура
- **Docker** - Контейнеризация приложения
- **Docker Compose** - Оркестрация сервисов
- **Nginx** - Обратный прокси и SSL
- **Let's Encrypt** - SSL сертификаты

## 📁 Структура проекта

```
create_document/
├── app/                    # Backend приложение
│   ├── api/               # API endpoints
│   ├── core/              # Основная конфигурация
│   ├── models/            # Модели базы данных
│   ├── schemas/           # Pydantic схемы
│   ├── services/          # Бизнес-логика
│   └── utils/             # Утилиты
├── frontend/              # React frontend
│   ├── src/
│   │   ├── api/           # API функции
│   │   ├── components/    # React компоненты
│   │   ├── pages/         # Страницы приложения
│   │   └── styles/        # CSS стили
├── scripts/               # Скрипты управления
│   ├── deployment/        # Скрипты деплоя
│   ├── admin/            # Административные скрипты
│   └── database/         # Скрипты БД
├── docs/                 # Документация
├── templates/            # Шаблоны документов
└── nginx/               # Конфигурация Nginx
```

## 📚 Документация

### Основная документация
- **[CHANGES.md](CHANGES.md)** - История изменений и версий
- **[docs/BACKEND.md](docs/BACKEND.md)** - Документация по backend
- **[docs/FRONTEND.md](docs/FRONTEND.md)** - Документация по frontend
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Руководство по деплою
- **[docs/SCRIPTS.md](docs/SCRIPTS.md)** - Описание скриптов

### Дополнительная документация
- **[docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md)** - Локальная разработка
- **[docs/deployment/](docs/deployment/)** - Детальные инструкции по деплою
- **[docs/ssl/](docs/ssl/)** - Настройка SSL сертификатов

## 🛠️ Разработка

### Требования
- **Docker** и **Docker Compose**
- **Git** для управления версиями
- **Node.js** (для локальной разработки frontend)
- **Python 3.8+** (для локальной разработки backend)

### Локальная разработка
```bash
# Backend
cd app
pip install -r requirements.txt
uvicorn main:app --reload

# Frontend
cd frontend
npm install
npm start
```

## 🔧 Конфигурация

### Переменные окружения
Скопируйте `env.example` в `.env` и настройте:
```bash
# База данных
DATABASE_URL=postgresql://user:password@localhost/dbname

# JWT секреты
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-secret

# Настройки приложения
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
```

## 🚀 Деплой

### Продакшен
```bash
# Деплой с backup
./scripts/deployment/deploy_v2.sh --backup

# Проверка здоровья
./scripts/deployment/check_server_v2.sh --detailed

# Создание backup
./scripts/deployment/backup_v2.sh full --compress
```

### Мониторинг
```bash
# Просмотр логов
docker-compose -f docker-compose.prod.yaml logs -f

# Проверка контейнеров
docker ps -a

# Проверка ресурсов
docker stats
```

## 🔒 Безопасность

### Реализованные меры
- **JWT токены** для аутентификации
- **CSRF защита** для всех форм
- **Валидация данных** через Pydantic
- **SQL injection защита** через SQLAlchemy
- **XSS защита** через React
- **SSL/TLS** шифрование

### Рекомендации
- Регулярно обновляйте зависимости
- Используйте сильные пароли
- Настройте firewall
- Мониторьте логи на подозрительную активность

## 🤝 Вклад в проект

### Как внести вклад
1. Форкните репозиторий
2. Создайте ветку для новой функции
3. Внесите изменения
4. Добавьте тесты
5. Создайте Pull Request

### Стандарты кода
- **Python**: PEP 8, type hints
- **JavaScript**: ESLint, Prettier
- **Git**: Conventional Commits
- **Документация**: Markdown

## 📞 Поддержка

### Контакты
- **Email**: support@alnilam.by
- **GitHub Issues**: [Создать issue](https://github.com/pandrosov/contract-create/issues)
- **Документация**: [docs/](docs/)

### Полезные ссылки
- **Продакшен**: https://contract.alnilam.by
- **API Health**: https://contract.alnilam.by/api/health
- **API Docs**: https://contract.alnilam.by/api/docs

## 📄 Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

---

**🎉 Готово к использованию!**

Для получения дополнительной информации см. [CHANGES.md](CHANGES.md) и документацию в папке [docs/](docs/). 