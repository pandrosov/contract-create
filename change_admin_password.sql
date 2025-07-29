-- Скрипт для изменения пароля администратора
-- Новый пароль: Contract2024!

UPDATE users 
SET hashed_password = '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj3ZxQQxq3Hy' 
WHERE username = 'admin'; 