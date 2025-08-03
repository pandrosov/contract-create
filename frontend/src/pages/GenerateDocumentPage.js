import React, { useEffect, useState } from 'react';
import { getFolders } from '../api/folders';
import { getTemplatesByFolder, getTemplateFields, generateDocument } from '../api/templates';
import { getSetting } from '../api/settings';
import { useAuth } from '../context/AuthContext';
import TemplateSelectorModal from '../components/TemplateSelectorModal';
import Loader from '../components/Loader';

export default function GenerateDocumentPage() {
  const { csrfToken } = useAuth();
  const [selectedTemplate, setSelectedTemplate] = useState(null);
  const [templateFields, setTemplateFields] = useState([]);
  const [fieldValues, setFieldValues] = useState({});
  const [placeholderDescriptions, setPlaceholderDescriptions] = useState({});
  const [outputFormat, setOutputFormat] = useState('docx');
  const [filenameTemplate, setFilenameTemplate] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isTemplateModalOpen, setIsTemplateModalOpen] = useState(false);
  const [helpInfo, setHelpInfo] = useState('');
  const [contractHelpInfo, setContractHelpInfo] = useState('');

  // Загружаем информационные поля при загрузке компонента
  useEffect(() => {
    const loadHelpInfo = async () => {
      // Безопасная загрузка настроек с обработкой ошибок
      const loadSettingSafely = async (key) => {
        try {
          const response = await getSetting(key);
          if (response.data && response.data.value) {
            return response.data.value;
          }
        } catch (error) {
          console.log(`Setting '${key}' not found or error loading:`, error);
        }
        return null;
      };

      // Загружаем настройки параллельно
      const [generalInfo, contractInfo] = await Promise.all([
        loadSettingSafely('document_help_info'),
        loadSettingSafely('contract_help_info')
      ]);

      if (generalInfo) setHelpInfo(generalInfo);
      if (contractInfo) setContractHelpInfo(contractInfo);
    };
    
    loadHelpInfo();
  }, []);

  const handleTemplateSelect = async (template) => {
    setSelectedTemplate(template);
    setLoading(true);
    setError('');
    try {
      const fields = await getTemplateFields(template.id);
      setTemplateFields(fields);
      
      // Инициализируем значения полей
      const initialValues = {};
      const descriptions = {};
      fields.forEach(field => {
        initialValues[field.name] = '';
        if (field.description) {
          descriptions[field.name] = field.description;
        }
      });
      setFieldValues(initialValues);
      setPlaceholderDescriptions(descriptions);
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
      const blob = await generateDocument(selectedTemplate.id, fieldValues, outputFormat, filenameTemplate);
      
      // Создаем ссылку для скачивания
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      
      // Используем кастомное название файла или генерируем стандартное
      let downloadFilename;
      if (filenameTemplate) {
        // Заменяем плейсхолдеры в названии файла
        let customName = filenameTemplate;
        Object.entries(fieldValues).forEach(([key, value]) => {
          const placeholder = `{{${key}}}`;
          customName = customName.replace(new RegExp(placeholder, 'g'), value || '');
        });
        // Убираем недопустимые символы
        customName = customName.replace(/[<>:"/\\|?*]/g, '_').trim();
        downloadFilename = customName;
      } else {
        const baseName = selectedTemplate.filename.replace('.docx', '');
        const extension = outputFormat === 'pdf' ? '.pdf' : '.docx';
        downloadFilename = `generated_${baseName}${extension}`;
      }
      
      a.download = downloadFilename;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
      
      setSuccess('Документ сгенерирован и скачан');
    } catch (error) {
      console.error('Error generating document:', error);
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

  // Функция для определения, является ли шаблон договором
  const isContractTemplate = (template) => {
    if (!template) return false;
    const filename = template.filename.toLowerCase();
    return filename.includes('договор') || filename.includes('contract') || filename.includes('agreement');
  };

  return (
    <div className="generate-document-page">
      <div className="container">
        <h1>Создание документа из шаблона</h1>
        {error && <div className="auth-error">{error}</div>}
        {success && <div className="auth-success">{success}</div>}
        
        {/* Информационные поля */}
        {helpInfo && (
          <div className="help-info-section">
            <div className="help-info-header">
              <span className="help-icon">💡</span>
              <strong>Общая информация для заполнения документов</strong>
            </div>
            <div className="help-info-content">
              {helpInfo}
            </div>
          </div>
        )}
        
        {/* Специфичная информация для договоров */}
        {selectedTemplate && isContractTemplate(selectedTemplate) && contractHelpInfo && (
          <div className="help-info-section contract-help">
            <div className="help-info-header">
              <span className="help-icon">📋</span>
              <strong>Специальные требования для договоров</strong>
            </div>
            <div className="help-info-content">
              {contractHelpInfo}
            </div>
          </div>
        )}
        
        <div className="document-generation-layout">
          {/* Левая панель - выбор шаблона */}
          <div className="template-selection-panel">
            <h3>Выбор шаблона</h3>
            
            <div className="form-group">
              <label>Шаблон:</label>
              <div className="template-selector">
                {selectedTemplate ? (
                  <div className="selected-template">
                    <span className="template-icon">📄</span>
                    <span className="template-name">{selectedTemplate.filename}</span>
                    <button 
                      className="btn btn-secondary btn-small"
                      onClick={() => setIsTemplateModalOpen(true)}
                    >
                      Изменить
                    </button>
                  </div>
                ) : (
                  <button 
                    className="btn btn-primary"
                    onClick={() => setIsTemplateModalOpen(true)}
                  >
                    Выбрать шаблон
                  </button>
                )}
              </div>
            </div>

            {loading && <Loader text="Загрузка полей шаблона..." />}
          </div>

          {/* Правая панель - заполнение полей */}
          {selectedTemplate && (
            <div className="field-filling-panel">
              <h3>Заполнение данных</h3>
              <div className="selected-template-info">
                <strong>Выбранный шаблон:</strong> {selectedTemplate.filename}
              </div>
              
              {templateFields.length > 0 ? (
                <form onSubmit={handleGenerateDocument} className="field-form">
                  {templateFields.map(field => (
                    <div key={field.name} className="form-group">
                      <label className="field-label">
                        {field.name}
                        {field.description && (
                          <span 
                            className="field-help-icon" 
                            title={field.description}
                          >
                            ❓
                          </span>
                        )}
                      </label>
                      <input
                        type="text"
                        value={fieldValues[field.name] || ''}
                        onChange={e => handleFieldChange(field.name, e.target.value)}
                        className="form-control"
                        placeholder={`Введите значение для ${field.name}`}
                        required
                      />
                      {field.description && (
                        <small className="field-description">
                          {field.description}
                        </small>
                      )}
                    </div>
                  ))}
                  
                  <div className="form-group">
                    <label>Шаблон названия файла (необязательно):</label>
                    <input
                      type="text"
                      value={filenameTemplate}
                      onChange={e => setFilenameTemplate(e.target.value)}
                      className="form-control"
                      placeholder="Например: Договор_{{номер_договора}}_{{ФИО}}"
                    />
                    <small className="form-help">
                      Используйте плейсхолдеры в формате {'{{поле}}'} для автоматического формирования названия файла
                    </small>
                  </div>
                  
                  <div className="form-group">
                    <label>Формат документа:</label>
                    <div className="radio-options">
                      <label className="radio-option">
                        <input
                          type="radio"
                          value="docx"
                          checked={outputFormat === 'docx'}
                          onChange={e => setOutputFormat(e.target.value)}
                        />
                        <span>DOCX (Word)</span>
                      </label>
                      <label className="radio-option">
                        <input
                          type="radio"
                          value="pdf"
                          checked={outputFormat === 'pdf'}
                          onChange={e => setOutputFormat(e.target.value)}
                        />
                        <span>PDF</span>
                      </label>
                    </div>
                  </div>
                  
                  <button 
                    type="submit" 
                    disabled={loading}
                    className="btn btn-primary btn-large"
                  >
                    {loading ? 'Генерация...' : 'Создать документ'}
                  </button>
                </form>
              ) : (
                <div className="no-fields-message">
                  В выбранном шаблоне не найдено полей для заполнения.
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Модальное окно выбора шаблона */}
      <TemplateSelectorModal
        isOpen={isTemplateModalOpen}
        onClose={() => setIsTemplateModalOpen(false)}
        onSelect={handleTemplateSelect}
        selectedTemplateId={selectedTemplate?.id}
      />
    </div>
  );
} 