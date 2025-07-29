# 🚀 Быстрый деплой на удаленный сервер

## 📋 Что у нас есть

✅ **Готовый проект:** https://github.com/pandrosov/contract-create.git  
✅ **Ветка для production:** master  
✅ **Версия:** v1.1.0  
✅ **Автоматический скрипт деплоя:** `remote_deploy.sh`

## 🎯 Варианты деплоя

### 1. Автоматический деплой (рекомендуется)

```bash
# Сделать скрипт исполняемым
chmod +x remote_deploy.sh

# Запуск деплоя
./remote_deploy.sh YOUR_SERVER_IP YOUR_DOMAIN

# Пример:
./remote_deploy.sh 192.168.1.100 mydomain.com
```

### 2. Ручной деплой

```bash
# 1. Подключитесь к серверу
ssh user@YOUR_SERVER_IP

# 2. Подготовьте сервер
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3. Клонируйте проект
mkdir -p /opt/contract-manager
cd /opt/contract-manager
git clone -b master https://github.com/pandrosov/contract-create.git .

# 4. Настройте окружение
cp env.example .env
# Отредактируйте .env файл

# 5. Запустите деплой
chmod +x deploy.sh
./deploy.sh production
```

## 🔧 Настройка .env файла

```env
# Обязательные настройки
POSTGRES_PASSWORD=your_secure_password
SECRET_KEY=your-super-secret-key
DOMAIN=your-domain.com
CORS_ORIGINS=https://your-domain.com
REACT_APP_API_URL=https://your-domain.com/api
```

## 🌐 После деплоя

- **Фронтенд:** http://YOUR_SERVER_IP или https://YOUR_DOMAIN
- **API:** http://YOUR_SERVER_IP:8000 или https://YOUR_DOMAIN/api
- **Админ:** admin/admin

## 🔧 Управление

```bash
# Просмотр логов
docker-compose -f docker-compose.prod.yaml logs -f

# Перезапуск
docker-compose -f docker-compose.prod.yaml restart

# Обновление
git pull origin master
docker-compose -f docker-compose.prod.yaml up --build -d
```

## 📞 Поддержка

Если что-то не работает:

1. **Проверьте логи:** `docker-compose -f docker-compose.prod.yaml logs -f`
2. **Проверьте статус:** `docker-compose -f docker-compose.prod.yaml ps`
3. **Проверьте порты:** `sudo netstat -tlnp | grep :80`

## 🎯 Результат

После успешного деплоя у вас будет полностью рабочая система управления договорами с:

- ✅ Красивым современным интерфейсом
- ✅ Валидацией форм
- ✅ Системой уведомлений
- ✅ Адаптивным дизайном
- ✅ SSL сертификатами
- ✅ Резервным копированием

**Готово к использованию! 🚀** 