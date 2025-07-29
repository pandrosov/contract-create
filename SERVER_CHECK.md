# 🔍 Проверка сервера перед деплоем

## 📋 Ваша конфигурация

- **Сервер:** 178.172.138.229
- **Пользователь:** root
- **Домен:** contract.alnilam.by
- **Проект:** Contract Manager

## 🚀 Быстрая проверка

### 1. Проверка конфигурации сервера

```bash
# Запустите скрипт проверки
./check_server.sh
```

Этот скрипт проверит:
- ✅ Системную информацию
- ✅ Ресурсы (CPU, RAM, диск)
- ✅ Установку Docker и Docker Compose
- ✅ Существующие контейнеры
- ✅ Сетевую конфигурацию
- ✅ Доступность портов
- ✅ DNS разрешение

### 2. Ручная проверка (альтернатива)

```bash
# Подключение к серверу
ssh root@178.172.138.229

# Проверка системы
uname -a
cat /etc/os-release
free -h
df -h

# Проверка Docker
docker --version
docker-compose --version
docker ps -a

# Проверка портов
netstat -tlnp | grep -E ':(80|443|8000|5437)'

# Проверка DNS
nslookup contract.alnilam.by
```

## 🔧 Что проверить

### 1. Системные требования

- ✅ **ОС:** Ubuntu 20.04+ или CentOS 8+
- ✅ **RAM:** Минимум 2 GB (рекомендуется 4 GB)
- ✅ **Диск:** Минимум 10 GB свободного места
- ✅ **Docker:** Версия 20.10+
- ✅ **Docker Compose:** Версия 2.0+

### 2. Сетевые порты

Проверьте, что порты свободны:
- **80** - HTTP (фронтенд)
- **443** - HTTPS (фронтенд)
- **8000** - API (бэкенд)
- **5437** - PostgreSQL (база данных)

### 3. Существующие контейнеры

Убедитесь, что нет конфликтов с существующими контейнерами:
```bash
docker ps -a
```

### 4. DNS настройки

Проверьте, что домен указывает на сервер:
```bash
nslookup contract.alnilam.by
```

## 🚨 Возможные проблемы

### 1. Порт занят

```bash
# Найти процесс, использующий порт
sudo netstat -tlnp | grep :80
sudo lsof -i :80

# Остановить процесс (если нужно)
sudo systemctl stop nginx
```

### 2. Docker не установлен

```bash
# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 3. Недостаточно места

```bash
# Очистка Docker
docker system prune -a

# Очистка логов
sudo journalctl --vacuum-time=3d
```

## ✅ Готовность к деплою

После успешной проверки у вас должно быть:

- ✅ Все системные требования выполнены
- ✅ Docker и Docker Compose установлены
- ✅ Необходимые порты свободны
- ✅ Достаточно места на диске
- ✅ DNS настроен правильно

## 🚀 Следующие шаги

1. **Запустите проверку:** `./check_server.sh`
2. **Если все в порядке:** `./deploy_alnilam.sh`
3. **Или ручной деплой:** следуйте инструкции в `REMOTE_DEPLOYMENT.md`

## 📞 Поддержка

Если возникли проблемы:

1. **Проверьте логи:** `docker logs <container_name>`
2. **Проверьте статус:** `docker ps -a`
3. **Проверьте ресурсы:** `docker stats`
4. **Проверьте сеть:** `docker network ls`

**Готово к проверке! 🔍** 