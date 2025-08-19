#!/bin/bash

# Скрипт автоматического создания резервных копий
# Использование: ./backup.sh [full|db|files]

set -e

# Конфигурация
SERVER_IP="185.179.83.236"
SERVER_USER="root"
APP_PATH="/opt/contract-app"
BACKUP_DIR="./backups"
RETENTION_DAYS=30
SSH_KEY="~/.ssh/id_rsa_deploy"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Создаем локальную директорию для бэкапов
mkdir -p ${BACKUP_DIR}

# Функция для создания резервной копии базы данных
backup_database() {
    echo -e "${YELLOW}💾 Создание резервной копии базы данных...${NC}"
    
    BACKUP_FILE="db_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << EOF
        cd ${APP_PATH}
        docker-compose -f docker-compose.prod.yaml exec -T postgres pg_dump -U contract_user contract_db > backups/${BACKUP_FILE}
        echo "Резервная копия БД создана: ${BACKUP_FILE}"
EOF
    
    # Скачиваем бэкап на локальную машину
    scp -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP}:${APP_PATH}/backups/${BACKUP_FILE} ${BACKUP_DIR}/
    
    echo -e "${GREEN}✅ Резервная копия БД сохранена: ${BACKUP_DIR}/${BACKUP_FILE}${NC}"
}

# Функция для создания резервной копии файлов
backup_files() {
    echo -e "${YELLOW}📁 Создание резервной копии файлов...${NC}"
    
    BACKUP_FILE="files_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << EOF
        cd ${APP_PATH}
        tar -czf backups/${BACKUP_FILE} \
            --exclude='node_modules' \
            --exclude='__pycache__' \
            --exclude='.git' \
            --exclude='backups' \
            --exclude='logs' \
            .
        echo "Резервная копия файлов создана: ${BACKUP_FILE}"
EOF
    
    # Скачиваем бэкап на локальную машину
    scp -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP}:${APP_PATH}/backups/${BACKUP_FILE} ${BACKUP_DIR}/
    
    echo -e "${GREEN}✅ Резервная копия файлов сохранена: ${BACKUP_DIR}/${BACKUP_FILE}${NC}"
}

# Функция для создания полной резервной копии
backup_full() {
    echo -e "${YELLOW}🔄 Создание полной резервной копии...${NC}"
    
    backup_database
    backup_files
    
    # Создаем метафайл с информацией о бэкапе
    META_FILE="backup_meta_$(date +%Y%m%d_%H%M%S).json"
    cat > ${BACKUP_DIR}/${META_FILE} << EOF
{
    "backup_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "backup_type": "full",
    "server_ip": "${SERVER_IP}",
    "app_path": "${APP_PATH}",
    "components": ["database", "files"],
    "retention_days": ${RETENTION_DAYS}
}
EOF
    
    echo -e "${GREEN}✅ Полная резервная копия создана${NC}"
}

# Функция для очистки старых бэкапов
cleanup_old_backups() {
    echo -e "${YELLOW}🧹 Очистка старых резервных копий...${NC}"
    
    # Очистка локальных бэкапов
    find ${BACKUP_DIR} -name "*.sql" -mtime +${RETENTION_DAYS} -delete
    find ${BACKUP_DIR} -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete
    find ${BACKUP_DIR} -name "*.json" -mtime +${RETENTION_DAYS} -delete
    
    # Очистка бэкапов на сервере
    ssh ${SERVER_USER}@${SERVER_IP} << EOF
        cd ${APP_PATH}/backups
        find . -name "*.sql" -mtime +${RETENTION_DAYS} -delete
        find . -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete
        echo "Старые резервные копии удалены"
EOF
    
    echo -e "${GREEN}✅ Очистка завершена${NC}"
}

