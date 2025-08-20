#!/bin/bash

# Скрипт деплоя для contract.alnilam.by
# Использование: ./deploy.sh [production|staging]
#
# Логика деплоя:
# 1. Если есть Git репозиторий - используем Git (рекомендуется)
# 2. Если нет Git - fallback на scp с архивом
# 3. Автоматическая установка Docker, firewall, SSL

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Конфигурация
SERVER_IP="185.179.83.236"
SERVER_USER="root"
DOMAIN="contract.alnilam.by"
ENVIRONMENT=${1:-production}
SSH_KEY="~/.ssh/id_rsa_deploy"

echo -e "${GREEN}🚀 Начинаем деплой приложения на сервер ${SERVER_IP}${NC}"
echo -e "${YELLOW}Домен: ${DOMAIN}${NC}"
echo -e "${YELLOW}Окружение: ${ENVIRONMENT}${NC}"

# Проверяем подключение к серверу
echo -e "${YELLOW}Проверяем подключение к серверу...${NC}"
if ! ssh -i ${SSH_KEY} -o ConnectTimeout=10 -o BatchMode=yes ${SERVER_USER}@${SERVER_IP} exit 2>/dev/null; then
    echo -e "${RED}❌ Не удается подключиться к серверу ${SERVER_IP}${NC}"
    echo -e "${YELLOW}Убедитесь, что:${NC}"
    echo -e "   - Сервер доступен по IP ${SERVER_IP}"
    echo -e "   - SSH ключи настроены правильно"
    echo -e "   - Пользователь ${SERVER_USER} имеет доступ"
    exit 1
fi

echo -e "${GREEN}✅ Подключение к серверу успешно${NC}"

# Проверяем Git
echo -e "${YELLOW}Проверяем Git...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git не найден. Установите Git для деплоя${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Git готов к использованию${NC}"

# Создаем директории на сервере
echo -e "${YELLOW}Создаем структуру директорий на сервере...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
mkdir -p /opt/contract-app
mkdir -p /opt/contract-app/nginx/ssl
mkdir -p /opt/contract-app/nginx/logs
mkdir -p /opt/contract-app/logs
mkdir -p /opt/contract-app/backups
mkdir -p /opt/contract-app/templates
EOF

echo -e "${GREEN}✅ Директории созданы${NC}"

# Устанавливаем необходимые инструменты на сервере
echo -e "${YELLOW}Устанавливаем необходимые инструменты...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
apt update
if apt install -y curl wget git ufw iptables-persistent net-tools iproute2; then
    echo "Инструменты установлены"
else
    echo "Ошибка установки, пробуем без ufw..."
    apt install -y curl wget git net-tools iproute2
    echo "Базовые инструменты установлены"
fi
EOF

echo -e "${GREEN}✅ Инструменты установлены${NC}"

# Проверяем установку всех инструментов
echo -e "${YELLOW}Проверяем установку инструментов...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
echo "Проверяем наличие инструментов:"
for tool in curl wget git netstat ss iptables ufw; do
    if command -v $tool &> /dev/null; then
        echo "✅ $tool установлен"
    else
        echo "❌ $tool не найден"
    fi
done
EOF

echo -e "${GREEN}✅ Инструменты проверены${NC}"

# Клонируем/обновляем Git репозиторий на сервере
echo -e "${YELLOW}Настраиваем Git репозиторий на сервере...${NC}"

