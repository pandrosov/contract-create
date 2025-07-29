#!/bin/bash

# Скрипт для обновления Let's Encrypt сертификата
# Запускается автоматически через cron

set -e

echo "$(date): Starting SSL certificate renewal..."

# Останавливаем nginx для освобождения порта 80
cd /opt/contract-manager
docker-compose -f docker-compose.prod.yaml stop nginx

# Обновляем сертификат
certbot renew --quiet

# Копируем новые сертификаты
cp /etc/letsencrypt/live/contract.alnilam.by/fullchain.pem /opt/contract-manager/nginx/ssl/
cp /etc/letsencrypt/live/contract.alnilam.by/privkey.pem /opt/contract-manager/nginx/ssl/

# Перезапускаем nginx
docker-compose -f docker-compose.prod.yaml up -d nginx

echo "$(date): SSL certificate renewal completed successfully"

# Проверяем статус
if curl -s -I https://contract.alnilam.by > /dev/null; then
    echo "$(date): HTTPS is working correctly"
else
    echo "$(date): ERROR - HTTPS is not working!"
    exit 1
fi 