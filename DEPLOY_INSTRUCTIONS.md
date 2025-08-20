# 🚀 Инструкции по деплою приложения

## 📋 Предварительные требования

### На локальной машине:
- SSH ключи настроены для доступа к серверу
- Установлен `git` (обычно есть по умолчанию на macOS/Linux)
- Установлен `openssl` для генерации случайных паролей
- Git репозиторий настроен с remote origin

### На сервере:
- Ubuntu/Debian система
- Доступ по SSH с правами root
- Открытые порты 22 (SSH), 80 (HTTP), 443 (HTTPS)

## 🔑 Настройка SSH доступа

1. **Генерация SSH ключа** (если еще не создан):
```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
```

2. **Копирование публичного ключа на сервер**:
```bash
ssh-copy-id root@185.179.83.236
```

3. **Проверка подключения**:
```bash
ssh root@185.179.83.236 "echo 'SSH доступ настроен'"
```

## 🌐 Настройка домена

Убедитесь, что ваш домен `contract.alnilam.by` указывает на IP адрес сервера `185.179.83.236`:

```bash
# Проверка DNS записи
nslookup contract.alnilam.by
dig contract.alnilam.by
```

## 🚀 Выполнение деплоя

### 1. Подготовка Git репозитория
```bash
# Убедитесь, что все изменения закоммичены
git status
git add .
git commit -m "Prepare for deployment"

# Отправьте изменения в удаленный репозиторий
git push origin master
```

### 2. Первый деплой (полная установка)

```bash
# Сделать скрипты исполняемыми
chmod +x deploy.sh
chmod +x server-manage.sh

# Запустить деплой
./deploy.sh
```

Скрипт автоматически:
- ✅ Проверит подключение к серверу
- ✅ Создаст необходимые директории
- ✅ Скопирует файлы приложения через Git
- ✅ Установит Docker и Docker Compose
- ✅ Настроит firewall
- ✅ Получит SSL сертификаты Let's Encrypt
- ✅ Запустит все сервисы

### 3. Проверка работы приложения

После успешного деплоя ваше приложение будет доступно по адресам:
- 🌐 **Frontend**: https://contract.alnilam.by
- 🔌 **API**: https://contract.alnilam.by/api
- 📊 **Health Check**: https://contract.alnilam.by/health

### 4. Проверка Git статуса на сервере
```bash
# Подключиться к серверу
ssh root@185.179.83.236

# Проверить Git статус
cd /opt/contract-app
git status
git log --oneline -5
```

## 🛠️ Управление приложением

### Основные команды:

```bash
# Запуск приложения
./server-manage.sh start

# Остановка приложения
./server-manage.sh stop

# Перезапуск приложения
./server-manage.sh restart

# Просмотр статуса
./server-manage.sh status

# Просмотр логов
./server-manage.sh logs

# Обновление приложения через Git
./server-manage.sh update

# Деплой конкретной ветки
./server-manage.sh deploy develop

# Деплой тега
./server-manage.sh deploy v1.0.0

# Создание резервной копии БД
./server-manage.sh backup

# Git-based резервные копии
git tag v1.0.0
git push origin v1.0.0
./server-manage.sh deploy v1.0.0

# Обновление SSL сертификатов
./server-manage.sh ssl

# Открытие shell на сервере
./server-manage.sh shell
```

## 📁 Структура на сервере

```
/opt/contract-app/
├── app/                    # Backend код
├── frontend/              # Frontend код
├── nginx/                 # Nginx конфигурация
│   ├── nginx.conf        # Основной конфиг
│   ├── ssl/              # SSL сертификаты
│   └── logs/             # Логи Nginx
├── templates/             # Шаблоны документов
├── logs/                  # Логи приложения
├── backups/               # Резервные копии БД
├── docker-compose.prod.yaml  # Docker Compose конфиг
└── .env                   # Переменные окружения
```

## 🔒 Безопасность

### Автоматически настроено:
- ✅ Firewall (только необходимые порты открыты)
- ✅ SSL сертификаты с автоматическим обновлением
- ✅ Безопасные пароли для базы данных
- ✅ CORS настройки для вашего домена
- ✅ Rate limiting для API

### Рекомендуется дополнительно:
- 🔐 Изменить пароли в файле `.env` на сервере
- 🔐 Настроить регулярные резервные копии
- 🔐 Мониторинг логов на предмет подозрительной активности

## 📊 Мониторинг и логи

### Git мониторинг:
```bash
# Git статус на сервере
ssh root@185.179.83.236 "cd /opt/contract-app && git status"

# История коммитов
ssh root@185.179.83.236 "cd /opt/contract-app && git log --oneline -10"

# Информация о ветках
ssh root@185.179.83.236 "cd /opt/contract-app && git branch -a"
```

### Просмотр логов в реальном времени:
```bash
# Логи всех сервисов
./server-manage.sh logs

# Логи конкретного сервиса
ssh root@185.179.83.236 "cd /opt/contract-app && docker-compose -f docker-compose.prod.yaml logs -f backend"
```

### Мониторинг ресурсов:
```bash
# Статус сервисов
./server-manage.sh status

# Использование ресурсов
ssh root@185.179.83.236 "docker stats"
```

## 🔄 Обновление приложения

### Git-based обновление (рекомендуется):
```bash
# Обновление через Git
./server-manage.sh update

# Деплой конкретной ветки/тега
./server-manage.sh deploy master
./server-manage.sh deploy v1.0.0
```

