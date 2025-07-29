# Scripts

Эта папка содержит все скрипты для управления системой.

## Структура

### `/admin/` - Скрипты для управления администраторами
- `change_admin_password.py` - Изменение пароля администратора
- `generate_hash.py` - Генерация хеша пароля
- `activate_admin.py` - Активация администратора

### `/database/` - Скрипты для работы с базой данных
- `change_admin_password.sql` - SQL скрипт для изменения пароля
- `init_db.py` - Инициализация базы данных
- `create_test_user.py` - Создание тестового пользователя

### `/deployment/` - Скрипты для развертывания
- `deploy.sh` - Основной скрипт развертывания
- `deploy_alnilam.sh` - Развертывание на сервере alnilam
- `remote_deploy.sh` - Удаленное развертывание
- `cleanup_deployments.sh` - Очистка развертываний
- `setup_ssh.sh` - Настройка SSH
- `check_server.sh` - Проверка сервера
- `setup_docker_db.sh` - Настройка Docker базы данных
- `setup_database.sh` - Настройка базы данных
- `backup.sh` - Резервное копирование

### `/ssl/` - Скрипты для SSL сертификатов
- `ssl_renew.sh` - Обновление SSL сертификатов

### `/` - Общие скрипты
- `test_docs.html` - Тестовая страница документации
- `debug_docs.html` - Отладочная страница документации
- `test.txt` - Тестовый файл
- `downloaded_template.docx` - Скачанный шаблон
- `test_template.docx` - Тестовый шаблон
- `cookies.txt` - Файл с cookies 