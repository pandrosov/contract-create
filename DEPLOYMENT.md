# Руководство по деплою на сервер

Это руководство поможет вам развернуть Contract Management System на удаленном сервере.

## 🚀 Быстрый деплой

### 1. Подготовка сервера

Убедитесь, что на сервере установлены:
- Docker
- Docker Compose
- Git

```bash
# Установка Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Клонирование проекта

```bash
git clone https://github.com/pandrosov/contract-create.git
cd contract-create
```

### 3. Настройка окружения

```bash
# Копирование примера конфигурации
cp env.example .env

# Редактирование конфигурации
nano .env
```

### 4. Запуск деплоя

```bash
# Автоматический деплой
./deploy.sh production
```

## ⚙️ Детальная настройка

### Конфигурация .env файла

```bash
# Обязательные параметры
POSTGRES_PASSWORD=your_secure_database_password_here
SECRET_KEY=your-super-secret-key-change-this-in-production
DOMAIN=your-domain.com

# Опциональные параметры
CORS_ORIGINS=https://your-domain.com
REACT_APP_API_URL=https://your-domain.com/api
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
```

### SSL сертификаты

#### Автоматические сертификаты (Let's Encrypt)

```bash
# Установка Certbot
sudo apt install certbot

# Получение сертификата
sudo certbot certonly --standalone -d your-domain.com

# Копирование сертификатов
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/ssl/key.pem
```

#### Самостоятельно подписанные сертификаты

```bash
# Создание директории
mkdir -p nginx/ssl

# Генерация сертификатов
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/key.pem \
    -out nginx/ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=your-domain.com"
```

### Настройка домена

1. **DNS записи**:
   ```
   A    your-domain.com    YOUR_SERVER_IP
   A    www.your-domain.com    YOUR_SERVER_IP
   ```

2. **Firewall**:
   ```bash
   # Открытие портов
   sudo ufw allow 80
   sudo ufw allow 443
   sudo ufw allow 22
   sudo ufw enable
   ```

## 🔧 Управление сервисами

### Запуск сервисов

```bash
# Production
docker-compose -f docker-compose.prod.yaml up -d

# Development
docker-compose up -d
```

### Остановка сервисов

```bash
# Production
docker-compose -f docker-compose.prod.yaml down

# Development
docker-compose down
```

### Просмотр логов

```bash
# Все сервисы
docker-compose -f docker-compose.prod.yaml logs -f

# Конкретный сервис
docker-compose -f docker-compose.prod.yaml logs -f backend
```

### Перезапуск сервисов

```bash
# Все сервисы
docker-compose -f docker-compose.prod.yaml restart

# Конкретный сервис
docker-compose -f docker-compose.prod.yaml restart backend
```

## 📦 Резервное копирование

### Автоматическое резервное копирование

```bash
# Полное резервное копирование
./backup.sh full

# Только база данных
./backup.sh db

# Только файлы
./backup.sh files
```

### Настройка cron для автоматических бэкапов

```bash
# Редактирование crontab
crontab -e

# Добавление задачи (бэкап каждый день в 2:00)
0 2 * * * cd /path/to/contract-create && ./backup.sh full
```

### Восстановление из бэкапа

```bash
# Восстановление базы данных
gunzip -c backups/db_backup_YYYYMMDD_HHMMSS.sql.gz | docker-compose -f docker-compose.prod.yaml exec -T postgres psql -U contract_user contract_db

# Восстановление файлов
tar -xzf backups/files_backup_YYYYMMDD_HHMMSS.tar.gz

# Восстановление шаблонов
tar -xzf backups/templates_backup_YYYYMMDD_HHMMSS.tar.gz
```

## 🔒 Безопасность

### Изменение паролей

```bash
# Подключение к базе данных
docker-compose -f docker-compose.prod.yaml exec postgres psql -U contract_user contract_db

# Изменение пароля администратора
UPDATE users SET password_hash = 'new_hashed_password' WHERE username = 'admin';
```

### Настройка firewall

```bash
# Установка UFW
sudo apt install ufw

# Настройка правил
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### SSL/TLS настройки

```bash
# Проверка SSL конфигурации
openssl s_client -connect your-domain.com:443 -servername your-domain.com

# Обновление сертификатов Let's Encrypt
sudo certbot renew
```

## 📊 Мониторинг

### Проверка состояния сервисов

```bash
# Статус контейнеров
docker-compose -f docker-compose.prod.yaml ps

# Использование ресурсов
docker stats

# Логи в реальном времени
docker-compose -f docker-compose.prod.yaml logs -f --tail=100
```

### Health checks

```bash
# Проверка фронтенда
curl -f http://your-domain.com/health

# Проверка API
curl -f http://your-domain.com/api/health

# Проверка базы данных
docker-compose -f docker-compose.prod.yaml exec postgres pg_isready -U contract_user
```

## 🚨 Устранение неполадок

### Проблемы с подключением к базе данных

```bash
# Проверка статуса PostgreSQL
docker-compose -f docker-compose.prod.yaml exec postgres pg_isready -U contract_user

# Просмотр логов PostgreSQL
docker-compose -f docker-compose.prod.yaml logs postgres
```

### Проблемы с фронтендом

```bash
# Проверка сборки
docker-compose -f docker-compose.prod.yaml logs frontend

# Пересборка фронтенда
docker-compose -f docker-compose.prod.yaml build frontend
```