# Функция для показа информации о бэкапах
show_backup_info() {
    echo -e "${BLUE}📊 Информация о резервных копиях:${NC}"
    echo ""
    
    echo -e "${YELLOW}Локальные резервные копии:${NC}"
    if [ -z "$(ls -A ${BACKUP_DIR})" ]; then
        echo "  Нет резервных копий"
    else
        ls -lh ${BACKUP_DIR}/
    fi
    
    echo ""
    echo -e "${YELLOW}Резервные копии на сервере:${NC}"
    ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << 'EOF'
        cd /opt/contract-app/backups
        if [ -z "$(ls -A .)" ]; then
            echo "  Нет резервных копий"
        else
            ls -lh
        fi
EOF
    
    echo ""
    echo -e "${YELLOW}Использование диска:${NC}"
    du -sh ${BACKUP_DIR}
}

# Функция для восстановления из резервной копии
restore_backup() {
    if [ -z "$1" ]; then
        echo -e "${RED}❌ Укажите файл резервной копии для восстановления${NC}"
        echo "Использование: $0 restore <backup_file>"
        exit 1
    fi
    
    BACKUP_FILE="$1"
    
    if [ ! -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
        echo -e "${RED}❌ Файл резервной копии не найден: ${BACKUP_FILE}${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}🔄 Восстановление из резервной копии: ${BACKUP_FILE}${NC}"
    echo -e "${RED}⚠️  ВНИМАНИЕ: Это действие перезапишет текущие данные!${NC}"
    read -p "Продолжить? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$BACKUP_FILE" == *"db_backup"* ]]; then
            echo -e "${YELLOW}Восстанавливаем базу данных...${NC}"
            scp -i ${SSH_KEY} "${BACKUP_DIR}/${BACKUP_FILE}" ${SERVER_USER}@${SERVER_IP}:${APP_PATH}/backups/
            ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << EOF
                cd ${APP_PATH}
                docker-compose -f docker-compose.prod.yaml exec -T postgres psql -U contract_user -d contract_db < backups/${BACKUP_FILE}
EOF
            echo -e "${GREEN}✅ База данных восстановлена${NC}"
        elif [[ "$BACKUP_FILE" == *"files_backup"* ]]; then
            echo -e "${YELLOW}Восстанавливаем файлы...${NC}"
            scp -i ${SSH_KEY} "${BACKUP_DIR}/${BACKUP_FILE}" ${SERVER_USER}@${SERVER_IP}:${APP_PATH}/backups/
            ssh -i ${SSH_KEY} ${SERVER_USER}@${SERVER_IP} << EOF
                cd ${APP_PATH}
                tar -xzf backups/${BACKUP_FILE}
                docker-compose -f docker-compose.prod.yaml restart
EOF
            echo -e "${GREEN}✅ Файлы восстановлены${NC}"
        else
            echo -e "${RED}❌ Неизвестный тип резервной копии${NC}"
        fi
    else
        echo -e "${YELLOW}Восстановление отменено${NC}"
    fi
}

# Основная логика
case "${1:-full}" in
    db)
        backup_database
        ;;
    files)
        backup_files
        ;;
    full)
        backup_full
        ;;
    cleanup)
        cleanup_old_backups
        ;;
    info)
        show_backup_info
        ;;
    restore)
        restore_backup "$2"
        ;;
    help|--help|-h)
        echo -e "${BLUE}Использование: $0 [команда]${NC}"
        echo ""
        echo "Доступные команды:"
        echo "  full      - Полная резервная копия (по умолчанию)"
        echo "  db        - Только база данных"
        echo "  files     - Только файлы"
        echo "  cleanup   - Очистка старых бэкапов"
        echo "  info      - Информация о бэкапах"
        echo "  restore   - Восстановление из бэкапа"
        echo "  help      - Эта справка"
        ;;
    *)
        echo -e "${RED}❌ Неизвестная команда: $1${NC}"
        echo "Используйте '$0 help' для справки"
        exit 1
        ;;
esac

# Автоматическая очистка после создания бэкапа
if [[ "$1" =~ ^(full|db|files)$ ]]; then
    cleanup_old_backups
fi

echo -e "${GREEN}🎉 Операция завершена успешно!${NC}"
