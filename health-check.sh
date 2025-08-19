#!/bin/bash

# Скрипт проверки здоровья приложения
# Использование: ./health-check.sh

set -e

# Конфигурация
SERVER_IP="185.179.83.236"
SERVER_USER="root"
DOMAIN="contract.alnilam.by"
SSH_KEY="~/.ssh/id_rsa_deploy"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏥 Проверка здоровья приложения${NC}"
echo -e "${YELLOW}Сервер: ${SERVER_IP}${NC}"
echo -e "${YELLOW}Домен: ${DOMAIN}${NC}"
echo ""

# Функция для проверки подключения к серверу
check_ssh_connection() {
    echo -e "${YELLOW}🔌 Проверка SSH подключения...${NC}"
    if ssh -i ${SSH_KEY} -o ConnectTimeout=10 -o BatchMode=yes ${SERVER_USER}@${SERVER_IP} exit 2>/dev/null; then
        echo -e "${GREEN}✅ SSH подключение работает${NC}"
        return 0
    else
        echo -e "${RED}❌ SSH подключение не работает${NC}"
        return 1
    fi
}

# Функция для проверки Docker сервисов
check_docker_services() {
    echo -e "${YELLOW}🐳 Проверка Docker сервисов...${NC}"
    
    if ! check_ssh_connection; then
        return 1
    fi
    
    ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
        cd /opt/contract-app
        if [ -f "docker-compose.prod.yaml" ]; then
            echo "Статус сервисов:"
            docker-compose -f docker-compose.prod.yaml ps
            echo ""
            echo "Использование ресурсов:"
            docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'
        else
            echo "Docker Compose файл не найден"
        fi
EOF
}

# Функция для проверки доступности веб-сервисов
check_web_services() {
    echo -e "${YELLOW}🌐 Проверка веб-сервисов...${NC}"
    
    # Проверка HTTP (должен редиректить на HTTPS)
    echo -e "${YELLOW}  HTTP (порт 80)...${NC}"
    if curl -s -o /dev/null -w "%{http_code}" "http://${DOMAIN}" | grep -q "301\|302"; then
        echo -e "${GREEN}  ✅ HTTP редирект работает${NC}"
    else
        echo -e "${RED}  ❌ HTTP редирект не работает${NC}"
    fi
    
    # Проверка HTTPS
    echo -e "${YELLOW}  HTTPS (порт 443)...${NC}"
    if curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}" | grep -q "200"; then
        echo -e "${GREEN}  ✅ HTTPS работает${NC}"
    else
        echo -e "${RED}  ❌ HTTPS не работает${NC}"
    fi
    
    # Проверка API
    echo -e "${YELLOW}  API endpoint...${NC}"
    if curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}/api" | grep -q "200\|401\|404"; then
        echo -e "${GREEN}  ✅ API отвечает${NC}"
    else
        echo -e "${RED}  ❌ API не отвечает${NC}"
    fi
    
    # Проверка Health Check
    echo -e "${YELLOW}  Health Check...${NC}"
    if curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}/health" | grep -q "200"; then
        echo -e "${GREEN}  ✅ Health Check работает${NC}"
    else
        echo -e "${RED}  ❌ Health Check не работает${NC}"
    fi
}

# Функция для проверки SSL сертификатов
check_ssl_certificates() {
    echo -e "${YELLOW}🔒 Проверка SSL сертификатов...${NC}"
    
    # Проверка срока действия сертификата
    CERT_EXPIRY=$(echo | openssl s_client -servername ${DOMAIN} -connect ${DOMAIN}:443 2>/dev/null | openssl x509 -noout -dates | grep "notAfter")
    
    if [ ! -z "$CERT_EXPIRY" ]; then
        echo -e "${GREEN}  ✅ SSL сертификат найден${NC}"
        echo -e "${BLUE}  📅 $CERT_EXPIRY${NC}"
        
        # Проверяем, не истекает ли сертификат в ближайшие 30 дней
        EXPIRY_DATE=$(echo "$CERT_EXPIRY" | sed 's/notAfter=//')
        EXPIRY_EPOCH=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$EXPIRY_DATE" +%s 2>/dev/null || date -d "$EXPIRY_DATE" +%s 2>/dev/null)
        CURRENT_EPOCH=$(date +%s)
        DAYS_LEFT=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))
        
        if [ $DAYS_LEFT -gt 30 ]; then
            echo -e "${GREEN}  ✅ Сертификат действителен еще $DAYS_LEFT дней${NC}"
        elif [ $DAYS_LEFT -gt 7 ]; then
            echo -e "${YELLOW}  ⚠️ Сертификат истекает через $DAYS_LEFT дней${NC}"
        else
            echo -e "${RED}  ❌ Сертификат истекает через $DAYS_LEFT дней!${NC}"
        fi
    else
        echo -e "${RED}  ❌ SSL сертификат не найден${NC}"
    fi
}

# Функция для проверки портов
check_ports() {
    echo -e "${YELLOW}🔍 Проверка открытых портов...${NC}"
    
    # Проверка основных портов
    for port in 22 80 443 8000; do
        if nc -z -w5 ${SERVER_IP} ${port} 2>/dev/null; then
            echo -e "${GREEN}  ✅ Порт ${port} открыт${NC}"
        else
            echo -e "${RED}  ❌ Порт ${port} закрыт${NC}"
        fi
    done
}

# Функция для проверки дискового пространства
check_disk_space() {
    echo -e "${YELLOW}💾 Проверка дискового пространства...${NC}"
    
    if check_ssh_connection; then
        ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
            echo "Использование диска:"
            df -h | grep -E '^/dev/'
            echo ""
            echo "Использование Docker:"
            docker system df
EOF
    fi
}

# Функция для проверки логов на ошибки
check_logs() {
    echo -e "${YELLOW}📝 Проверка логов на ошибки...${NC}"
    
    if check_ssh_connection; then
        ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
            cd /opt/contract-app
            echo "Последние ошибки в логах:"
            docker-compose -f docker-compose.prod.yaml logs --tail=50 | grep -i "error\|exception\|fail" | tail -10 || echo "Ошибок не найдено"
EOF
    fi
}

# Основная функция проверки
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}    ПРОВЕРКА ЗДОРОВЬЯ СИСТЕМЫ    ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    
    # Выполняем все проверки
    check_ssh_connection
    echo ""
    
    check_ports
    echo ""
    
    check_web_services
    echo ""
    
    check_ssl_certificates
    echo ""
    
    check_docker_services
    echo ""
    
    check_disk_space
    echo ""
    
    check_logs
    echo ""
    
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}      ПРОВЕРКА ЗАВЕРШЕНА        ${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Запуск основной функции
main
