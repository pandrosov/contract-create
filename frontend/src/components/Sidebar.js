import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Sidebar = () => {
  const { user } = useAuth();

  const navItems = [
    {
      path: '/folders',
      label: 'Папки',
      icon: '📁'
    },
    {
      path: '/templates',
      label: 'Шаблоны',
      icon: '📄'
    },
    {
      path: '/generate',
      label: 'Создать документ',
      icon: '✏️'
    },
    {
      path: '/users',
      label: 'Пользователи',
      icon: '👥'
    },
    {
      path: '/permissions',
      label: 'Права доступа',
      icon: '🔐'
    },
    {
      path: '/logs',
      label: 'Логи',
      icon: '📊'
    }
  ];

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <div className="sidebar-title">Contract Manager</div>
        <div className="sidebar-subtitle">Система управления договорами</div>
      </div>
      
      <nav className="sidebar-nav">
        {navItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
          >
            <span className="nav-icon">{item.icon}</span>
            {item.label}
          </NavLink>
        ))}
      </nav>
      
      {user && (
        <div className="sidebar-footer">
          <div className="user-info">
            <div className="user-name">{user.username}</div>
            <div className="user-role">
              {user.is_admin ? 'Администратор' : 'Пользователь'}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Sidebar; 