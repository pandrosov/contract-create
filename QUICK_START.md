# 🚀 Быстрый старт деплоя

## ⚡ Выполните эти команды по порядку:

### 1. Настройка SSH доступа
```bash
# Генерация SSH ключа (если еще не создан)
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Копирование ключа на сервер
ssh-copy-id root@185.179.83.236

# Проверка подключения
ssh root@185.179.83.236 "echo 'SSH доступ настроен'"
```

### 2. Запуск деплоя
```bash
# Сделать скрипты исполняемыми
chmod +x deploy.sh server-manage.sh health-check.sh

# Запустить полный деплой
./deploy.sh
```

### 3. Проверка работы
```bash
# Проверка здоровья системы
./health-check.sh

# Управление приложением
./server-manage.sh status
```

## 🌐 После успешного деплоя:

- **Frontend**: https://contract.alnilam.by
- **API**: https://contract.alnilam.by/api
- **Health Check**: https://contract.alnilam.by/health

## 🛠️ Основные команды управления:

```bash
./server-manage.sh start      # Запуск
./server-manage.sh stop       # Остановка
./server-manage.sh restart    # Перезапуск
./server-manage.sh logs       # Логи
./server-manage.sh status     # Статус
./server-manage.sh update     # Обновление
```

## 📚 Подробная документация:

См. файл `DEPLOY_INSTRUCTIONS.md` для детальных инструкций.

---

**Время выполнения деплоя: ~10-15 минут** ⏱️
