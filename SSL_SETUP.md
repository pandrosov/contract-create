# Настройка SSL сертификатов

## Текущее состояние

На сервере настроены самоподписанные SSL сертификаты:
- Сертификат: `/opt/contract-manager/nginx/ssl/cert.pem`
- Ключ: `/opt/contract-manager/nginx/ssl/key.pem`

## Проблемы с самоподписанными сертификатами

1. **Браузеры показывают предупреждение безопасности**
2. **Некоторые API клиенты могут отказаться от подключения**
3. **Мобильные приложения могут не работать**

## Решения

### Вариант 1: Let's Encrypt (Рекомендуется)

```bash
# Установка certbot
apt update
apt install certbot python3-certbot-nginx

# Получение сертификата
certbot --nginx -d contract.alnilam.by -d www.contract.alnilam.by

# Автоматическое обновление
crontab -e
# Добавить строку:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

### Вариант 2: Коммерческий сертификат

1. Купить SSL сертификат у провайдера (например, Comodo, DigiCert)
2. Загрузить файлы на сервер
3. Обновить конфигурацию nginx

### Вариант 3: Временное решение

Для тестирования можно:
1. Добавить исключение в браузере
2. Использовать флаг `-k` в curl
3. Настроить доверие к сертификату в системе

## Проверка SSL

```bash
# Проверка сертификата
openssl x509 -in /opt/contract-manager/nginx/ssl/cert.pem -text -noout

# Проверка подключения
openssl s_client -connect contract.alnilam.by:443 -servername contract.alnilam.by

# Проверка через curl
curl -k https://contract.alnilam.by/api/health
```

## Обновление конфигурации

После получения нового сертификата:

1. Скопировать файлы в `/opt/contract-manager/nginx/ssl/`
2. Перезапустить nginx:
```bash
docker-compose -f docker-compose.prod.yaml restart nginx
```

## Мониторинг

```bash
# Проверка срока действия
openssl x509 -in /opt/contract-manager/nginx/ssl/cert.pem -noout -dates

# Проверка статуса nginx
docker-compose -f docker-compose.prod.yaml logs nginx
``` 