import React from 'react';
import { useAuth } from '../context/AuthContext';

export default function Header() {
  const { user, logout } = useAuth();

  const handleLogout = async () => {
    await logout();
    window.location.href = '/login';
  };

  return (
    <header className="header-bar">
      <div className="header-content">
        <div className="header-title">Генератор договоров</div>
        {user && (
          <div className="header-user">
            <span className="header-username">{user.username || 'Пользователь'}</span>
            <button className="header-logout-btn" onClick={handleLogout}>Выйти</button>
          </div>
        )}
      </div>
    </header>
  );
} 