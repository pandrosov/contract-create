import React from 'react';

const DashboardStats = ({ stats }) => {
  const defaultStats = {
    folders: 0,
    templates: 0,
    users: 0,
    documents: 0
  };

  const currentStats = { ...defaultStats, ...stats };

  const statCards = [
    {
      title: 'Папки',
      value: currentStats.folders,
      icon: '📁',
      color: 'blue',
      description: 'Всего папок'
    },
    {
      title: 'Шаблоны',
      value: currentStats.templates,
      icon: '📄',
      color: 'green',
      description: 'Загруженных шаблонов'
    },
    {
      title: 'Пользователи',
      value: currentStats.users,
      icon: '👥',
      color: 'purple',
      description: 'Активных пользователей'
    },
    {
      title: 'Документы',
      value: currentStats.documents,
      icon: '📋',
      color: 'orange',
      description: 'Созданных документов'
    }
  ];

  const getColorClass = (color) => {
    const colors = {
      blue: 'bg-blue-500',
      green: 'bg-green-500',
      purple: 'bg-purple-500',
      orange: 'bg-orange-500'
    };
    return colors[color] || 'bg-blue-500';
  };

  return (
    <div className="dashboard-stats">
      <div className="stats-grid">
        {statCards.map((stat, index) => (
          <div key={index} className="stat-card">
            <div className="stat-icon">
              <span className="stat-emoji">{stat.icon}</span>
            </div>
            <div className="stat-content">
              <div className="stat-value">{stat.value}</div>
              <div className="stat-title">{stat.title}</div>
              <div className="stat-description">{stat.description}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default DashboardStats; 