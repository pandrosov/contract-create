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
- **Docker и Docker Compose** на сервере
- **PostgreSQL базу данных** с безопасными паролями
- **Nginx reverse proxy** с SSL сертификатами
- **Firewall** (только необходимые порты)
- **SSL сертификаты Let's Encrypt** с автообновлением
- **CORS настройки** для вашего домена
- **Rate limiting** для API
- **Логирование** и мониторинг

### 🌐 Результат:
- **Frontend**: https://contract.alnilam.by
- **API**: https://contract.alnilam.by/api
- **Health Check**: https://contract.alnilam.by/health

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
./server-manage.sh shell      # Shell на сервере
```

### Резервные копии:
```bash
./backup.sh full              # Полный бэкап
./backup.sh db                # Только БД
./backup.sh files             # Только файлы
./backup.sh info              # Информация
./backup.sh cleanup           # Очистка старых
```

### Мониторинг:
```bash
./health-check.sh             # Полная проверка
./server-manage.sh status     # Статус сервисов
./server-manage.sh logs       # Логи в реальном времени
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

### Использование ресурсов:
```bash
./server-manage.sh status
ssh root@185.179.83.236 "docker stats"
```

## 🔄 Обновление приложения

### Автоматическое:
```bash
./server-manage.sh update
```

### Ручное:
```bash
ssh root@185.179.83.236
cd /opt/contract-app
git pull origin main
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

### Автоматические:
- **База данных**: SQL dump
- **Файлы**: сжатый архив
- **Метаданные**: JSON с информацией
- **Хранение**: 30 дней
- **Локальные копии**: скачиваются автоматически

### Восстановление:
```bash
./backup.sh restore db_backup_20241201_120000.sql
./backup.sh restore files_backup_20241201_120000.tar.gz
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

После успешного деплоя:
1. **Настройте мониторинг** (UptimeRobot)
2. **Настройте аналитику** (Google Analytics)
3. **Настройте уведомления** (Telegram Bot)
4. **Настройте CDN** (Cloudflare)
5. **Настройте автоматические бэкапы** (cron)

---

## 🚀 Готово к деплою!

**Время выполнения**: ~10-15 минут  
**Сложность**: Автоматизировано  
**Результат**: Продакшн готовое приложение  

**Начните с `QUICK_START.md` для быстрого старта!** 🎉