# Проверяем Git статус
if [ -d ".git" ]; then
    echo -e "${YELLOW}Проверяем Git статус...${NC}"
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "${YELLOW}⚠️  Есть незакоммиченные изменения:${NC}"
        git status --short
        echo -e "${YELLOW}Рекомендуется закоммитить изменения перед деплоем${NC}"
        read -p "Продолжить деплой? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Деплой отменен. Сначала закоммитьте изменения.${NC}"
            exit 0
        fi
    else
        echo -e "${GREEN}✅ Все изменения закоммичены${NC}"
    fi
    
    # Проверяем, что есть удаленный репозиторий
    if ! git remote get-url origin &> /dev/null; then
        echo -e "${RED}❌ Удаленный репозиторий не настроен${NC}"
        echo -e "${YELLOW}Добавьте remote origin: git remote add origin <url>${NC}"
        exit 1
    fi
    
    # Проверяем, что есть коммиты
    if ! git rev-parse HEAD &> /dev/null; then
        echo -e "${RED}❌ Нет коммитов в репозитории${NC}"
        echo -e "${YELLOW}Сделайте первый коммит: git add . && git commit -m 'Initial commit'${NC}"
        exit 1
    fi
    
    # Проверяем, что есть удаленная ветка
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "master")
    if ! git ls-remote --heads origin ${CURRENT_BRANCH} | grep -q ${CURRENT_BRANCH}; then
        echo -e "${YELLOW}⚠️  Ветка ${CURRENT_BRANCH} не существует в удаленном репозитории${NC}"
        echo -e "${YELLOW}Отправьте ветку: git push -u origin ${CURRENT_BRANCH}${NC}"
        read -p "Продолжить деплой? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Деплой отменен. Сначала отправьте ветку.${NC}"
            exit 0
        fi
    fi
    
    # Показываем информацию о репозитории
    echo -e "${GREEN}✅ Git репозиторий готов к деплою${NC}"
    echo -e "${BLUE}📊 Информация о репозитории:${NC}"
    echo -e "  Ветка: ${CURRENT_BRANCH}"
    echo -e "  Последний коммит: $(git log -1 --oneline)"
    echo -e "  Удаленный: $(git remote get-url origin)"
    
    # Проверяем, что ветка актуальна
    if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/${CURRENT_BRANCH} 2>/dev/null)" ]; then
        echo -e "${YELLOW}⚠️  Локальная ветка не синхронизирована с удаленной${NC}"
        echo -e "${YELLOW}Рекомендуется: git pull origin ${CURRENT_BRANCH}${NC}"
        read -p "Продолжить деплой? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Деплой отменен. Сначала синхронизируйте ветку.${NC}"
            exit 0
        fi
    fi
    
    # Проверяем, что есть теги
    if git tag | wc -l | grep -q "0"; then
        echo -e "${YELLOW}⚠️  Нет тегов в репозитории${NC}"
        echo -e "${YELLOW}Рекомендуется создать тег для версии${NC}"
    else
        echo -e "${GREEN}✅ Теги найдены: $(git tag | tail -3 | tr '\n' ' ')"
    fi
    
    # Показываем статистику репозитория
    echo -e "${BLUE}📈 Статистика репозитория:${NC}"
    echo -e "  Всего коммитов: $(git rev-list --count HEAD)"
    echo -e "  Размер: $(du -sh .git | cut -f1)"
    echo -e "  Последние изменения: $(git log --since="1 week ago" --oneline | wc -l | tr -d ' ') за неделю"
    
    # Показываем последние коммиты
    echo -e "${BLUE}📝 Последние коммиты:${NC}"
    git log --oneline -5
    
    # Показываем информацию о ветках
    echo -e "${BLUE}🌿 Ветки:${NC}"
    git branch -r | head -5
    
    # Показываем информацию о файлах
    echo -e "${BLUE}📁 Файлы в репозитории:${NC}"
    echo -e "  Всего файлов: $(git ls-files | wc -l | tr -d ' ')"
    echo -e "  Размер кода: $(git ls-files | xargs du -ch 2>/dev/null | tail -1 | cut -f1)"
    
    # Показываем информацию о конфигурации
    echo -e "${BLUE}⚙️  Конфигурация Git:${NC}"
    echo -e "  User: $(git config user.name 2>/dev/null || echo 'Не настроен')"
    echo -e "  Email: $(git config user.email 2>/dev/null || echo 'Не настроен')"
    echo -e "  Editor: $(git config core.editor 2>/dev/null || echo 'По умолчанию')"
    
    # Показываем информацию о последнем деплое
    echo -e "${BLUE}🚀 Последний деплой:${NC}"
    if [ -f ".deploy-info" ]; then
        echo -e "  $(cat .deploy-info)"
    else
        echo -e "  Информация о деплое не найдена"
    fi
fi

# Получаем URL текущего репозитория
GIT_REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

