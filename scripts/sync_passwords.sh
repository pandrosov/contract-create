#!/bin/bash

# Скрипт для синхронизации паролей между .env и docker-compose.prod.yaml
# Использование: ./scripts/sync_passwords.sh

set -e

echo "🔐 Синхронизация паролей..."

# Проверяем наличие .env файла
if [ ! -f ".env" ]; then
    echo "❌ Файл .env не найден!"
    exit 1
fi

# Проверяем наличие docker-compose.prod.yaml
if [ ! -f "docker-compose.prod.yaml" ]; then
    echo "❌ Файл docker-compose.prod.yaml не найден!"
    exit 1
fi

# Создаем резервную копию docker-compose.prod.yaml
cp docker-compose.prod.yaml docker-compose.prod.yaml.backup
echo "✅ Создана резервная копия docker-compose.prod.yaml"

# Функция для обновления пароля в docker-compose файле
update_password_in_compose() {
    local env_file=".env"
    local compose_file="docker-compose.prod.yaml"
    
    # Извлекаем POSTGRES_PASSWORD из .env
    if grep -q "^POSTGRES_PASSWORD=" "$env_file"; then
        POSTGRES_PASSWORD=$(grep "^POSTGRES_PASSWORD=" "$env_file" | cut -d'=' -f2)
        echo "📝 Найден POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:0:10}..."
        
        # Обновляем POSTGRES_PASSWORD в docker-compose.prod.yaml (macOS совместимость)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-.*}/POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-$POSTGRES_PASSWORD}/" "$compose_file"
            sed -i '' "s|DATABASE_URL=postgresql://contract_user:\${POSTGRES_PASSWORD:-.*}@postgres:5432/contract_db|DATABASE_URL=postgresql://contract_user:\${POSTGRES_PASSWORD:-$POSTGRES_PASSWORD}@postgres:5432/contract_db|" "$compose_file"
        else
            # Linux
            sed -i "s/POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-.*}/POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-$POSTGRES_PASSWORD}/" "$compose_file"
            sed -i "s|DATABASE_URL=postgresql://contract_user:\${POSTGRES_PASSWORD:-.*}@postgres:5432/contract_db|DATABASE_URL=postgresql://contract_user:\${POSTGRES_PASSWORD:-$POSTGRES_PASSWORD}@postgres:5432/contract_db|" "$compose_file"
        fi
        
        echo "✅ Пароли синхронизированы в docker-compose.prod.yaml"
    else
        echo "⚠️ POSTGRES_PASSWORD не найден в .env файле"
    fi
}

# Функция для проверки синхронизации
check_sync() {
    local env_file=".env"
    local compose_file="docker-compose.prod.yaml"
    
    echo "🔍 Проверка синхронизации..."
    
    # Извлекаем пароли
    ENV_PASSWORD=$(grep "^POSTGRES_PASSWORD=" "$env_file" | cut -d'=' -f2)
    COMPOSE_PASSWORD=$(grep "POSTGRES_PASSWORD:" "$compose_file" | head -1 | sed 's/.*POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-\([^}]*\)}/\1/')
    
    if [ "$ENV_PASSWORD" = "$COMPOSE_PASSWORD" ]; then
        echo "✅ Пароли синхронизированы: ${ENV_PASSWORD:0:10}..."
    else
        echo "❌ Пароли не синхронизированы!"
        echo "   .env: ${ENV_PASSWORD:0:10}..."
        echo "   docker-compose: ${COMPOSE_PASSWORD:0:10}..."
        return 1
    fi
}

# Основная логика
echo "🚀 Начинаем синхронизацию паролей..."

# Обновляем пароли
update_password_in_compose

# Проверяем результат
if check_sync; then
    echo "🎉 Синхронизация паролей завершена успешно!"
    echo "💡 Теперь можно безопасно деплоить приложение"
else
    echo "❌ Ошибка синхронизации паролей!"
    echo "🔄 Восстанавливаем резервную копию..."
    cp docker-compose.prod.yaml.backup docker-compose.prod.yaml
    exit 1
fi

# Удаляем резервную копию
rm -f docker-compose.prod.yaml.backup
echo "🧹 Резервная копия удалена"
