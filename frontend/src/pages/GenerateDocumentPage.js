import React, { useEffect, useState } from 'react';
import { getFolders } from '../api/folders';
import { getTemplatesByFolder, getTemplateFields, generateDocument } from '../api/templates';
import { useAuth } from '../context/AuthContext';

export default function GenerateDocumentPage() {
  const { csrfToken } = useAuth();
  const [folders, setFolders] = useState([]);
  const [selectedFolder, setSelectedFolder] = useState(null);
  const [templates, setTemplates] = useState([]);
  const [selectedTemplate, setSelectedTemplate] = useState(null);
  const [templateFields, setTemplateFields] = useState([]);
  const [fieldValues, setFieldValues] = useState({});
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    (async () => {
      try {
        const data = await getFolders();
        setFolders(Array.isArray(data) ? data : Array.isArray(data.folders) ? data.folders : []);
        if ((Array.isArray(data) && data.length > 0)) setSelectedFolder(data[0].id);
        else if (Array.isArray(data.folders) && data.folders.length > 0) setSelectedFolder(data.folders[0].id);
      } catch {
        setError('Ошибка загрузки папок');
        setFolders([]);
      }
    })();
  }, []);

  useEffect(() => {
    if (!selectedFolder) return;
    setLoading(true);
    setError('');
    (async () => {
      try {
        const data = await getTemplatesByFolder(selectedFolder);
        setTemplates(Array.isArray(data) ? data : Array.isArray(data.templates) ? data.templates : []);
      } catch {
        setError('Ошибка загрузки шаблонов');
        setTemplates([]);
      } finally {
        setLoading(false);
      }
    })();
  }, [selectedFolder]);

  const handleTemplateSelect = async (template) => {
    setSelectedTemplate(template);
    setLoading(true);
    setError('');
    try {
      const fields = await getTemplateFields(template.id);
      setTemplateFields(fields);
      // Инициализируем значения полей
      const initialValues = {};
      fields.forEach(field => {
        initialValues[field] = '';
      });
      setFieldValues(initialValues);
    } catch {
      setError('Ошибка загрузки полей шаблона');
    } finally {
      setLoading(false);
    }
  };

  const handleGenerateDocument = async (e) => {
    e.preventDefault();
    if (!selectedTemplate) return;
    setError('');
    setSuccess('');
    setLoading(true);
    try {
      await generateDocument(selectedTemplate.id, fieldValues, csrfToken);
      setSuccess('Документ сгенерирован и скачан');
    } catch {
      setError('Ошибка генерации документа');
    } finally {
      setLoading(false);
    }
  };

  const handleFieldChange = (field, value) => {
    setFieldValues(prev => ({
      ...prev,
      [field]: value
    }));
  };

  return (
    <div>
      <h2>Создание документа из шаблона</h2>
      {error && <div className="auth-error">{error}</div>}
      {success && <div className="auth-success">{success}</div>}
      
      <div style={{ display: 'flex', gap: 20, marginTop: 20 }}>
        {/* Левая панель - выбор шаблона */}
        <div style={{ flex: 1, padding: 20, border: '1px solid #e0e7ef', borderRadius: 8 }}>
          <h3>Выбор шаблона</h3>
          
          <div style={{ marginBottom: 16 }}>
            <label style={{ display: 'block', marginBottom: 8, fontWeight: 'bold' }}>
              Папка:
            </label>
            <select 
              value={selectedFolder || ''} 
              onChange={e => setSelectedFolder(Number(e.target.value))}
              style={{ width: '100%', padding: 8, border: '1px solid #d1d5db', borderRadius: 4 }}
            >
              {(folders || []).map(f => (
                <option key={f.id} value={f.id}>{f.name}</option>
              ))}
            </select>
          </div>

          {loading ? (
            <div>Загрузка шаблонов...</div>
          ) : (
            <div>
              <label style={{ display: 'block', marginBottom: 8, fontWeight: 'bold' }}>
                Шаблон:
              </label>
              <div style={{ maxHeight: 300, overflowY: 'auto' }}>
                {(templates || []).map(template => (
                  <div 
                    key={template.id}
                    onClick={() => handleTemplateSelect(template)}
                    style={{
                      padding: 12,
                      border: selectedTemplate?.id === template.id ? '2px solid #4CAF50' : '1px solid #d1d5db',
                      borderRadius: 4,
                      marginBottom: 8,
                      cursor: 'pointer',
                      background: selectedTemplate?.id === template.id ? '#f0f8f0' : '#fff',
                      transition: 'all 0.2s'
                    }}
                  >
                    <div style={{ fontWeight: 'bold' }}>{template.filename}</div>
                    <div style={{ fontSize: 12, color: '#666' }}>
                      ID: {template.id} | Загружен: {new Date(template.uploaded_at).toLocaleDateString()}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Правая панель - заполнение полей */}
        {selectedTemplate && (
          <div style={{ flex: 1, padding: 20, border: '1px solid #e0e7ef', borderRadius: 8 }}>
            <h3>Заполнение данных</h3>
            <div style={{ marginBottom: 16 }}>
              <strong>Выбранный шаблон:</strong> {selectedTemplate.filename}
            </div>
            
            {templateFields.length > 0 ? (
              <form onSubmit={handleGenerateDocument}>
                {templateFields.map(field => (
                  <div key={field} style={{ marginBottom: 16 }}>
                    <label style={{ display: 'block', marginBottom: 4, fontWeight: 'bold' }}>
                      {field}:
                    </label>
                    <input
                      type="text"
                      value={fieldValues[field] || ''}
                      onChange={e => handleFieldChange(field, e.target.value)}
                      style={{
                        width: '100%',
                        padding: 8,
                        border: '1px solid #d1d5db',
                        borderRadius: 4
                      }}
                      placeholder={`Введите значение для ${field}`}
                      required
                    />
                  </div>
                ))}
                
                <button 
                  type="submit" 
                  disabled={loading}
                  style={{
                    padding: '12px 24px',
                    background: '#4CAF50',
                    color: 'white',
                    border: 'none',
                    borderRadius: 4,
                    cursor: 'pointer',
                    fontSize: 16,
                    fontWeight: 'bold'
                  }}
                >
                  {loading ? 'Генерация...' : 'Создать документ'}
                </button>
              </form>
            ) : (
              <div style={{ color: '#666', fontStyle: 'italic' }}>
                В выбранном шаблоне не найдено полей для заполнения.
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
} 