-- Инициализация базы данных PostgreSQL для приложения Contract
-- Этот файл создает все необходимые таблицы и начальные данные

-- Создание таблицы пользователей
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR UNIQUE NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    password_hash VARCHAR NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    is_admin BOOLEAN DEFAULT FALSE,
    date_joined TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание таблицы папок
CREATE TABLE IF NOT EXISTS folders (
    id SERIAL PRIMARY KEY,
    name VARCHAR NOT NULL,
    parent_id INTEGER REFERENCES folders(id),
    path VARCHAR UNIQUE NOT NULL,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание таблицы шаблонов
CREATE TABLE IF NOT EXISTS templates (
    id SERIAL PRIMARY KEY,
    filename VARCHAR NOT NULL,
    folder_id INTEGER REFERENCES folders(id),
    uploaded_by INTEGER REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание таблицы разрешений
CREATE TABLE IF NOT EXISTS permissions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    folder_id INTEGER REFERENCES folders(id),
    level VARCHAR NOT NULL, -- view, upload, delete, manage
    UNIQUE(user_id, folder_id)
);

-- Создание таблицы логов действий
CREATE TABLE IF NOT EXISTS action_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR NOT NULL, -- download, upload, delete, manage, login, etc.
    target_type VARCHAR NOT NULL, -- folder, template, user
    target_id INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

-- Создание таблицы настроек
CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY,
    key VARCHAR UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание таблицы описаний плейсхолдеров
CREATE TABLE IF NOT EXISTS placeholder_descriptions (
    id SERIAL PRIMARY KEY,
    name VARCHAR UNIQUE NOT NULL,
    description TEXT NOT NULL,
    example_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Создание индексов для улучшения производительности
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_folders_path ON folders(path);
CREATE INDEX IF NOT EXISTS idx_templates_folder_id ON templates(folder_id);
CREATE INDEX IF NOT EXISTS idx_permissions_user_folder ON permissions(user_id, folder_id);
CREATE INDEX IF NOT EXISTS idx_action_logs_user_id ON action_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_action_logs_timestamp ON action_logs(timestamp);

-- Вставка начальных данных

-- Создание администратора (пароль: admin)
INSERT INTO users (username, email, password_hash, is_active, is_admin) 
VALUES ('admin', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj3ZxQQxq3Hy', true, true)
ON CONFLICT (username) DO NOTHING;

-- Создание дефолтных папок
INSERT INTO folders (name, path, created_by) VALUES 
    ('Договоры', '/contracts', 1),
    ('Шаблоны', '/templates', 1),
    ('Архив', '/archive', 1)
ON CONFLICT (path) DO NOTHING;

-- Создание дефолтных настроек
INSERT INTO settings (key, value, description) VALUES 
    ('document_help_info', 'Для правильного заполнения документов:

1. Все поля должны быть заполнены корректно
2. Даты указывать в формате ДД.ММ.ГГГГ
3. Суммы указывать цифрами
4. ФИО указывать полностью', 'Информация для помощи при заполнении документов'),
    
    ('contract_help_info', 'При заполнении договоров обратите внимание:

- Номер договора должен быть уникальным
- Сумма указывается цифрами и прописью
- Дата подписания обязательна
- Все реквизиты должны быть актуальными', 'Специфичная информация для договоров')
ON CONFLICT (key) DO NOTHING;

-- Создание описаний плейсхолдеров
INSERT INTO placeholder_descriptions (name, description, example_value) VALUES 
    ('company_name', 'Название компании', 'ООО "Рога и Копыта"'),
    ('contract_number', 'Номер договора', 'ДОГ-2024-001'),
    ('contract_date', 'Дата договора', '20.08.2024'),
    ('client_name', 'ФИО клиента', 'Иванов Иван Иванович'),
    ('client_passport', 'Паспортные данные клиента', 'AB1234567'),
    ('amount', 'Сумма договора', '100000'),
    ('amount_words', 'Сумма прописью', 'Сто тысяч рублей 00 копеек'),
    ('address', 'Адрес', 'г. Москва, ул. Примерная, д. 1, кв. 1')
ON CONFLICT (name) DO NOTHING;

-- Установка прав доступа для администратора
INSERT INTO permissions (user_id, folder_id, level) 
SELECT 1, id, 'manage' FROM folders
ON CONFLICT (user_id, folder_id) DO NOTHING;

COMMIT;
