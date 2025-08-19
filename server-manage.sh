#!/bin/bash

# Скрипт управления приложением на сервере
# Использование: ./server-manage.sh [start|stop|restart|logs|status|update|backup]

set -e

# Конфигурация
SERVER_IP="185.179.83.236"
SERVER_USER="root"
APP_PATH="/opt/contract-app"
SSH_KEY="~/.ssh/id_rsa_deploy"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для выполнения команд на сервере
run_on_server() {
    ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} "$1"
}

# Функция для показа справки
show_help() {
    echo -e "${BLUE}Использование: $0 [команда]${NC}"
    echo ""
    echo "Доступные команды:"
    echo "  start     - Запустить приложение"
    echo "  stop      - Остановить приложение"
    echo "  restart   - Перезапустить приложение"
    echo "  status    - Показать статус сервисов"
    echo "  logs      - Показать логи приложения"
    echo "  update    - Обновить приложение с Git"
    echo "  deploy    - Деплой конкретной ветки/тега"
    echo "  backup    - Создать резервную копию базы данных"
    echo "  ssl       - Обновить SSL сертификаты"
    echo "  shell     - Открыть shell на сервере"
    echo "  help      - Показать эту справку"
}

# Функция для запуска приложения
start_app() {
    echo -e "${YELLOW}🚀 Запускаем приложение...${NC}"
    run_on_server "cd ${APP_PATH} && docker-compose -f docker-compose.prod.yaml up -d"
    echo -e "${GREEN}✅ Приложение запущено${NC}"
}

# Функция для остановки приложения
stop_app() {
    echo -e "${YELLOW}🛑 Останавливаем приложение...${NC}"
    run_on_server "cd ${APP_PATH} && docker-compose -f docker-compose.prod.yaml down"
    echo -e "${GREEN}✅ Приложение остановлено${NC}"
}

# Функция для перезапуска приложения
restart_app() {
    echo -e "${YELLOW}🔄 Перезапускаем приложение...${NC}"
    run_on_server "cd ${APP_PATH} && docker-compose -f docker-compose.prod.yaml restart"
    echo -e "${GREEN}✅ Приложение перезапущено${NC}"
}

# Функция для показа статуса
show_status() {
    echo -e "${YELLOW}📊 Статус сервисов:${NC}"
    run_on_server "cd ${APP_PATH} && docker-compose -f docker-compose.prod.yaml ps"
    
    echo -e "\n${YELLOW}📈 Использование ресурсов:${NC}"
    run_on_server "docker stats --no-stream --format 'table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'"
    
    echo -e "\n${YELLOW}🌿 Git статус:${NC}"
    run_on_server "cd ${APP_PATH} && git status --short && echo '---' && git log --oneline -5"
}

# Функция для показа логов
show_logs() {
    echo -e "${YELLOW}📝 Логи приложения (последние 50 строк):${NC}"
    run_on_server "cd ${APP_PATH} && docker-compose -f docker-compose.prod.yaml logs --tail=50"
}

# Функция для обновления приложения
update_app() {
    echo -e "${YELLOW}🔄 Обновляем приложение...${NC}"
    
    # Останавливаем приложение
    stop_app
    
    # Получаем текущую ветку
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "master")
    echo -e "${YELLOW}Обновляем ветку: ${CURRENT_BRANCH}${NC}"
    
    # Обновляем код с Git
    run_on_server "cd ${APP_PATH} && git fetch origin && git reset --hard origin/${CURRENT_BRANCH} && git clean -fd"
    
    # Пересобираем и запускаем
    run_on_server "cd ${APP_PATH} && docker-compose -f docker-compose.prod.yaml up -d --build"
    
    echo -e "${GREEN}✅ Приложение обновлено до последней версии${NC}"
}

# Функция для деплоя конкретной ветки/тега
deploy_branch() {
    if [ -z "$1" ]; then
        echo -e "${RED}❌ Укажите ветку или тег для деплоя${NC}"
        echo "Использование: $0 deploy <branch|tag>"
        exit 1
    fi
    
    BRANCH_OR_TAG="$1"
    echo -e "${YELLOW}🚀 Деплой ветки/тега: ${BRANCH_OR_TAG}${NC}"
    
    # Останавливаем приложение
    stop_app
    
    # Деплоим конкретную ветку/тег
    run_on_server "cd ${APP_PATH} && git fetch origin && git checkout ${BRANCH_OR_TAG} && git reset --hard origin/${BRANCH_OR_TAG} && git clean -fd"
    
    # Пересобираем и запускаем
    run_on_server "cd ${APP_PATH} && docker-compose -f docker-compose.prod.yaml up -d --build"
    
    echo -e "${GREEN}✅ Приложение развернуто с ветки/тега: ${BRANCH_OR_TAG}${NC}"
}

# Функция для создания резервной копии
create_backup() {
    echo -e "${YELLOW}💾 Создаем резервную копию базы данных...${NC}"
    
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    run_on_server "cd ${APP_PATH} && docker-compose -f docker-compose.prod.yaml exec -T postgres pg_dump -U contract_user contract_db > backups/${BACKUP_FILE}"
    
    echo -e "${GREEN}✅ Резервная копия создана: ${BACKUP_FILE}${NC}"
}

# Функция для обновления SSL сертификатов
update_ssl() {
    echo -e "${YELLOW}🔒 Обновляем SSL сертификаты...${NC}"
    
    run_on_server "certbot renew --quiet"
    run_on_server "cp /etc/letsencrypt/live/contract.alnilam.by/fullchain.pem ${APP_PATH}/nginx/ssl/"
    run_on_server "cp /etc/letsencrypt/live/contract.alnilam.by/privkey.pem ${APP_PATH}/nginx/ssl/"
    run_on_server "cd ${APP_PATH} && docker-compose -f docker-compose.prod.yaml restart nginx"
    
    echo -e "${GREEN}✅ SSL сертификаты обновлены${NC}"
}

# Функция для открытия shell на сервере
open_shell() {
    echo -e "${YELLOW}🐚 Открываем shell на сервере...${NC}"
    echo -e "${BLUE}Для выхода используйте команду 'exit'${NC}"
    ssh ${SERVER_USER}@${SERVER_IP}
}

# Основная логика
case "${1:-help}" in
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    restart)
        restart_app
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    update)
        update_app
        ;;
    deploy)
        deploy_branch "$2"
        ;;
    backup)
        create_backup
        ;;
    ssl)
        update_ssl
        ;;
    shell)
        open_shell
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Неизвестная команда: $1${NC}"
        show_help
        exit 1
        ;;
esac
