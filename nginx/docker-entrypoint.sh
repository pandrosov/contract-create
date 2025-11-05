#!/bin/bash

echo "🚀 Инициализация Nginx контейнера..."

# Ждем, пока хост-система будет готова
sleep 5

# Проверяем, есть ли SSL сертификаты на хосте
if [ -f "/etc/letsencrypt/live/contract.alnilam.by/fullchain.pem" ]; then
    echo "✅ SSL сертификаты найдены на хосте, копируем их..."
    
    # Копируем сертификаты
    cp /etc/letsencrypt/live/contract.alnilam.by/fullchain.pem /etc/nginx/ssl/
    cp /etc/letsencrypt/live/contract.alnilam.by/privkey.pem /etc/nginx/ssl/
    
    # Устанавливаем правильные права
    chmod 644 /etc/nginx/ssl/fullchain.pem
    chmod 600 /etc/nginx/ssl/privkey.pem
    
    echo "✅ SSL сертификаты скопированы и настроены"
else
    echo "⚠️ SSL сертификаты не найдены, запускаем без SSL..."
    
    # Создаем временную конфигурацию без SSL
    cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    server {
        listen 80;
        server_name contract.alnilam.by www.contract.alnilam.by;
        
        root /usr/share/nginx/html;
        index index.html;
        
        # Upstream for backend
        upstream backend {
            server backend:8000;
        }
        
        # Upstream for frontend
        upstream frontend {
            server frontend:80;
        }
        
        # API routes
        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Увеличиваем таймауты для длительных операций (генерация актов)
            proxy_connect_timeout 600s;
            proxy_send_timeout 600s;
            proxy_read_timeout 600s;
            send_timeout 600s;
        }
        
        # Health check endpoint
        location /health {
            proxy_pass http://backend/health;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Frontend static files
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
    
    echo "✅ Временная конфигурация без SSL создана"
fi

# Проверяем конфигурацию nginx перед запуском
echo "🔍 Проверяем конфигурацию nginx..."
nginx -t
if [ $? -ne 0 ]; then
    echo "❌ Ошибка в конфигурации nginx!"
    exit 1
fi

echo "🚀 Запускаем Nginx..."
exec "$@"
