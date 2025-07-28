import React from 'react';

const LoadingSpinner = ({ size = 'medium', text = 'Загрузка...' }) => {
  const getSizeClass = () => {
    switch (size) {
      case 'small':
        return 'spinner-sm';
      case 'large':
        return 'spinner-lg';
      default:
        return 'spinner';
    }
  };

  return (
    <div className="loading">
      <div className={getSizeClass()}></div>
      {text && <p className="loading-text">{text}</p>}
    </div>
  );
};

export default LoadingSpinner; 