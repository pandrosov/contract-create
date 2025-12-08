# Руководство по обновлению приложения на удаленном сервере

## Быстрое обновление (без восстановления БД)

### Шаг 1: Отправка изменений в репозиторий
```bash
# Локально
git add .
git commit -m "Описание изменений"
git push origin master
```

### Шаг 2: Обновление на сервере
```bash
# Подключение к серверу
ssh -i ~/.ssh/id_rsa_deploy root@185.179.83.236

# Обновление кода
cd /opt/contract-app
git pull origin master

# Перезапуск только backend (БД не трогается)
docker-compose -f docker-compose.prod.yaml up -d --build backend

# Проверка статуса
docker-compose -f docker-compose.prod.yaml ps
```

### Шаг 3: Проверка работоспособности
```bash
# Проверка health endpoint
curl http://localhost:8000/health

# Или через веб-интерфейс
# Откройте https://contract.alnilam.by
```

## Что обновляется

- ✅ **Код приложения** (Python файлы)
- ✅ **Backend контейнер** (пересобирается с новым кодом)
- ❌ **База данных** (НЕ трогается - данные сохраняются)
- ❌ **Frontend контейнер** (перезапускается только при изменении frontend кода)
- ❌ **Nginx контейнер** (перезапускается только при изменении конфигурации)

## Полное обновление (если нужно обновить все контейнеры)

```bash
cd /opt/contract-app
git pull origin master
docker-compose -f docker-compose.prod.yaml up -d --build
```

⚠️ **Внимание**: Полное обновление пересоберет все контейнеры, но база данных все равно не будет затронута (используется volume).

## Откат изменений (если что-то пошло не так)

```bash
cd /opt/contract-app
git log --oneline -10  # Смотрим историю коммитов
git checkout <commit_hash>  # Откатываемся к нужному коммиту
docker-compose -f docker-compose.prod.yaml up -d --build backend
```

## Проверка логов

```bash
# Логи backend
docker-compose -f docker-compose.prod.yaml logs backend --tail 50

# Логи всех сервисов
docker-compose -f docker-compose.prod.yaml logs --tail 50
```

## Важные замечания

1. **База данных сохраняется** - используется Docker volume `postgres_data`, который не удаляется при обновлении
2. **Шаблоны сохраняются** - файлы в папке `templates/` не удаляются
3. **Загруженные файлы** - все загруженные шаблоны остаются в базе данных и файловой системе
4. **Настройки** - все настройки в базе данных сохраняются

## Автоматизация (опционально)

Можно создать скрипт для автоматического обновления:

```bash
#!/bin/bash
# scripts/update_server.sh

cd /opt/contract-app
git pull origin master
docker-compose -f docker-compose.prod.yaml up -d --build backend
echo "✅ Обновление завершено"
```

