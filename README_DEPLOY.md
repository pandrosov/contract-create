# 🚀 Полный гайд по деплою приложения

## 📁 Структура файлов деплоя

```
├── deploy.sh              # Основной скрипт деплоя
├── server-manage.sh       # Управление приложением на сервере
├── health-check.sh        # Проверка здоровья системы
├── backup.sh              # Создание и управление резервными копиями
├── QUICK_START.md         # Быстрый старт
├── DEPLOY_INSTRUCTIONS.md # Подробные инструкции
├── production.env         # Пример переменных окружения
└── README_DEPLOY.md       # Этот файл
```

## 🎯 Что делает система деплоя

### ✅ Автоматически настраивает:
- **Git-based деплой** (основной метод)
- **Docker и Docker Compose** на сервере
- **PostgreSQL базу данных** с безопасными паролями
- **Nginx reverse proxy** с SSL сертификатами
- **Firewall** (только необходимые порты)
- **SSL сертификаты Let's Encrypt** с автообновлением
- **CORS настройки** для вашего домена
- **Rate limiting** для API
- **Логирование** и мониторинг

### 🔄 Логика деплоя:
1. **Git репозиторий** (рекомендуется) - клонирование/обновление
2. **Fallback на SCP** - если Git недоступен
3. **Автоматическая установка** всех зависимостей
4. **Настройка безопасности** и SSL
5. **Запуск приложения** в Docker

### 🌟 **Ключевые преимущества:**
- **Версионность** - полная история изменений
- **Откат** - легко вернуться к предыдущей версии
- **Ветки** - деплой разных версий
- **Теги** - деплой релизов
- **Безопасность** - проверка целостности кода
- **Коллаборация** - работа в команде
- **Автоматизация** - CI/CD интеграция
- **Надежность** - проверка целостности файлов
- **Эффективность** - только изменения
- **Скорость** - быстрые деплои
- **Мониторинг** - полная трассировка
- **Стандарты** - лучшие практики DevOps
- **Масштабируемость** - легко добавить новые серверы
- **Простота** - понятные команды
- **Документация** - встроенная в Git

### 🌐 Результат:
- **Frontend**: https://contract.alnilam.by
- **API**: https://contract.alnilam.by/api
- **Health Check**: https://contract.alnilam.by/health

## 📋 Рекомендуемый Git workflow

### 🌿 **Структура веток:**
```
master          # Основная ветка для продакшена
├── develop     # Ветка разработки
├── feature/*   # Feature ветки
├── hotfix/*    # Срочные исправления
└── release/*   # Подготовка релизов
```

### 🔄 **Процесс разработки:**
1. **Создание feature ветки:**
   ```bash
   git checkout -b feature/new-feature
   # Разработка...
   git commit -m "Add new feature"
   git push origin feature/new-feature
   ```

2. **Создание Pull Request** в GitHub/GitLab

3. **Code Review** и тестирование

4. **Merge в develop** после одобрения

5. **Деплой в staging** для тестирования

6. **Merge в master** для продакшена

### 🚀 **Деплой:**
```bash
# Деплой master ветки
./deploy.sh

# Деплой конкретной ветки
./server-manage.sh deploy develop

# Деплой тега (релиза)
git tag v1.2.0
git push origin v1.2.0
./server-manage.sh deploy v1.2.0
```

### 📊 **Мониторинг деплоев:**
```bash
# Статус приложения
./server-manage.sh status

# Git статус на сервере
ssh root@185.179.83.236 "cd /opt/contract-app && git log --oneline -10"

# История деплоев
./health-check.sh
```

### 🔄 **Автоматизация:**
```bash
# GitHub Actions для автоматического деплоя
# .github/workflows/deploy.yml

# GitLab CI для автоматического деплоя
# .gitlab-ci.yml

# Автоматический деплой при push в master
git push origin master
# → Автоматический деплой на сервер
```

## 🚀 Быстрый старт (5 минут)

### 1. Настройка SSH
```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
ssh-copy-id root@185.179.83.236
ssh root@185.179.83.236 "echo 'SSH готов'"
```

### 2. Запуск деплоя
```bash
chmod +x *.sh
./deploy.sh
```

### 3. Проверка
```bash
./health-check.sh
./server-manage.sh status
```

## 🛠️ Команды управления

