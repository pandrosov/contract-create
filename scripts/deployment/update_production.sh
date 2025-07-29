#!/bin/bash

# Скрипт для безопасного обновления продакшена
# Использование: ./update_production.sh

set -e  # Остановка при ошибке

echo "🚀 Начинаем обновление продакшена..."
echo "=================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции для логирования
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка подключения к серверу
check_connection() {
    log_info "Проверка подключения к серверу..."
    if ! ssh -o ConnectTimeout=10 root@178.172.138.229 "echo 'Connection OK'" > /dev/null 2>&1; then
        log_error "Не удается подключиться к серверу"
        exit 1
    fi
    log_info "Подключение к серверу установлено"
}

# Проверка текущего состояния
check_current_state() {
    log_info "Проверка текущего состояния сервера..."
    
    # Проверка доступности сайта
    if curl -s -I https://contract.alnilam.by > /dev/null; then
        log_info "Сайт доступен"
    else
        log_warn "Сайт недоступен"
    fi
    
    # Проверка контейнеров
    CONTAINERS=$(ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml ps --format 'table {{.Name}}\t{{.Status}}'")
    log_info "Статус контейнеров:"
    echo "$CONTAINERS"
}

# Создание резервной копии
create_backup() {
    log_info "Создание резервной копии..."
    
    # Создание бэкапа кода
    ssh root@178.172.138.229 "cd /opt/contract-manager && git rev-parse HEAD > backup_commit.txt"
    
    # Создание бэкапа базы данных
    ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml exec -T postgres pg_dump -U contract_user contract_db > backup_db.sql"
    
    # Создание бэкапа файлов
    ssh root@178.172.138.229 "cd /opt/contract-manager && tar -czf backup_files_$(date +%Y%m%d_%H%M%S).tar.gz templates/ nginx/ssl/"
    
    log_info "Резервная копия создана"
}

# Обновление кода
update_code() {
    log_info "Обновление кода на сервере..."
    
    ssh root@178.172.138.229 "cd /opt/contract-manager && git fetch origin"
    ssh root@178.172.138.229 "cd /opt/contract-manager && git reset --hard origin/master"
    
    # Проверка обновления
    COMMIT_HASH=$(ssh root@178.172.138.229 "cd /opt/contract-manager && git rev-parse HEAD")
    log_info "Обновлен до коммита: $COMMIT_HASH"
}

# Проверка новой структуры
check_structure() {
    log_info "Проверка новой структуры файлов..."
    
    # Проверка ключевых файлов
    ssh root@178.172.138.229 "cd /opt/contract-manager && ls -la app/main.py app/auth.py app/db.py"
    
    # Проверка новых папок
    ssh root@178.172.138.229 "cd /opt/contract-manager && ls -la scripts/ docs/"
    
    log_info "Структура файлов проверена"
}

# Обновление контейнеров
update_containers() {
    log_info "Обновление контейнеров..."
    
    # Остановка сервисов
    log_info "Остановка сервисов..."
    ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml down"
    
    # Пересборка
    log_info "Пересборка контейнеров..."
    ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml build --no-cache"
    
    # Запуск сервисов
    log_info "Запуск сервисов..."
    ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml up -d"
    
    # Ожидание запуска
    log_info "Ожидание запуска сервисов (30 секунд)..."
    sleep 30
}

# Проверка работоспособности
check_health() {
    log_info "Проверка работоспособности..."
    
    # Проверка контейнеров
    CONTAINERS=$(ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml ps")
    log_info "Статус контейнеров после обновления:"
    echo "$CONTAINERS"
    
    # Проверка логов бэкенда
    log_info "Проверка логов бэкенда..."
    ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml logs backend --tail=10"
    
    # Проверка health check
    if curl -s https://contract.alnilam.by/api/health > /dev/null; then
        log_info "Health check отвечает"
    else
        log_error "Health check не отвечает"
        return 1
    fi
    
    # Проверка основного сайта
    if curl -s -I https://contract.alnilam.by > /dev/null; then
        log_info "Основной сайт доступен"
    else
        log_error "Основной сайт недоступен"
        return 1
    fi
}

# Тестирование функциональности
test_functionality() {
    log_info "Тестирование функциональности..."
    
    # Тест API документации
    if curl -s -I https://contract.alnilam.by/api/docs > /dev/null; then
        log_info "API документация доступна"
    else
        log_warn "API документация недоступна"
    fi
    
    # Тест SSL сертификата
    if openssl s_client -connect contract.alnilam.by:443 -servername contract.alnilam.by < /dev/null > /dev/null 2>&1; then
        log_info "SSL сертификат работает"
    else
        log_warn "Проблемы с SSL сертификатом"
    fi
    
    log_info "Тестирование завершено"
}

# Откат в случае проблем
rollback() {
    log_error "Выполняется откат..."
    
    # Восстановление предыдущего коммита
    ssh root@178.172.138.229 "cd /opt/contract-manager && git reset --hard HEAD~1"
    
    # Перезапуск контейнеров
    ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml down"
    ssh root@178.172.138.229 "cd /opt/contract-manager && docker-compose -f docker-compose.prod.yaml up -d"
    
    log_info "Откат завершен"
}

# Основная функция
main() {
    echo "=================================="
    echo "🔄 Обновление продакшена"
    echo "=================================="
    
    # Проверка подключения
    check_connection
    
    # Проверка текущего состояния
    check_current_state
    
    # Создание резервной копии
    create_backup
    
    # Обновление кода
    update_code
    
    # Проверка структуры
    check_structure
    
    # Обновление контейнеров
    update_containers
    
    # Проверка работоспособности
    if ! check_health; then
        log_error "Проблемы с работоспособностью, выполняем откат"
        rollback
        exit 1
    fi
    
    # Тестирование функциональности
    test_functionality
    
    echo "=================================="
    echo "✅ Обновление продакшена завершено успешно!"
    echo "=================================="
}

# Запуск основной функции
main "$@" 