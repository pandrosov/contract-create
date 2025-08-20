#!/bin/bash

# Улучшенный скрипт деплоя с автоматической синхронизацией паролей
# Использование: ./scripts/deploy_with_sync.sh

set -e

echo "🚀 Запуск улучшенного деплоя с синхронизацией паролей..."

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для цветного вывода
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверяем наличие необходимых файлов
check_files() {
    log_info "Проверка необходимых файлов..."
    
    local required_files=(
        ".env"
        "docker-compose.prod.yaml"
        "scripts/sync_passwords.sh"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Файл $file не найден!"
            exit 1
        fi
    done
    
    log_success "Все необходимые файлы найдены"
}

# Синхронизируем пароли
sync_passwords() {
    log_info "Синхронизация паролей..."
    
    if ./scripts/sync_passwords.sh; then
        log_success "Пароли успешно синхронизированы"
    else
        log_error "Ошибка синхронизации паролей"
        exit 1
    fi
}

# Проверяем Git статус
check_git_status() {
    log_info "Проверка Git статуса..."
    
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "Обнаружены несохраненные изменения в Git"
        git status --short
        
        read -p "Продолжить деплой? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Деплой отменен пользователем"
            exit 0
        fi
    else
        log_success "Git репозиторий чист"
    fi
}

# Останавливаем контейнеры
stop_containers() {
    log_info "Остановка контейнеров..."
    
    if docker-compose -f docker-compose.prod.yaml down; then
        log_success "Контейнеры остановлены"
    else
        log_warning "Ошибка при остановке контейнеров (возможно, они уже остановлены)"
    fi
}

# Пересобираем контейнеры
rebuild_containers() {
    log_info "Пересборка контейнеров..."
    
    # Пересобираем backend с новыми исправлениями
    if docker-compose -f docker-compose.prod.yaml build backend; then
        log_success "Backend контейнер пересобран"
    else
        log_error "Ошибка при пересборке backend"
        exit 1
    fi
    
    # Пересобираем frontend
    if docker-compose -f docker-compose.prod.yaml build frontend; then
        log_success "Frontend контейнер пересобран"
    else
        log_error "Ошибка при пересборке frontend"
        exit 1
    fi
    
    # Пересобираем nginx
    if docker-compose -f docker-compose.prod.yaml build nginx; then
        log_success "Nginx контейнер пересобран"
    else
        log_error "Ошибка при пересборке nginx"
        exit 1
    fi
}

# Запускаем контейнеры
start_containers() {
    log_info "Запуск контейнеров..."
    
    if docker-compose -f docker-compose.prod.yaml up -d; then
        log_success "Контейнеры запущены"
    else
        log_error "Ошибка при запуске контейнеров"
        exit 1
    fi
}

# Проверяем здоровье приложения
health_check() {
    log_info "Проверка здоровья приложения..."
    
    # Ждем немного для запуска
    sleep 10
    
    # Проверяем backend
    if curl -s http://localhost:8000/health > /dev/null; then
        log_success "Backend работает"
    else
        log_error "Backend не отвечает"
        return 1
    fi
    
    # Проверяем frontend
    if curl -s http://localhost:3000 > /dev/null; then
        log_success "Frontend работает"
    else
        log_warning "Frontend не отвечает (возможно, еще запускается)"
    fi
    
    # Проверяем nginx
    if curl -s http://localhost > /dev/null; then
        log_success "Nginx работает"
    else
        log_warning "Nginx не отвечает (возможно, еще запускается)"
    fi
}

# Показываем статус контейнеров
show_status() {
    log_info "Статус контейнеров:"
    docker-compose -f docker-compose.prod.yaml ps
    
    log_info "Логи backend (последние 10 строк):"
    docker logs contract-backend --tail 10
}

# Основная функция
main() {
    log_info "🚀 Начинаем улучшенный деплой..."
    
    # Проверяем файлы
    check_files
    
    # Синхронизируем пароли
    sync_passwords
    
    # Проверяем Git статус
    check_git_status
    
    # Останавливаем контейнеры
    stop_containers
    
    # Пересобираем контейнеры
    rebuild_containers
    
    # Запускаем контейнеры
    start_containers
    
    # Проверяем здоровье
    if health_check; then
        log_success "🎉 Деплой завершен успешно!"
    else
        log_warning "⚠️ Деплой завершен с предупреждениями"
    fi
    
    # Показываем статус
    show_status
    
    log_info "💡 Приложение доступно по адресу: http://localhost"
    log_info "🔧 Backend API: http://localhost:8000"
    log_info "📱 Frontend: http://localhost:3000"
}

# Запускаем основную функцию
main "$@"