### Основные операции:
```bash
./server-manage.sh start      # Запуск
./server-manage.sh stop       # Остановка
./server-manage.sh restart    # Перезапуск
./server-manage.sh status     # Статус
./server-manage.sh logs       # Логи
./server-manage.sh update     # Обновление
```

### Git-based операции:
```bash
./server-manage.sh update     # Обновление до последней версии
./server-manage.sh deploy master    # Деплой master ветки
./server-manage.sh deploy develop   # Деплой develop ветки
./server-manage.sh deploy v1.0.0   # Деплой тега
```

### Резервные копии:
```bash
./backup.sh full              # Полный бэкап
./backup.sh db                # Только БД
./backup.sh files             # Только файлы
./backup.sh info              # Информация
```

### Мониторинг:
```bash
./health-check.sh             # Полная проверка
./server-manage.sh status     # Статус сервисов
```

## 🔒 Безопасность

### Автоматически настроено:
- ✅ **Firewall**: только порты 22, 80, 443, 8000
- ✅ **SSL**: Let's Encrypt с автообновлением
- ✅ **Пароли**: случайно генерируются для каждого деплоя
- ✅ **CORS**: ограничен вашим доменом
- ✅ **Rate limiting**: 10 запросов/сек на API

### Рекомендуется дополнительно:
- 🔐 Изменить пароли в `.env` на сервере
- 🔐 Настроить регулярные бэкапы
- 🔐 Мониторинг логов

## 📊 Мониторинг и логи

### Логи в реальном времени:
```bash
# Все сервисы
./server-manage.sh logs

# Конкретный сервис
ssh root@185.179.83.236 "cd /opt/contract-app && docker-compose -f docker-compose.prod.yaml logs -f backend"
```

### Git мониторинг:
```bash
# Статус Git на сервере
ssh root@185.179.83.236 "cd /opt/contract-app && git status"

# История коммитов
ssh root@185.179.83.236 "cd /opt/contract-app && git log --oneline -10"

# Информация о ветках
ssh root@185.179.83.236 "cd /opt/contract-app && git branch -a"
```

### Использование ресурсов:
```bash
./server-manage.sh status
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

# Пересобрать и запустить
docker-compose -f docker-compose.prod.yaml up -d --build
```

## 🚨 Устранение неполадок

### Проблема: SSH не работает
```bash
# Проверьте IP и ключи
ssh -v root@185.179.83.236
```

### Проблема: Приложение не запускается
```bash
./server-manage.sh logs
./health-check.sh
```

### Проблема: SSL не работает
```bash
./server-manage.sh ssl
```

### Проблема: База данных недоступна
```bash
ssh root@185.179.83.236 "cd /opt/contract-app && docker-compose -f docker-compose.prod.yaml exec postgres pg_isready"
```

## 📈 Производительность

### Настройки по умолчанию:
- **Workers**: 4 (backend)
- **Max connections**: 1000 (nginx)
- **Timeout**: 30 секунд
- **Gzip compression**: включен
- **Static file caching**: 1 год

### Мониторинг:
```bash
./health-check.sh
ssh root@185.179.83.236 "htop"
ssh root@185.179.83.236 "docker stats"
```

## 💾 Резервные копии

### Git-based резервные копии:
```bash
# Создание тега для версии
git tag v1.0.0
git push origin v1.0.0

# Восстановление из тега
./server-manage.sh deploy v1.0.0
```

### Традиционные резервные копии:
```bash
# База данных
./backup.sh db

# Файлы приложения
./backup.sh files

# Полный бэкап
./backup.sh full
```

### Автоматические:
- **Git теги** - версионность кода
- **База данных** - SQL dump
- **Файлы** - сжатый архив
- **Метаданные** - JSON с информацией
- **Хранение** - 30 дней
- **Локальные копии** - скачиваются автоматически

### Восстановление:
```bash
# Восстановление БД
./backup.sh restore db_backup_20241201_120000.sql

# Восстановление файлов
./backup.sh restore files_backup_20241201_120000.tar.gz

# Восстановление версии кода
./server-manage.sh deploy v1.0.0
```

## 🌍 Домен и SSL

### Требования:
- Домен `contract.alnilam.by` должен указывать на `185.179.83.236`
- Порты 80 и 443 должны быть открыты

