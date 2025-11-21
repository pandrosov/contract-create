#!/bin/bash
#
# Скрипт для автоматического обновления SSL сертификатов Let's Encrypt
# и их копирования в Nginx контейнер
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="/opt/contract-app"
DOMAIN="contract.alnilam.by"
NGINX_CONTAINER="contract-nginx"

echo "🔐 Начало обновления SSL сертификатов для ${DOMAIN}..."

# Переходим в директорию проекта
cd "${PROJECT_DIR}"

# Обновляем сертификаты через certbot
echo "📝 Проверяем и обновляем сертификаты через certbot..."

# Проверяем, нужно ли обновление (сертификат истекает менее чем через 30 дней)
CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
if [ -f "${CERT_PATH}" ]; then
    EXPIRY_DATE=$(openssl x509 -enddate -noout -in "${CERT_PATH}" | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "${EXPIRY_DATE}" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "${EXPIRY_DATE}" +%s 2>/dev/null)
    CURRENT_EPOCH=$(date +%s)
    DAYS_UNTIL_EXPIRY=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))
    
    echo "📅 Дней до истечения сертификата: ${DAYS_UNTIL_EXPIRY}"
    
    if [ ${DAYS_UNTIL_EXPIRY} -gt 30 ]; then
        echo "✅ Сертификат действителен более 30 дней, обновление не требуется"
        SKIP_RENEWAL=true
    fi
fi

# Обновляем сертификаты, если нужно
if [ "${SKIP_RENEWAL}" != "true" ]; then
    # Пробуем обновить через webroot (текущий метод)
    if certbot renew --quiet --no-random-sleep-on-renew 2>&1 | grep -q "No renewals were attempted"; then
        echo "ℹ️ Обновление не требуется (сертификат еще действителен)"
    elif certbot renew --quiet --no-random-sleep-on-renew; then
        echo "✅ Сертификаты обновлены"
        CERT_UPDATED=true
    else
        echo "⚠️ Автоматическое обновление не удалось, используем текущие сертификаты"
        CERT_UPDATED=false
    fi
else
    CERT_UPDATED=false
fi

# Проверяем, были ли обновлены сертификаты
CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
if [ ! -f "${CERT_PATH}" ]; then
    echo "❌ Сертификаты не найдены по пути ${CERT_PATH}"
    exit 1
fi

# Проверяем, запущен ли контейнер Nginx
if ! docker ps | grep -q "${NGINX_CONTAINER}"; then
    echo "⚠️ Контейнер ${NGINX_CONTAINER} не запущен, пропускаем копирование"
    exit 0
fi

# Копируем обновленные сертификаты в контейнер
echo "📋 Копируем обновленные сертификаты в контейнер ${NGINX_CONTAINER}..."

# Получаем реальные пути к файлам (разрешаем симлинки)
REAL_CERT_PATH=$(readlink -f "${CERT_PATH}" 2>/dev/null || echo "${CERT_PATH}")
PRIVKEY_PATH="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
REAL_PRIVKEY_PATH=$(readlink -f "${PRIVKEY_PATH}" 2>/dev/null || echo "${PRIVKEY_PATH}")

# Копируем fullchain.pem (используем реальный путь)
if [ -f "${REAL_CERT_PATH}" ]; then
    docker cp "${REAL_CERT_PATH}" "${NGINX_CONTAINER}:/etc/nginx/ssl/fullchain.pem"
    if [ $? -eq 0 ]; then
        echo "✅ fullchain.pem скопирован"
    else
        echo "❌ Ошибка копирования fullchain.pem"
        exit 1
    fi
else
    echo "❌ Файл сертификата не найден: ${REAL_CERT_PATH}"
    exit 1
fi

# Копируем privkey.pem (используем реальный путь)
if [ -f "${REAL_PRIVKEY_PATH}" ]; then
    docker cp "${REAL_PRIVKEY_PATH}" "${NGINX_CONTAINER}:/etc/nginx/ssl/privkey.pem"
    if [ $? -eq 0 ]; then
        echo "✅ privkey.pem скопирован"
    else
        echo "❌ Ошибка копирования privkey.pem"
        exit 1
    fi
else
    echo "❌ Файл приватного ключа не найден: ${REAL_PRIVKEY_PATH}"
    exit 1
fi

# Устанавливаем правильные права в контейнере
docker exec "${NGINX_CONTAINER}" chmod 644 /etc/nginx/ssl/fullchain.pem
docker exec "${NGINX_CONTAINER}" chmod 600 /etc/nginx/ssl/privkey.pem

# Проверяем конфигурацию nginx перед перезагрузкой
echo "🔍 Проверяем конфигурацию nginx..."
if docker exec "${NGINX_CONTAINER}" nginx -t; then
    echo "✅ Конфигурация nginx корректна"
else
    echo "❌ Ошибка в конфигурации nginx!"
    exit 1
fi

# Перезагружаем nginx для применения новых сертификатов
echo "🔄 Перезагружаем nginx..."
docker exec "${NGINX_CONTAINER}" nginx -s reload

if [ $? -eq 0 ]; then
    echo "✅ Nginx успешно перезагружен с новыми сертификатами"
    echo "🎉 Обновление SSL сертификатов завершено успешно!"
else
    echo "❌ Ошибка при перезагрузке nginx"
    exit 1
fi