### Автоматическое обновление:
```bash
./server-manage.sh update
```

### Ручное обновление:
```bash
# Подключиться к серверу
ssh root@185.179.83.236

# Перейти в директорию приложения
cd /opt/contract-app

# Остановить сервисы
docker-compose -f docker-compose.prod.yaml down

# Обновить код через Git
git fetch origin
git reset --hard origin/master
git clean -fd

# Пересобрать и запустить
docker-compose -f docker-compose.prod.yaml up -d --build
```

## 💾 Git-based резервные копии

### Создание тега для версии:
```bash
# Создать тег
git tag v1.0.0
git push origin v1.0.0

# Деплой тега
./server-manage.sh deploy v1.0.0
```

### Восстановление из тега:
```bash
# Восстановить конкретную версию
./server-manage.sh deploy v1.0.0
```

## 🚨 Устранение неполадок

### Проблема: Не удается подключиться по SSH
**Решение**: Проверьте:
- Правильность IP адреса
- Настройки SSH ключей
- Доступность сервера

### Проблема: Приложение не запускается
**Решение**: Проверьте логи:
```bash
./server-manage.sh logs
```

### Проблема: SSL сертификаты не работают
**Решение**: Обновите сертификаты:
```bash
./server-manage.sh ssl
```

### Проблема: База данных недоступна
**Решение**: Проверьте статус PostgreSQL:
```bash
ssh root@185.179.83.236 "cd /opt/contract-app && docker-compose -f docker-compose.prod.yaml exec postgres pg_isready"
```

## 📞 Поддержка

При возникновении проблем:

1. **Проверьте логи**: `./server-manage.sh logs`
2. **Проверьте статус**: `./server-manage.sh status`
3. **Проверьте Git статус**: `ssh root@185.179.83.236 "cd /opt/contract-app && git status"`
4. **Проверьте подключение к серверу**: `ssh root@185.179.83.236`
5. **Проверьте Docker контейнеры**: `docker ps -a`
6. **Проверьте Git репозиторий**: `git status && git remote -v`
7. **Проверьте firewall**: `ufw status` или `iptables -L`
8. **Проверьте SSL сертификаты**: `./server-manage.sh ssl`
9. **Проверьте порты**: `netstat -tlnp` или `ss -tlnp`
10. **Проверьте диск**: `df -h` и `du -sh /opt/contract-app`
11. **Проверьте процессы**: `ps aux | grep docker` и `ps aux | grep nginx`
12. **Проверьте сеть**: `ping google.com` и `curl -I https://contract.alnilam.by`
13. **Проверьте DNS**: `nslookup contract.alnilam.by` и `dig contract.alnilam.by`
14. **Проверьте время**: `date` и `timedatectl status`
15. **Проверьте пользователей**: `who` и `w`
16. **Проверьте память**: `free -h` и `vmstat 1 5`
17. **Проверьте загрузку**: `uptime` и `top -n 1`
18. **Проверьте журналы**: `journalctl -u docker` и `journalctl -u nginx`
19. **Проверьте конфигурацию**: `nginx -t` и `docker info`
20. **Проверьте права доступа**: `ls -la /opt/contract-app` и `id`
21. **Проверьте переменные окружения**: `cat /opt/contract-app/.env`
22. **Проверьте SSL сертификаты**: `openssl x509 -in /etc/nginx/ssl/fullchain.pem -text -noout`
23. **Проверьте базу данных**: `docker exec -it contract-postgres psql -U contract_user -d contract_db -c "SELECT version();"`
24. **Проверьте Docker volumes**: `docker volume ls` и `docker volume inspect postgres_data`
25. **Проверьте Docker networks**: `docker network ls` и `docker network inspect contract-network`
26. **Проверьте Docker images**: `docker images` и `docker history nginx:alpine`

### 🔍 **Git-specific проблемы:**
```bash
# Проверка Git статуса
ssh root@185.179.83.236 "cd /opt/contract-app && git status"

# Проверка последних коммитов
ssh root@185.179.83.236 "cd /opt/contract-app && git log --oneline -5"

# Проверка веток
ssh root@185.179.83.236 "cd /opt/contract-app && git branch -a"

# Проверка remote origin
ssh root@185.179.83.236 "cd /opt/contract-app && git remote -v"
```

### 🚨 **Частые проблемы:**
- **Git не настроен**: `git remote add origin <url>`
- **Ветка не существует**: `git push -u origin master`
- **Незакоммиченные изменения**: `git add . && git commit -m "message"`

## 🎯 Следующие шаги

После успешного деплоя рекомендуется:

1. **Настроить Git workflow** (feature branches, pull requests)
2. **Создать теги для версий** (git tag v1.0.0)
3. **Настроить CI/CD** (GitHub Actions, GitLab CI)
4. **Настроить мониторинг** (например, через UptimeRobot)
5. **Настроить автоматические резервные копии**
6. **Настроить уведомления** о критических ошибках
7. **Добавить аналитику** (Google Analytics, Yandex.Metrica)
8. **Настроить CDN** для статических файлов

### 🔄 **Автоматизация деплоя:**
```bash
# Создание тега и автоматический деплой
git tag v1.1.0
git push origin v1.1.0
./server-manage.sh deploy v1.1.0

# Деплой staging ветки
./server-manage.sh deploy develop

# Деплой production
./deploy.sh
```

---

**Удачи с деплоем! 🚀**
