import React, { useState, useRef } from 'react';

const FileUpload = ({ onFileSelect, accept = '.docx', multiple = false, maxSize = 10 }) => {
  const [isDragging, setIsDragging] = useState(false);
  const [dragCounter, setDragCounter] = useState(0);
  const fileInputRef = useRef(null);

  const handleDragEnter = (e) => {
    e.preventDefault();
    setDragCounter(prev => prev + 1);
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    setDragCounter(prev => prev - 1);
    if (dragCounter === 0) {
      setIsDragging(false);
    }
  };

  const handleDragOver = (e) => {
    e.preventDefault();
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setIsDragging(false);
    setDragCounter(0);

    const files = Array.from(e.dataTransfer.files);
    handleFiles(files);
  };

  const handleFileInput = (e) => {
    const files = Array.from(e.target.files);
    handleFiles(files);
  };

  const handleFiles = (files) => {
    const validFiles = files.filter(file => {
      // Проверка размера файла (в МБ)
      const fileSizeMB = file.size / (1024 * 1024);
      if (fileSizeMB > maxSize) {
        window.showNotification?.(`Файл ${file.name} слишком большой. Максимальный размер: ${maxSize}МБ`, 'error');
        return false;
      }

      // Проверка типа файла
      if (accept && !file.name.toLowerCase().endsWith(accept.replace('*', ''))) {
        window.showNotification?.(`Файл ${file.name} имеет неподдерживаемый формат`, 'error');
        return false;
      }

      return true;
    });

    if (validFiles.length > 0) {
      onFileSelect(multiple ? validFiles : validFiles[0]);
      window.showNotification?.(`Загружено файлов: ${validFiles.length}`, 'success');
    }
  };

  const handleClick = () => {
    fileInputRef.current?.click();
  };

  return (
    <div
      className={`file-upload ${isDragging ? 'dragover' : ''}`}
      onDragEnter={handleDragEnter}
      onDragLeave={handleDragLeave}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
      onClick={handleClick}
    >
      <div className="file-upload-icon">📁</div>
      <div className="file-upload-text">
        {isDragging ? 'Отпустите файлы здесь' : 'Перетащите файлы сюда или нажмите для выбора'}
      </div>
      <div className="file-upload-hint">
        Поддерживаемые форматы: {accept} • Максимальный размер: {maxSize}МБ
      </div>
      <input
        ref={fileInputRef}
        type="file"
        accept={accept}
        multiple={multiple}
        onChange={handleFileInput}
        style={{ display: 'none' }}
      />
    </div>
  );
};

export default FileUpload; 