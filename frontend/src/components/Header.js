import React from 'react';
import { useAuth } from '../context/AuthContext';

const Header = () => {
  const { user, logout } = useAuth();

  const handleLogout = () => {
    logout();
    window.showNotification?.('Вы успешно вышли из системы', 'success');
  };

  return (
    <header className="header">
      <div className="header-left">
        <h1 className="header-title">Contract Manager</h1>
      </div>
      
      <div className="header-actions">
        {user && (
          <>
            <div className="user-menu">
              <span className="user-greeting">Привет, {user.username}!</span>
              <span className="user-role">
                {user.is_admin ? 'Администратор' : 'Пользователь'}
              </span>
            </div>
            
            <button 
              className="btn btn-secondary btn-sm"
              onClick={handleLogout}
            >
              <span>🚪</span>
              Выйти
            </button>
          </>
        )}
      </div>
    </header>
  );
};

export default Header; 