import React from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Sidebar = ({ collapsed = false, onToggle }) => {
  const { user } = useAuth();
  const location = useLocation();

  const menuCategories = [
    {
      title: 'Основные',
      items: [
        {
          path: '/dashboard',
          label: 'Главная',
          icon: '🏠',
          description: 'Обзор системы'
        },
        {
          path: '/folders',
          label: 'Папки',
          icon: '📁',
          description: 'Управление папками'
        },
        {
          path: '/templates',
          label: 'Шаблоны',
          icon: '📄',
          description: 'Управление шаблонами'
        },
        {
          path: '/generate',
          label: 'Создать документ',
          icon: '✏️',
          description: 'Генерация документов'
        },
        {
          path: '/acts',
          label: 'Генерация актов',
          icon: '📋',
          description: 'Массовая генерация актов'
        }
      ]
    },
    {
      title: 'Администрирование',
      items: [
        {
          path: '/users',
          label: 'Пользователи',
          icon: '👥',
          description: 'Управление пользователями',
          adminOnly: true
        },
        {
          path: '/permissions',
          label: 'Права доступа',
          icon: '🔐',
          description: 'Настройка прав',
          adminOnly: true
        },
        {
          path: '/logs',
          label: 'Логи системы',
          icon: '📊',
          description: 'Просмотр логов',
          adminOnly: true
        },
        {
          path: '/settings',
          label: 'Настройки',
          icon: '⚙️',
          description: 'Настройки системы',
          adminOnly: true
        }
      ]
    }
  ];

  const isActive = (path) => {
    return location.pathname === path;
  };

  return (
    <div className={`sidebar ${collapsed ? 'collapsed' : ''}`}>
      <div className="sidebar-header">
        <div className="sidebar-brand">
          <div className="sidebar-logo">📋</div>
          {!collapsed && (
            <div className="sidebar-brand-text">
              <div className="sidebar-title">Contract Manager</div>
              <div className="sidebar-subtitle">Система управления договорами</div>
            </div>
          )}
        </div>
        <button 
          className="sidebar-toggle"
          onClick={onToggle}
          title={collapsed ? 'Развернуть меню' : 'Свернуть меню'}
        >
          {collapsed ? '→' : '←'}
        </button>
      </div>
      
      <div className="sidebar-content">
        <nav className="sidebar-nav">
          {menuCategories.map((category, categoryIndex) => (
            <div key={categoryIndex} className="nav-category">
              {!collapsed && (
                <div className="nav-category-title">{category.title}</div>
              )}
              <div className="nav-category-items">
                {category.items.map((item) => {
                  // Показываем элемент только если пользователь админ или элемент не требует админских прав
                  if (item.adminOnly && !user?.is_admin) return null;
                  
                  return (
                    <NavLink
                      key={item.path}
                      to={item.path}
                      className={({ isActive }) => 
                        `nav-item ${isActive ? 'active' : ''} ${collapsed ? 'collapsed' : ''}`
                      }
                      title={collapsed ? item.label : undefined}
                    >
                      <span className="nav-icon">{item.icon}</span>
                      {!collapsed && (
                        <div className="nav-item-content">
                          <span className="nav-label">{item.label}</span>
                          <span className="nav-description">{item.description}</span>
                        </div>
                      )}
                    </NavLink>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>
      </div>
      
      {user && (
        <div className="sidebar-footer">
          <div className="user-profile">
            <div className="user-avatar">
              {user.username.charAt(0).toUpperCase()}
            </div>
            {!collapsed && (
              <div className="user-info">
                <div className="user-name">{user.username}</div>
                <div className="user-role">
                  {user.is_admin ? 'Администратор' : 'Пользователь'}
                </div>
                <div className="user-status online">● Онлайн</div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default Sidebar; 