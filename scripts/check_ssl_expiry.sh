#!/bin/bash
#
# Скрипт для проверки срока действия SSL сертификатов
#

DOMAIN="contract.alnilam.by"
CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"

if [ ! -f "${CERT_PATH}" ]; then
    echo "❌ Сертификат не найден: ${CERT_PATH}"
    exit 1
fi

# Получаем дату истечения сертификата
EXPIRY_DATE=$(openssl x509 -enddate -noout -in "${CERT_PATH}" | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "${EXPIRY_DATE}" +%s)
CURRENT_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( (EXPIRY_EPOCH - CURRENT_EPOCH) / 86400 ))

echo "📅 Сертификат для ${DOMAIN}:"
echo "   Дата истечения: ${EXPIRY_DATE}"
echo "   Дней до истечения: ${DAYS_UNTIL_EXPIRY}"

if [ ${DAYS_UNTIL_EXPIRY} -lt 30 ]; then
    echo "⚠️ ВНИМАНИЕ: Сертификат истекает менее чем через 30 дней!"
    exit 1
elif [ ${DAYS_UNTIL_EXPIRY} -lt 7 ]; then
    echo "🔴 КРИТИЧНО: Сертификат истекает менее чем через 7 дней!"
    exit 2
else
    echo "✅ Сертификат действителен"
    exit 0
fi

