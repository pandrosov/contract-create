import React, { useEffect } from 'react';

const Notification = ({ message, type = 'info', onClose, duration = 5000 }) => {
  useEffect(() => {
    if (duration > 0) {
      const timer = setTimeout(() => {
        onClose();
      }, duration);

      return () => clearTimeout(timer);
    }
  }, [duration, onClose]);

  const getIcon = () => {
    switch (type) {
      case 'success':
        return '✓';
      case 'error':
        return '✕';
      case 'warning':
        return '⚠';
      case 'info':
      default:
        return 'ℹ';
    }
  };

  return (
    <div className={`alert alert-${type} fade-in`}>
      <span className="alert-icon">{getIcon()}</span>
      <span className="alert-message">{message}</span>
      <button 
        className="alert-close" 
        onClick={onClose}
        aria-label="Закрыть уведомление"
      >
        ×
      </button>
    </div>
  );
};

export default Notification; 