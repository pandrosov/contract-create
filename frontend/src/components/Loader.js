import React from 'react';

const Loader = ({ text = "Загрузка...", showProgress = false, progress = 0 }) => {
  return (
    <div className="loader-container">
      <div className="loader-with-text">
        <div className="loader"></div>
        <div className="loader-text">{text}</div>
        
        {showProgress && (
          <div className="progress-container">
            <div 
              className="progress-bar" 
              style={{ width: `${progress}%` }}
            ></div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Loader; 