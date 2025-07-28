import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import DashboardStats from '../components/DashboardStats';
import LoadingSpinner from '../components/LoadingSpinner';

const DashboardPage = () => {
  const [stats, setStats] = useState({
    folders: 0,
    templates: 0,
    users: 0,
    documents: 0
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Имитация загрузки статистики
    setTimeout(() => {
      setStats({
        folders: 5,
        templates: 12,
        users: 8,
        documents: 24
      });
      setLoading(false);
    }, 1000);
  }, []);

  const quickActions = [
    {
      title: 'Создать документ',
      description: 'Генерировать документы из шаблонов',
      icon: '✏️',
      path: '/generate',
      color: 'blue'
    },
    {
      title: 'Загрузить шаблон',
      description: 'Добавить новый шаблон в систему',
      icon: '📄',
      path: '/templates',
      color: 'green'
    },
    {
      title: 'Управление папками',
      description: 'Создать и организовать папки',
      icon: '📁',
      path: '/folders',
      color: 'purple'
    },
    {
      title: 'Пользователи',
      description: 'Управление пользователями системы',
      icon: '👥',
      path: '/users',
      color: 'orange'
    }
  ];

  const recentActivity = [
    {
      type: 'document',
      title: 'Создан договор №123',
      time: '2 минуты назад',
      icon: '📋'
    },
    {
      type: 'template',
      title: 'Загружен шаблон "Договор поставки"',
      time: '15 минут назад',
      icon: '📄'
    },
    {
      type: 'folder',
      title: 'Создана папка "Архив 2024"',
      time: '1 час назад',
      icon: '📁'
    },
    {
      type: 'user',
      title: 'Новый пользователь зарегистрирован',
      time: '2 часа назад',
      icon: '👤'
    }
  ];

  if (loading) {
    return (
      <div className="page-header">
        <h1 className="page-title">Главная</h1>
        <LoadingSpinner text="Загрузка статистики..." />
      </div>
    );
  }

  return (
    <div className="dashboard-page">
      <div className="page-header">
        <h1 className="page-title">Главная</h1>
        <p className="page-subtitle">Обзор системы управления договорами</p>
      </div>

      {/* Статистика */}
      <DashboardStats stats={stats} />

      <div className="dashboard-content">
        <div className="dashboard-grid">
          {/* Быстрые действия */}
          <div className="card">
            <div className="card-header">
              <h2 className="card-title">Быстрые действия</h2>
            </div>
            <div className="quick-actions">
              {quickActions.map((action, index) => (
                <Link
                  key={index}
                  to={action.path}
                  className={`quick-action-card quick-action-${action.color}`}
                >
                  <div className="quick-action-icon">
                    <span>{action.icon}</span>
                  </div>
                  <div className="quick-action-content">
                    <h3 className="quick-action-title">{action.title}</h3>
                    <p className="quick-action-description">{action.description}</p>
                  </div>
                </Link>
              ))}
            </div>
          </div>

          {/* Последняя активность */}
          <div className="card">
            <div className="card-header">
              <h2 className="card-title">Последняя активность</h2>
            </div>
            <div className="activity-list">
              {recentActivity.map((activity, index) => (
                <div key={index} className="activity-item">
                  <div className="activity-icon">
                    <span>{activity.icon}</span>
                  </div>
                  <div className="activity-content">
                    <div className="activity-title">{activity.title}</div>
                    <div className="activity-time">{activity.time}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Информация о системе */}
        <div className="card">
          <div className="card-header">
            <h2 className="card-title">Информация о системе</h2>
          </div>
          <div className="system-info">
            <div className="info-grid">
              <div className="info-item">
                <div className="info-label">Версия системы</div>
                <div className="info-value">1.0.0</div>
              </div>
              <div className="info-item">
                <div className="info-label">Последнее обновление</div>
                <div className="info-value">Сегодня, 14:30</div>
              </div>
              <div className="info-item">
                <div className="info-label">Статус системы</div>
                <div className="info-value status-online">● Онлайн</div>
              </div>
              <div className="info-item">
                <div className="info-label">Поддержка</div>
                <div className="info-value">support@company.com</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardPage; 