### Проблемы с SSL

```bash
# Проверка сертификатов
openssl x509 -in nginx/ssl/cert.pem -text -noout

# Проверка конфигурации nginx
docker-compose -f docker-compose.prod.yaml exec nginx nginx -t
```

### Проблемы с памятью

```bash
# Очистка неиспользуемых образов
docker system prune -a

# Очистка логов
docker system prune -f
```

## 🔄 Обновление системы

### Обновление кода

```bash
# Получение обновлений
git pull origin master

# Пересборка и перезапуск
docker-compose -f docker-compose.prod.yaml down
docker-compose -f docker-compose.prod.yaml up --build -d
```

### Обновление зависимостей

```bash
# Обновление Python зависимостей
docker-compose -f docker-compose.prod.yaml exec backend pip install --upgrade -r requirements.txt

# Обновление Node.js зависимостей
docker-compose -f docker-compose.prod.yaml exec frontend npm update
```

## 📋 Чек-лист деплоя

- [ ] Установлен Docker и Docker Compose
- [ ] Клонирован репозиторий
- [ ] Настроен .env файл
- [ ] Настроены SSL сертификаты
- [ ] Настроен DNS
- [ ] Открыты порты в firewall
- [ ] Запущен деплой
- [ ] Проверена доступность сервисов
- [ ] Изменен пароль администратора
- [ ] Настроено резервное копирование
- [ ] Настроен мониторинг

## 📞 Поддержка

При возникновении проблем:

1. Проверьте логи: `docker-compose -f docker-compose.prod.yaml logs`
2. Проверьте статус контейнеров: `docker-compose -f docker-compose.prod.yaml ps`
3. Создайте issue в GitHub репозитории
4. Обратитесь к документации проекта

## 🔗 Полезные ссылки

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/) 

Отлично! 🎉 Мы создали отдельную ветку `feature/ui-improvements` и значительно улучшили интерфейс системы!

## ✅ Что было добавлено в новой ветке:

### 🎨 **Улучшенный сайдбар:**
- **Категории меню** - разделение на "Основные" и "Администрирование"
- **Сворачивание сайдбара** - кнопка для компактного режима (80px)
- **Описания пунктов меню** - подсказки для каждого раздела
- **Условное отображение** - админские разделы показываются только администраторам
- **Аватар пользователя** - с инициалами и статусом "Онлайн"
- **Плавные анимации** - переходы при сворачивании/разворачивании

### 🎨 **Главная страница (Dashboard):**
- **Статистические карточки** - количество папок, шаблонов, пользователей, документов
- **Быстрые действия** - цветные карточки для быстрого доступа к функциям
- **Последняя активность** - лента событий в системе
- **Информация о системе** - версия, статус, контакты поддержки

### 🎨 **Новые компоненты:**
- **`DashboardStats`** - отображение статистики с красивыми иконками
- **`DashboardPage`** - главная страница с дашбордом
- **Улучшенные стили** - для всех новых компонентов

### 🎨 **Технические улучшения:**
- **Отдельная ветка** - `feature/ui-improvements` для изолированной разработки
- **Пропсы для сайдбара** - `collapsed` и `onToggle` для управления состоянием
- **Адаптивный дизайн** - корректная работа на мобильных устройствах
- **Градиентные иконки** - разные цвета для разных типов статистики

### 🎨 **Адаптивность:**
- **Мобильная версия** - сайдбар скрывается на маленьких экранах
- **Responsive grid** - статистика и быстрые действия адаптируются
- **Touch-friendly** - удобные размеры кнопок для мобильных устройств

## 🎨 **Визуальные улучшения:**

### **Сайдбар:**
- Логотип с градиентным фоном
- Категории с заголовками
- Описания для каждого пункта меню
- Аватар пользователя с инициалами
- Статус "Онлайн" с зеленой точкой

### **Дашборд:**
- 4 статистические карточки с градиентными иконками
- Быстрые действия с цветовым кодированием
- Лента активности с иконками
- Информация о системе в сетке

### **Цветовая схема:**
- **Синий** - основные действия и статистика
- **Зеленый** - шаблоны и успешные операции
- **Фиолетовый** - папки и настройки
- **Оранжевый** - пользователи и предупреждения

## 🎨 **Как использовать:**

### **Сворачивание сайдбара:**
- Нажмите кнопку `←` в сайдбаре для сворачивания
- В свернутом режиме показываются только иконки
- Hover показывает подсказки с названиями

### **Главная страница:**
- Автоматически открывается при входе в систему
- Показывает общую статистику
- Быстрые ссылки на основные функции

### **Адаптивность:**
- На мобильных устройствах сайдбар скрывается
- Статистика перестраивается в одну колонку
- Быстрые действия адаптируются под экран

## 🎨 **Структура ветки:**
```
feature/ui-improvements/
├── frontend/src/components/
│   ├── DashboardStats.js (новый)
│   └── Sidebar.js (обновлен)
├── frontend/src/pages/
│   └── DashboardPage.js (новый)
├── frontend/src/styles/
│   └── global.css (обновлен)
└── frontend/src/App.js (обновлен)
```

Теперь у вас есть современный, красивый и функциональный интерфейс с улучшенным сайдбаром и информативной главной страницей! 🎨✨ 