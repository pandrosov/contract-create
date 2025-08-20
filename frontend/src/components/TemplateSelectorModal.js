import React, { useState, useEffect } from 'react';
import { getFolders } from '../api/folders';
import { getTemplatesByFolder } from '../api/templates';
import '../styles/global.css';

const TemplateSelectorModal = ({ isOpen, onClose, onSelect, selectedTemplateId }) => {
  const [folders, setFolders] = useState([]);
  const [templates, setTemplates] = useState({});
  const [expandedFolders, setExpandedFolders] = useState(new Set());
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isOpen) {
      loadFolders();
    }
  }, [isOpen]);

  const loadFolders = async () => {
    try {
      setLoading(true);
      const foldersData = await getFolders();
      setFolders(Array.isArray(foldersData) ? foldersData : []);
    } catch (error) {
      console.error('Error loading folders:', error);
    } finally {
      setLoading(false);
    }
  };

  const toggleFolder = async (folderId) => {
    const newExpanded = new Set(expandedFolders);
    if (newExpanded.has(folderId)) {
      newExpanded.delete(folderId);
    } else {
      newExpanded.add(folderId);
      // Загружаем шаблоны папки, если еще не загружены
      if (!templates[folderId]) {
        try {
          const templatesData = await getTemplatesByFolder(folderId);
          setTemplates(prev => ({
            ...prev,
            [folderId]: Array.isArray(templatesData) ? templatesData : []
          }));
        } catch (error) {
          console.error('Error loading templates for folder:', folderId, error);
        }
      }
    }
    setExpandedFolders(newExpanded);
  };

  const handleTemplateSelect = (template) => {
    onSelect(template);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content template-selector-modal" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h3>Выбор шаблона</h3>
          <button className="modal-close" onClick={onClose}>×</button>
        </div>
        
        <div className="modal-body">
          {loading ? (
            <div className="loading">Загрузка папок...</div>
          ) : (
            <div className="folder-tree">
              {folders.map(folder => (
                <div key={folder.id} className="folder-item">
                  <div 
                    className="folder-header"
                    onClick={() => toggleFolder(folder.id)}
                  >
                    <span className={`folder-icon ${expandedFolders.has(folder.id) ? 'expanded' : ''}`}>
                      {expandedFolders.has(folder.id) ? '📂' : '📁'}
                    </span>
                    <span className="folder-name">{folder.name}</span>
                    <span className="folder-count">
                      {templates[folder.id] ? `(${templates[folder.id].length})` : ''}
                    </span>
                  </div>
                  
                  {expandedFolders.has(folder.id) && (
                    <div className="templates-list">
                      {templates[folder.id] ? (
                        templates[folder.id].length > 0 ? (
                          templates[folder.id].map(template => (
                            <div 
                              key={template.id} 
                              className={`template-item ${selectedTemplateId === template.id ? 'selected' : ''}`}
                              onClick={() => handleTemplateSelect(template)}
                            >
                              <span className="template-icon">📄</span>
                              <span className="template-name">{template.filename}</span>
                              <span className="template-date">
                                {template.uploaded_at || 'Не указано'}
                              </span>
                            </div>
                          ))
                        ) : (
                          <div className="no-templates">В этой папке нет шаблонов</div>
                        )
                      ) : (
                        <div className="loading-templates">Загрузка шаблонов...</div>
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default TemplateSelectorModal; 