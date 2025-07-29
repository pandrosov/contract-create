# Настройка SSL сертификатов

## Текущий статус

✅ **Let's Encrypt сертификат установлен и работает**
- Домен: `contract.alnilam.by`
- Срок действия: до 27 октября 2025
- Автоматическое обновление: настроено

## Проверка SSL сертификата

### Проверка через браузер
Откройте https://contract.alnilam.by - теперь должен отображаться зеленый замок!

### Проверка через командную строку
```bash
# Проверка сертификата
openssl s_client -connect contract.alnilam.by:443 -servername contract.alnilam.by < /dev/null 2>/dev/null | openssl x509 -noout -subject -dates

# Проверка HTTP/HTTPS редиректа
curl -I http://contract.alnilam.by
curl -I https://contract.alnilam.by
```

## Автоматическое обновление

Сертификат обновляется автоматически:
- **Расписание**: каждый день в 2:00 утра
- **Скрипт**: `/opt/contract-manager/ssl_renew.sh`
- **Логи**: `/var/log/ssl_renew.log`

### Ручное обновление
```bash
ssh root@178.172.138.229
cd /opt/contract-manager
./ssl_renew.sh
```

## Структура файлов

```
/etc/letsencrypt/live/contract.alnilam.by/
├── fullchain.pem    # Полная цепочка сертификатов
├── privkey.pem      # Приватный ключ
└── cert.pem         # Основной сертификат

/opt/contract-manager/nginx/ssl/
├── fullchain.pem    # Копия для nginx
└── privkey.pem      # Копия для nginx
```

## Конфигурация nginx

SSL настройки в `/opt/contract-manager/nginx/nginx.conf`:
```nginx
ssl_certificate /etc/nginx/ssl/fullchain.pem;
ssl_certificate_key /etc/nginx/ssl/privkey.pem;
ssl_protocols TLSv1.2 TLSv1.3;
```

## Мониторинг

### Проверка статуса cron
```bash
ssh root@178.172.138.229 "crontab -l"
```

### Просмотр логов обновления
```bash
ssh root@178.172.138.229 "tail -f /var/log/ssl_renew.log"
```

### Проверка срока действия
```bash
ssh root@178.172.138.229 "certbot certificates"
```

## Устранение неполадок

### Если сертификат не обновляется
1. Проверьте логи: `tail -f /var/log/ssl_renew.log`
2. Проверьте cron: `crontab -l`
3. Запустите вручную: `./ssl_renew.sh`

### Если nginx не запускается
1. Проверьте права на файлы: `ls -la nginx/ssl/`
2. Проверьте конфигурацию: `docker-compose exec nginx nginx -t`
3. Перезапустите: `docker-compose restart nginx`

### Если домен не резолвится
```bash
nslookup contract.alnilam.by
dig contract.alnilam.by
```

## Безопасность

- ✅ HTTPS принудительно включен (HTTP → HTTPS редирект)
- ✅ HSTS заголовки настроены
- ✅ Современные SSL протоколы (TLS 1.2, 1.3)
- ✅ Автоматическое обновление сертификатов

## Тестирование

### Все endpoints должны работать через HTTPS:
- ✅ https://contract.alnilam.by (frontend)
- ✅ https://contract.alnilam.by/api/docs (API документация)
- ✅ https://contract.alnilam.by/api/health (health check)
- ✅ https://contract.alnilam.by/login (страница входа)

### Логин для тестирования:
- **Пользователь**: admin
- **Пароль**: admin 