### SSL сертификаты:
- **Автоматически**: Let's Encrypt
- **Обновление**: каждые 60 дней
- **Проверка**: `./health-check.sh`

## 📱 Уведомления и мониторинг

### Рекомендуемые сервисы:
- **UptimeRobot**: мониторинг доступности
- **Google Analytics**: аналитика
- **Yandex.Metrica**: аналитика
- **Telegram Bot**: уведомления об ошибках

## 🔧 Кастомизация

### Переменные окружения:
Файл `.env` на сервере содержит все настройки:
- Пароли базы данных
- Секретные ключи
- CORS настройки
- Логирование
- Бэкапы

### Nginx конфигурация:
Файл `nginx/nginx.conf` настраивает:
- SSL
- Rate limiting
- Gzip
- Кэширование
- CORS заголовки

## 📞 Поддержка

### При проблемах:
1. **Проверьте логи**: `./server-manage.sh logs`
2. **Проверьте статус**: `./server-manage.sh status`
3. **Проверьте здоровье**: `./health-check.sh`
4. **Проверьте SSH**: `ssh root@185.179.83.236`

### Полезные команды:
```bash
# Перезапуск всех сервисов
./server-manage.sh restart

# Перезапуск только nginx
ssh root@185.179.83.236 "cd /opt/contract-app && docker-compose -f docker-compose.prod.yaml restart nginx"

# Проверка SSL
echo | openssl s_client -servername contract.alnilam.by -connect contract.alnilam.by:443
```

## 🎯 Следующие шаги

После успешного деплоя рекомендуется:

1. **Настроить Git workflow** (feature branches, pull requests)
2. **Создать теги для версий** (git tag v1.0.0)
3. **Настроить CI/CD** (GitHub Actions, GitLab CI)
4. **Настроить мониторинг** (UptimeRobot)
5. **Настроить аналитику** (Google Analytics, Yandex.Metrica)
6. **Настроить уведомления** (Telegram Bot)
7. **Настроить CDN** (Cloudflare)
8. **Настроить автоматические бэкапы** (cron)

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

## 🚀 Готово к деплою!

**Все файлы созданы и настроены для автоматического деплоя вашего приложения на сервер `185.179.83.236`**

### 🌟 **Новый Git-based подход:**
- **Версионность** - полная история изменений
- **Откат** - легко вернуться к предыдущей версии
- **Ветки** - деплой разных версий
- **Теги** - деплой релизов
- **Безопасность** - проверка целостности кода

### 📚 **Документация:**
- **`QUICK_START.md`** - Быстрый старт с Git
- **`DEPLOY_INSTRUCTIONS.md`** - Подробные инструкции
- **`README_DEPLOY.md`** - Полный гайд

**Начните с `QUICK_START.md` для быстрого старта!** 🎉

## 🎯 Преимущества Git-based деплоя

### ✅ **Почему Git лучше rsync:**
- **Версионность** - полная история изменений
- **Откат** - легко вернуться к предыдущей версии
- **Ветки** - деплой разных версий и feature'ов
- **Теги** - деплой релизов и стабильных версий
- **Синхронизация** - автоматическое обновление с удаленного репозитория
- **Безопасность** - проверка целостности кода
- **Коллаборация** - работа в команде через pull requests

### 🚀 **Скорость и эффективность:**
- **Только изменения** - не копируются все файлы каждый раз
- **Сжатие** - Git автоматически сжимает данные
- **Кэширование** - локальные копии для быстрого доступа
- **Инкрементальные обновления** - только новые коммиты

### 🔒 **Надежность:**
- **Проверка целостности** - SHA1 хеши для каждого файла
- **Автоматическое восстановление** - при повреждении файлов
- **История изменений** - полная трассировка всех деплоев

### 📊 **Сравнение с rsync:**
| Аспект | rsync | Git |
|--------|--------|-----|
| **Версионность** | ❌ Нет | ✅ Полная история |
| **Откат** | ❌ Сложно | ✅ Легко |
| **Ветки** | ❌ Нет | ✅ Поддержка |
| **Теги** | ❌ Нет | ✅ Версии |
| **Целостность** | ❌ Базово | ✅ SHA1 хеши |
| **Скорость** | ✅ Быстро | ✅ Очень быстро |
| **Надежность** | ⚠️ Средне | ✅ Высокая |
