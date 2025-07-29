# 🔑 Настройка SSH ключей для автоматического деплоя

## 📋 Обзор

Теперь наши скрипты поддерживают работу с SSH ключами, что позволяет:
- ✅ Автоматически подключаться к серверу без ввода пароля
- ✅ Использовать SSH агент для управления ключами
- ✅ Указывать кастомные пути к SSH ключам
- ✅ Безопасно выполнять деплой без интерактивного ввода

## 🚀 Быстрая настройка

### Вариант 1: Автоматическая настройка

```bash
# Настроить SSH и скопировать ключ на сервер
./setup_ssh.sh --copy-key --start-agent

# Проверить сервер
./check_server.sh --ssh-agent

# Запустить деплой
./deploy_alnilam.sh --ssh-agent
```

### Вариант 2: Ручная настройка

```bash
# 1. Скопировать ключ на сервер
ssh-copy-id root@178.172.138.229

# 2. Запустить SSH агент
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

# 3. Проверить подключение
ssh root@178.172.138.229 "echo 'Connection successful'"

# 4. Запустить деплой
./deploy_alnilam.sh --ssh-agent
```

## 🔧 Опции скриптов

### Скрипт настройки SSH (`setup_ssh.sh`)

```bash
./setup_ssh.sh [OPTIONS]

Options:
  --copy-key      Скопировать SSH ключ на сервер
  --start-agent   Запустить SSH агент и добавить ключ
  --help          Показать справку
```

### Скрипт проверки сервера (`check_server.sh`)

```bash
./check_server.sh [OPTIONS]

Options:
  --ssh-agent     Использовать SSH агент для управления ключами
  --key-path PATH Указать кастомный путь к SSH ключу
  --help          Показать справку
```

### Скрипт деплоя (`deploy_alnilam.sh`)

```bash
./deploy_alnilam.sh [OPTIONS]

Options:
  --ssh-agent     Использовать SSH агент для управления ключами
  --key-path PATH Указать кастомный путь к SSH ключу
  --help          Показать справку
```

## 🔑 Управление SSH ключами

### Проверка существующих ключей

```bash
# Посмотреть все SSH ключи
ls -la ~/.ssh/

# Проверить, какие ключи добавлены в агент
ssh-add -l
```

### Создание нового SSH ключа

```bash
# Создать новый ключ
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Или создать ключ с кастомным именем
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_custom
```

### Копирование ключа на сервер

```bash
# Автоматическое копирование
ssh-copy-id root@178.172.138.229

# Или с указанием конкретного ключа
ssh-copy-id -i ~/.ssh/id_rsa root@178.172.138.229
```

## 🚀 Использование SSH агента

### Запуск агента

```bash
# Запустить SSH агент
eval $(ssh-agent -s)

# Добавить ключ в агент
ssh-add ~/.ssh/id_rsa

# Проверить добавленные ключи
ssh-add -l
```

### Автоматический запуск агента

Добавьте в `~/.bashrc` или `~/.zshrc`:

```bash
# Автоматически запускать SSH агент
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval $(ssh-agent -s)
    ssh-add ~/.ssh/id_rsa 2>/dev/null
fi
```

## 🔧 Примеры использования

### 1. Полная автоматизация

```bash
# Настройка SSH
./setup_ssh.sh --copy-key --start-agent

# Проверка и деплой
./check_server.sh --ssh-agent
./deploy_alnilam.sh --ssh-agent
```

### 2. Использование кастомного ключа

```bash
# Проверка с кастомным ключом
./check_server.sh --key-path ~/.ssh/id_rsa_custom

# Деплой с кастомным ключом
./deploy_alnilam.sh --key-path ~/.ssh/id_rsa_custom
```

### 3. Ручная проверка подключения

```bash
# Тест подключения
ssh root@178.172.138.229 "echo 'Connection test'"

# Тест с кастомным ключом
ssh -i ~/.ssh/id_rsa_custom root@178.172.138.229 "echo 'Test'"
```

## 🚨 Устранение проблем

### Проблема: "Permission denied"

```bash
# 1. Проверить права на ключ
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# 2. Проверить права на .ssh директорию
chmod 700 ~/.ssh

# 3. Перезапустить SSH агент
killall ssh-agent
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa
```

### Проблема: "Host key verification failed"

```bash
# Добавить сервер в known_hosts
ssh-keyscan -H 178.172.138.229 >> ~/.ssh/known_hosts

# Или отключить проверку (не рекомендуется для продакшена)
ssh -o StrictHostKeyChecking=no root@178.172.138.229
```

### Проблема: "Connection timeout"

```bash
# Проверить доступность сервера
ping 178.172.138.229

# Проверить порт SSH
telnet 178.172.138.229 22

# Проверить файрвол
ssh -v root@178.172.138.229
```

## 📋 Чек-лист готовности

- ✅ SSH ключ создан (`~/.ssh/id_rsa`)
- ✅ Ключ скопирован на сервер (`ssh-copy-id`)
- ✅ SSH агент запущен (`ssh-add -l`)
- ✅ Подключение работает (`ssh root@178.172.138.229`)
- ✅ Скрипты исполняемы (`chmod +x *.sh`)

## 🎯 Рекомендуемый workflow

1. **Настройка SSH:**
   ```bash
   ./setup_ssh.sh --copy-key --start-agent
   ```

2. **Проверка сервера:**
   ```bash
   ./check_server.sh --ssh-agent
   ```

3. **Деплой:**
   ```bash
   ./deploy_alnilam.sh --ssh-agent
   ```

4. **Проверка результата:**
   ```bash
   curl -k https://contract.alnilam.by
   ```

## 🔒 Безопасность

- ✅ Используйте сильные SSH ключи (RSA 4096 или Ed25519)
- ✅ Защитите ключи парольной фразой
- ✅ Регулярно ротируйте ключи
- ✅ Используйте SSH агент для временного хранения ключей
- ✅ Настройте файрвол на сервере

**Готово к автоматическому деплою! 🚀** 