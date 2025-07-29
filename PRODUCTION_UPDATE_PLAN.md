# План обновления продакшена

## 🎯 Цель
Безопасно применить изменения структуры проекта на продакшен сервере без нарушения работы системы.

## 📋 Пошаговый план

### 1. Подготовка (5 минут)
```bash
# Проверка текущего состояния сервера
ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml ps"

# Проверка доступности сервисов
curl -I https://contract.alnilam.by
curl -I https://contract.alnilam.by/api/health
```

### 2. Резервное копирование (5 минут)
```bash
# Создание бэкапа текущего состояния
ssh root@178.172.138.229 "cd /opt/contract-manager && ./scripts/deployment/backup.sh"

# Проверка создания бэкапа
ssh root@178.172.138.229 "ls -la /opt/contract-manager/backups/"
```

### 3. Обновление кода (10 минут)
```bash
# Переход в директорию проекта
ssh root@178.172.138.229 "cd /opt/contract-manager"

# Получение последних изменений
git fetch origin
git reset --hard origin/master

# Проверка изменений
git log --oneline -5
```

### 4. Проверка структуры (5 минут)
```bash
# Проверка новой структуры файлов
ssh root@178.172.138.229 "cd /opt/contract-manager && find . -name '*.py' -o -name '*.sh' | head -20"

# Проверка наличия ключевых файлов
ssh root@178.172.138.229 "cd /opt/contract-manager && ls -la app/main.py app/auth.py app/db.py"
```

### 5. Обновление контейнеров (15 минут)
```bash
# Остановка сервисов
ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml down"

# Пересборка с новой структурой
ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml build --no-cache"

# Запуск сервисов
ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml up -d"

# Ожидание запуска
sleep 30
```

### 6. Проверка работоспособности (10 минут)
```bash
# Проверка статуса контейнеров
ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml ps"

# Проверка логов бэкенда
ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml logs backend --tail=20"

# Проверка health check
curl -I https://contract.alnilam.by/api/health

# Проверка основного сайта
curl -I https://contract.alnilam.by
```

### 7. Тестирование функциональности (15 минут)
```bash
# Тест аутентификации
curl -X POST https://contract.alnilam.by/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Contract2024!"}'

# Тест API документации
curl -I https://contract.alnilam.by/api/docs

# Проверка SSL сертификата
openssl s_client -connect contract.alnilam.by:443 -servername contract.alnilam.by < /dev/null
```

### 8. Откат (если что-то пошло не так)
```bash
# Восстановление из бэкапа
ssh root@178.172.138.229 "cd /opt/contract-manager && git reset --hard HEAD~1"
ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml down && docker-compose -f docker-compose.prod.yaml up -d"
```

## ⚠️ Риски и меры предосторожности

### Риски:
1. **Неправильные импорты** - может сломать бэкенд
2. **Изменение путей** - может сломать скрипты
3. **Проблемы с Docker** - может не собраться

### Меры предосторожности:
1. **Бэкап перед обновлением** ✅
2. **Поэтапная проверка** ✅
3. **Возможность быстрого отката** ✅
4. **Мониторинг логов** ✅

## 🔍 Критерии успеха

### ✅ Обязательные проверки:
- [ ] Все контейнеры запущены
- [ ] Health check отвечает
- [ ] SSL сертификат работает
- [ ] API документация доступна
- [ ] Логи без критических ошибок

### ✅ Дополнительные проверки:
- [ ] Фронтенд загружается
- [ ] Аутентификация работает
- [ ] Скрипты выполняются
- [ ] Структура файлов правильная

## 📊 Временные рамки

- **Общее время**: ~60 минут
- **Критическое время простоя**: ~5 минут (перезапуск контейнеров)
- **Время отката**: ~10 минут

## 🚨 Команды для экстренного отката

```bash
# Если что-то пошло не так
ssh root@178.172.138.229 "cd /opt/contract-manager && git reset --hard HEAD~1"
ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml down"
ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml up -d"
```

---

**Дата**: 2025-07-29  
**Статус**: Готов к выполнению  
**Время**: ~60 минут 