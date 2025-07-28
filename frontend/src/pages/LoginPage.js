import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';

export default function LoginPage() {
  const { login } = useAuth();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(username, password);
      navigate('/');
    } catch (err) {
      setError('Неверный логин или пароль, либо пользователь не активирован');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <h2>Вход</h2>
      <form onSubmit={handleSubmit} className="auth-form">
        <input
          type="text"
          placeholder="Имя пользователя"
          value={username}
          onChange={e => setUsername(e.target.value)}
          required
        />
        <input
          type="password"
          placeholder="Пароль"
          value={password}
          onChange={e => setPassword(e.target.value)}
          required
        />
        <button type="submit" disabled={loading}>{loading ? 'Вход...' : 'Войти'}</button>
        {error && <div className="auth-error">{error}</div>}
      </form>
      <div style={{ marginTop: 16 }}>
        Нет аккаунта? <a href="/register">Зарегистрироваться</a>
      </div>
    </div>
  );
} 