if [ -z "$GIT_REMOTE_URL" ]; then
    echo -e "${YELLOW}Git репозиторий не найден, используем прямое копирование...${NC}"
    # Fallback на scp если это не git репозиторий
    echo -e "${YELLOW}Создаем архив и копируем через scp...${NC}"
    tar -czf /tmp/app-backup.tar.gz --exclude='.git' --exclude='node_modules' --exclude='__pycache__' --exclude='.DS_Store' .
    scp -i ${SSH_KEY} /tmp/app-backup.tar.gz ${SERVER_USER}@${SERVER_IP}:/opt/contract-app/
    ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} "cd /opt/contract-app && tar -xzf app-backup.tar.gz && rm app-backup.tar.gz"
    rm /tmp/app-backup.tar.gz
    echo -e "${GREEN}✅ Файлы скопированы через scp${NC}"
else
    echo -e "${GREEN}✅ Git репозиторий найден: ${GIT_REMOTE_URL}${NC}"
    
    # Определяем текущую ветку
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "master")
    echo -e "${YELLOW}Текущая ветка: ${CURRENT_BRANCH}${NC}"
    
    # Клонируем/обновляем репозиторий на сервере
    ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << EOF
        cd /opt/contract-app
        
        if [ -d ".git" ]; then
            echo "Git репозиторий уже существует, обновляем..."
            git fetch origin
            git reset --hard origin/${CURRENT_BRANCH}
            git clean -fd
            echo "✅ Репозиторий обновлен до последней версии"
        else
            echo "Клонируем Git репозиторий..."
            rm -rf * .[^.]* 2>/dev/null || true
            git clone -b ${CURRENT_BRANCH} ${GIT_REMOTE_URL} .
            echo "✅ Репозиторий клонирован"
        fi
        
        # Устанавливаем правильные права
        chmod +x *.sh 2>/dev/null || true
        chmod +x app/*.sh 2>/dev/null || true
        chmod +x scripts/*.sh 2>/dev/null || true
EOF
    
    echo -e "${GREEN}✅ Git репозиторий настроен на сервере${NC}"
fi

echo -e "${GREEN}✅ Файлы приложения готовы${NC}"

# Создаем .env файл на сервере
echo -e "${YELLOW}Создаем файл переменных окружения...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << EOF
cat > /opt/contract-app/.env << 'ENVEOF'
# Database Configuration
POSTGRES_PASSWORD=secure_password_$(openssl rand -hex 16)
DATABASE_URL=postgresql://contract_user:secure_password_$(openssl rand -hex 16)@postgres:5432/contract_db

# Security
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS Settings
CORS_ORIGINS=https://${DOMAIN},https://www.${DOMAIN}

# Frontend API URL
REACT_APP_API_URL=https://${DOMAIN}/api

# Domain Configuration
DOMAIN=${DOMAIN}

# SSL Certificate Paths
SSL_CERT_PATH=/etc/nginx/ssl/fullchain.pem
SSL_KEY_PATH=/etc/nginx/ssl/privkey.pem

# Logging
LOG_LEVEL=INFO
LOG_FILE=/app/logs/app.log

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
BACKUP_PATH=/app/backups
ENVEOF
EOF

echo -e "${GREEN}✅ Файл .env создан${NC}"

# Устанавливаем Docker и Docker Compose на сервере
echo -e "${YELLOW}Проверяем и устанавливаем Docker...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
if ! command -v docker &> /dev/null; then
    echo "Устанавливаем Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $USER
    systemctl enable docker
    systemctl start docker
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Устанавливаем Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi
EOF

echo -e "${GREEN}✅ Docker установлен${NC}"

# Настраиваем firewall
echo -e "${YELLOW}Настраиваем firewall...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
# Устанавливаем ufw если его нет
if ! command -v ufw &> /dev/null; then
    echo "Устанавливаем ufw..."
    apt update
    apt install -y ufw
fi

# Пробуем настроить ufw
if command -v ufw &> /dev/null; then
    echo "Настраиваем ufw..."
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80
    ufw allow 443
    ufw allow 8000
    ufw --force reload
    echo "ufw настроен"
else
    echo "ufw не установлен, используем iptables..."
    # Альтернативная настройка через iptables
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    
    # Разрешаем localhost
    iptables -A INPUT -i lo -j ACCEPT
    
    # Разрешаем установленные соединения
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Разрешаем SSH
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # Разрешаем HTTP и HTTPS
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    # Разрешаем порт приложения
    iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
    
    # Блокируем все остальное
    iptables -A INPUT -j DROP
    
    # Разрешаем исходящие соединения
    iptables -A OUTPUT -j ACCEPT
    
    # Создаем директорию для правил если её нет
    mkdir -p /etc/iptables
    
    # Сохраняем правила
    iptables-save > /etc/iptables/rules.v4
    echo "iptables настроен"
fi

echo "Firewall настроен"
EOF

echo -e "${GREEN}✅ Firewall настроен${NC}"

# Проверяем статус firewall
echo -e "${YELLOW}Проверяем статус firewall...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
echo "Статус firewall:"
if command -v ufw &> /dev/null; then
    ufw status
else
    echo "iptables правила:"
    iptables -L -n
fi
EOF

echo -e "${GREEN}✅ Firewall проверен${NC}"

# Проверяем открытые порты
echo -e "${YELLOW}Проверяем открытые порты...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
echo "Проверяем основные порты:"
for port in 22 80 443 8000; do
    if netstat -tlnp 2>/dev/null | grep ":$port " > /dev/null; then
        echo "✅ Порт $port открыт"
    elif ss -tlnp 2>/dev/null | grep ":$port " > /dev/null; then
        echo "✅ Порт $port открыт (ss)"
    else
        echo "❌ Порт $port закрыт"
    fi
done
EOF

echo -e "${GREEN}✅ Порты проверены${NC}"

# Создаем SSL сертификаты (Let's Encrypt)
echo -e "${YELLOW}Настраиваем SSL сертификаты...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
# Устанавливаем certbot
apt update
apt install -y certbot

# Создаем временный nginx конфиг для получения сертификатов
cat > /opt/contract-app/nginx/nginx-temp.conf << 'NGINXEOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 80;
        server_name contract.alnilam.by www.contract.alnilam.by;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 301 https://$server_name$request_uri;
        }
    }
}
NGINXEOF

# Запускаем временный nginx для получения сертификатов
cd /opt/contract-app
docker-compose -f docker-compose.prod.yaml up -d nginx

# Получаем сертификаты
certbot certonly --webroot --webroot-path=/var/www/certbot \
    --email admin@${DOMAIN} --agree-tos --no-eff-email \
    -d ${DOMAIN} -d www.${DOMAIN}

# Останавливаем временный nginx
docker-compose -f docker-compose.prod.yaml down

# Копируем сертификаты
cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem /opt/contract-app/nginx/ssl/
cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem /opt/contract-app/nginx/ssl/

# Настраиваем автоматическое обновление сертификатов
echo "0 12 * * * /usr/bin/certbot renew --quiet && docker-compose -f /opt/contract-app/docker-compose.prod.yaml restart nginx" | crontab -
EOF

echo -e "${GREEN}✅ SSL сертификаты настроены${NC}"

# Запускаем приложение
echo -e "${YELLOW}Запускаем приложение...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
cd /opt/contract-app
docker-compose -f docker-compose.prod.yaml down
docker-compose -f docker-compose.prod.yaml up -d --build
EOF

echo -e "${GREEN}✅ Приложение запущено${NC}"

# Проверяем статус
echo -e "${YELLOW}Проверяем статус сервисов...${NC}"
ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
cd /opt/contract-app
docker-compose -f docker-compose.prod.yaml ps
EOF

echo -e "${GREEN}🎉 Деплой завершен успешно!${NC}"
echo -e "${YELLOW}Ваше приложение доступно по адресу: https://${DOMAIN}${NC}"
echo -e "${YELLOW}API доступен по адресу: https://${DOMAIN}/api${NC}"
echo -e "${YELLOW}Health check: https://${DOMAIN}/health${NC}"

# Показываем логи для отладки
echo -e "${YELLOW}Показываем последние логи...${NC}"
ssh ${SERVER_USER}@${SERVER_IP} << 'EOF'
cd /opt/contract-app
docker-compose -f docker-compose.prod.yaml logs --tail=20
EOF
