FROM nginx:alpine

# Устанавливаем необходимые инструменты
RUN apk add --no-cache bash curl

# Копируем конфигурацию Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Создаем директории
RUN mkdir -p /etc/nginx/ssl /var/log/nginx

# Копируем скрипт инициализации
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Устанавливаем правильные права
RUN chown -R nginx:nginx /var/log/nginx /etc/nginx/ssl

EXPOSE 80 443

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
