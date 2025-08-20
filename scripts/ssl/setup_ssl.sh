#!/bin/bash

# Скрипт для автоматической настройки SSL сертификатов
# Запускается при деплое приложения

set -e

echo "🔐 Настройка SSL сертификатов..."

# Создаем директории для SSL
mkdir -p /opt/contract-app/nginx/ssl
mkdir -p /var/www/certbot

# Проверяем, есть ли уже сертификаты
if [ -f "/etc/letsencrypt/live/contract.alnilam.by/fullchain.pem" ]; then
    echo "✅ SSL сертификаты уже существуют, копируем их..."
    cp /etc/letsencrypt/live/contract.alnilam.by/fullchain.pem /opt/contract-app/nginx/ssl/
    cp /etc/letsencrypt/live/contract.alnilam.by/privkey.pem /opt/contract-app/nginx/ssl/
    echo "✅ SSL сертификаты скопированы"
else
    echo "⚠️ SSL сертификаты не найдены, получаем новые..."
    
    # Останавливаем nginx для освобождения порта 80
    cd /opt/contract-app
    docker-compose -f docker-compose.prod.yaml stop nginx 2>/dev/null || true
    
    # Получаем сертификаты
    certbot certonly --webroot -w /var/www/certbot -d contract.alnilam.by -d www.contract.alnilam.by --non-interactive --agree-tos --email admin@alnilam.by
    
    # Копируем сертификаты
    cp /etc/letsencrypt/live/contract.alnilam.by/fullchain.pem /opt/contract-app/nginx/ssl/
    cp /etc/letsencrypt/live/contract.alnilam.by/privkey.pem /opt/contract-app/nginx/ssl/
    
    echo "✅ Новые SSL сертификаты получены и скопированы"
fi

# Устанавливаем правильные права
chmod 644 /opt/contract-app/nginx/ssl/fullchain.pem
chmod 600 /opt/contract-app/nginx/ssl/privkey.pem

echo "✅ SSL сертификаты настроены успешно"
