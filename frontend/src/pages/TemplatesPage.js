import React, { useState, useEffect } from 'react';
import { getTemplatesByFolder, uploadTemplate, deleteTemplate } from '../api/templates';
import { getFolders } from '../api/folders';
import FileUpload from '../components/FileUpload';
import Modal from '../components/Modal';
import LoadingSpinner from '../components/LoadingSpinner';
import PlaceholderDescriptionsModal from '../components/PlaceholderDescriptionsModal';

const TemplatesPage = () => {
  const [templates, setTemplates] = useState([]);
  const [folders, setFolders] = useState([]);
  const [selectedFolder, setSelectedFolder] = useState('');
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [selectedFile, setSelectedFile] = useState(null);
  const [showDescriptionsModal, setShowDescriptionsModal] = useState(false);
  const [selectedTemplateForDescriptions, setSelectedTemplateForDescriptions] = useState(null);

  useEffect(() => {
    fetchFolders();
  }, []);

  useEffect(() => {
    if (selectedFolder) {
      fetchTemplates();
    }
  }, [selectedFolder]);

  const fetchFolders = async () => {
    try {
      const foldersData = await getFolders();
      setFolders(foldersData);
      if (foldersData.length > 0) {
        setSelectedFolder(foldersData[0].id);
      }
    } catch (error) {
      console.error('Error fetching folders:', error);
      window.showNotification?.('Ошибка при загрузке папок', 'error');
    }
  };

  const fetchTemplates = async () => {
    if (!selectedFolder) return;
    
    setLoading(true);
    try {
      const templatesData = await getTemplatesByFolder(selectedFolder);
      setTemplates(templatesData);
    } catch (error) {
      console.error('Error fetching templates:', error);
      window.showNotification?.('Ошибка при загрузке шаблонов', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleFileSelect = (file) => {
    setSelectedFile(file);
  };

  const handleUpload = async () => {
    if (!selectedFile || !selectedFolder) return;

    setUploading(true);
    try {
      await uploadTemplate(selectedFile, selectedFolder);
      window.showNotification?.('Шаблон успешно загружен!', 'success');
      setShowUploadModal(false);
      setSelectedFile(null);
      fetchTemplates();
    } catch (error) {
      console.error('Error uploading template:', error);
      window.showNotification?.('Ошибка при загрузке шаблона', 'error');
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = async (templateId) => {
    if (!window.confirm('Вы уверены, что хотите удалить этот шаблон?')) return;

    try {
      await deleteTemplate(templateId);
      window.showNotification?.('Шаблон успешно удален!', 'success');
      fetchTemplates();
    } catch (error) {
      console.error('Error deleting template:', error);
      window.showNotification?.('Ошибка при удалении шаблона', 'error');
    }
  };

  const handleOpenDescriptions = (template) => {
    setSelectedTemplateForDescriptions(template);
    setShowDescriptionsModal(true);
  };

  const handleCloseDescriptions = () => {
    setShowDescriptionsModal(false);
    setSelectedTemplateForDescriptions(null);
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('ru-RU', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  if (loading) {
    return (
      <div className="page-header">
        <h1 className="page-title">Шаблоны</h1>
        <LoadingSpinner text="Загрузка шаблонов..." />
      </div>
    );
  }

  return (
    <div className="templates-page">
      <div className="page-header">
        <h1 className="page-title">Шаблоны</h1>
        <p className="page-subtitle">Управление шаблонами документов</p>
      </div>

      <div className="card">
        <div className="card-header">
          <h2 className="card-title">Загрузка шаблона</h2>
          <button
            className="btn btn-primary"
            onClick={() => setShowUploadModal(true)}
          >
            <span>📄</span>
            Загрузить шаблон
          </button>
        </div>

        <div className="form-group">
          <label htmlFor="folder-select" className="form-label">
            Выберите папку
          </label>
          <select
            id="folder-select"
            className="form-select"
            value={selectedFolder}
            onChange={(e) => setSelectedFolder(e.target.value)}
          >
            {folders.map(folder => (
              <option key={folder.id} value={folder.id}>
                {folder.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <h2 className="card-title">Список шаблонов</h2>
          <span className="card-subtitle">
            {templates.length} шаблонов в папке
          </span>
        </div>

        {templates.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">📄</div>
            <h3 className="empty-state-title">Нет шаблонов</h3>
            <p className="empty-state-description">
              В этой папке пока нет шаблонов. Загрузите первый шаблон, чтобы начать работу.
            </p>
            <button
              className="btn btn-primary"
              onClick={() => setShowUploadModal(true)}
            >
              <span>📄</span>
              Загрузить шаблон
            </button>
          </div>
        ) : (
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Название</th>
                  <th>Папка</th>
                  <th>Загружен</th>
                  <th>Действия</th>
                </tr>
              </thead>
              <tbody>
                {templates.map(template => (
                  <tr key={template.id}>
                    <td>
                      <div className="template-info">
                        <span className="template-name">{template.filename}</span>
                      </div>
                    </td>
                    <td>
                      {folders.find(f => f.id === template.folder_id)?.name || 'Неизвестная папка'}
                    </td>
                    <td>{template.uploaded_at || 'Не указано'}</td>
                    <td>
                      <div className="table-actions">
                        <button
                          className="btn btn-info btn-sm"
                          onClick={() => handleOpenDescriptions(template)}
                          title="Управление описаниями плейсхолдеров"
                        >
                          <span>📝</span>
                          Описания
                        </button>
                        <button
                          className="btn btn-secondary btn-sm"
                          onClick={() => window.open(`/api/templates/${template.id}/download`, '_blank')}
                        >
                          <span>⬇️</span>
                          Скачать
                        </button>
                        <button
                          className="btn btn-danger btn-sm"
                          onClick={() => handleDelete(template.id)}
                        >
                          <span>🗑️</span>
                          Удалить
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="card">
        <div className="card-header">
          <h2 className="card-title">Информация</h2>
        </div>
        <div className="info-content">
          <p>
            <strong>📝 Как использовать шаблоны:</strong>
          </p>
          <ul>
            <li>Загрузите .docx файл с плейсхолдерами в формате <code>{'{{FIELD_NAME}}'}</code></li>
            <li>Система автоматически извлечет поля из шаблона</li>
            <li>Перейдите на страницу "Создать документ" для генерации</li>
            <li>Заполните поля и скачайте готовый документ</li>
          </ul>
        </div>
      </div>

      <Modal
        isOpen={showUploadModal}
        onClose={() => setShowUploadModal(false)}
        title="Загрузка шаблона"
        size="large"
      >
        <div className="upload-modal-content">
          <div className="form-group">
            <label className="form-label">Выберите файл шаблона</label>
            <FileUpload
              onFileSelect={handleFileSelect}
              accept=".docx"
              maxSize={10}
            />
          </div>

          {selectedFile && (
            <div className="selected-file">
              <p><strong>Выбранный файл:</strong> {selectedFile.name}</p>
              <p><strong>Размер:</strong> {(selectedFile.size / 1024 / 1024).toFixed(2)} МБ</p>
            </div>
          )}

          <div className="modal-actions">
            <button
              className="btn btn-secondary"
              onClick={() => setShowUploadModal(false)}
              disabled={uploading}
            >
              Отмена
            </button>
            <button
              className="btn btn-primary"
              onClick={handleUpload}
              disabled={!selectedFile || uploading}
            >
              {uploading ? (
                <>
                  <div className="spinner spinner-sm"></div>
                  Загрузка...
                </>
              ) : (
                <>
                  <span>📤</span>
                  Загрузить
                </>
              )}
            </button>
          </div>
        </div>
      </Modal>

      <PlaceholderDescriptionsModal
        isOpen={showDescriptionsModal}
        onClose={handleCloseDescriptions}
        template={selectedTemplateForDescriptions}
        onUpdate={() => {
          // Можно добавить обновление данных если нужно
        }}
      />
    </div>
  );
};

export default TemplatesPage; 