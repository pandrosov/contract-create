import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { uploadTemplate, getTemplates } from '../api/templates';
import { generateActs, analyzeExcelFile, analyzeDataQuality, validateMapping, getTemplatePlaceholders, getColumnValues } from '../api/acts';
import TemplateSelectorModal from '../components/TemplateSelectorModal';
import Loader from '../components/Loader';
import '../styles/global.css';

const ActGenerationPage = () => {
  const { user } = useAuth();
  const [templates, setTemplates] = useState([]);
  const [selectedTemplate, setSelectedTemplate] = useState(null);
  const [excelFile, setExcelFile] = useState(null);
  const [filters, setFilters] = useState([{ column: '', value: '' }]);
  const [availableColumns, setAvailableColumns] = useState([]);
  const [columnValues, setColumnValues] = useState({});
  const [placeholders, setPlaceholders] = useState([]);
  const [mapping, setMapping] = useState({});
  const [freeInputMapping, setFreeInputMapping] = useState({}); // Новое состояние для свободного ввода
  const [outputFormat, setOutputFormat] = useState('docx');
  const [outputFilename, setOutputFilename] = useState('');
  const [actFilenameTemplate, setActFilenameTemplate] = useState('');
  const [numberToTextFields, setNumberToTextFields] = useState([]);
  const [currency, setCurrency] = useState('белорусских рубля');
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [messageType, setMessageType] = useState('');
  const [dataAnalysis, setDataAnalysis] = useState(null);
  const [mappingValidation, setMappingValidation] = useState(null);
  const [isTemplateModalOpen, setIsTemplateModalOpen] = useState(false);

  useEffect(() => {
    loadTemplates();
  }, []);

  const loadTemplates = async () => {
    try {
      const response = await getTemplates();
      setTemplates(response.data);
    } catch (error) {
      console.error('Error loading templates:', error);
      showMessage('Ошибка загрузки шаблонов', 'error');
    }
  };

  const handleTemplateSelect = async (template) => {
    setSelectedTemplate(template);
    try {
      const response = await getTemplatePlaceholders(template.id);
      setPlaceholders(response.data.placeholders);
      setMapping({});
    } catch (error) {
      console.error('Error extracting placeholders:', error);
      showMessage('Ошибка извлечения плейсхолдеров', 'error');
    }
  };

  const handleExcelUpload = async (event) => {
    const file = event.target.files[0];
    if (file) {
      setExcelFile(file);
      setIsLoading(true);
      
      try {
        // Анализируем структуру Excel файла
        const response = await analyzeExcelFile(file);
        
        if (response.data && response.data.columns) {
          setAvailableColumns(response.data.columns);
          
          // Получаем уникальные значения для всех столбцов
          const columnValuesResponse = await getColumnValues(file);
          
          if (columnValuesResponse.data && columnValuesResponse.data.column_values) {
            setColumnValues(columnValuesResponse.data.column_values);
          } else {
            console.error('Invalid column values response:', columnValuesResponse.data);
            showMessage('Ошибка получения значений столбцов', 'error');
            return;
          }
        } else {
          console.error('Invalid Excel analysis response:', response.data);
          showMessage('Ошибка анализа структуры Excel файла', 'error');
          return;
        }
        
        // Анализируем качество данных
        const qualityResponse = await analyzeDataQuality(file);
        
        if (qualityResponse.data && qualityResponse.data.analysis) {
          setDataAnalysis(qualityResponse.data.analysis);
        } else if (qualityResponse.data && qualityResponse.data.total_rows) {
          // Если данные приходят напрямую (без вложенности analysis)
          setDataAnalysis(qualityResponse.data);
        } else {
          console.error('Invalid data quality response:', qualityResponse.data);
          showMessage('Ошибка анализа качества данных', 'error');
        }
        
        showMessage('Файл успешно загружен и проанализирован', 'success');
      } catch (error) {
        console.error('Error analyzing Excel file:', error);
        showMessage('Ошибка анализа Excel файла', 'error');
      } finally {
        setIsLoading(false);
      }
    }
  };

  const addFilter = () => {
    setFilters([...filters, { column: '', value: '' }]);
  };

  const removeFilter = (index) => {
    if (filters.length > 1) {
      const newFilters = filters.filter((_, i) => i !== index);
      setFilters(newFilters);
    }
  };

  const updateFilter = (index, field, value) => {
    const newFilters = [...filters];
    newFilters[index][field] = value;
    setFilters(newFilters);
  };

  const handleMappingChange = (placeholder, column) => {
    const newMapping = {
      ...mapping,
      [placeholder]: column
    };
    setMapping(newMapping);
    
    // Очищаем свободный ввод для этого плейсхолдера
    const newFreeInputMapping = { ...freeInputMapping };
    delete newFreeInputMapping[placeholder];
    setFreeInputMapping(newFreeInputMapping);
    
    // Валидируем маппинг, если есть файл
    if (excelFile && Object.keys(newMapping).length > 0) {
      validateMappingWithData(newMapping);
    }
  };

  const handleFreeInputChange = (placeholder, value) => {
    const newFreeInputMapping = {
      ...freeInputMapping,
      [placeholder]: value
    };
    setFreeInputMapping(newFreeInputMapping);
    
    // Очищаем маппинг столбца для этого плейсхолдера
    const newMapping = { ...mapping };
    delete newMapping[placeholder];
    setMapping(newMapping);
  };

  const handleFreeInputToggle = (placeholder, isFreeInput) => {
    if (isFreeInput) {
      // Переключаемся на свободный ввод
      const newMapping = { ...mapping };
      delete newMapping[placeholder];
      setMapping(newMapping);
      
      // Инициализируем свободный ввод пустым значением
      setFreeInputMapping({
        ...freeInputMapping,
        [placeholder]: ''
      });
    } else {
      // Переключаемся на выбор столбца
      const newFreeInputMapping = { ...freeInputMapping };
      delete newFreeInputMapping[placeholder];
      setFreeInputMapping(newFreeInputMapping);
    }
  };

  const validateMappingWithData = async (mappingToValidate) => {
    try {
      const response = await validateMapping(excelFile, mappingToValidate);
      console.log('Validation response:', response.data);
      
      if (response.data && response.data.validation) {
        setMappingValidation(response.data.validation);
        
        if (!response.data.validation.valid) {
          showMessage('Обнаружены ошибки в маппинге', 'error');
        } else if (response.data.validation.warnings && response.data.validation.warnings.length > 0) {
          showMessage('Обнаружены предупреждения в маппинге', 'warning');
        }
      } else {
        console.error('Invalid validation response structure:', response.data);
        showMessage('Ошибка валидации маппинга', 'error');
      }
    } catch (error) {
      console.error('Error validating mapping:', error);
      showMessage('Ошибка валидации маппинга', 'error');
    }
  };

  const handleGenerateActs = async () => {
    if (!selectedTemplate || !excelFile || filters.some(f => !f.column || !f.value)) {
      showMessage('Пожалуйста, заполните все обязательные поля', 'error');
      return;
    }

    // Проверяем, что есть маппинг или свободный ввод для плейсхолдеров
    const hasMapping = Object.keys(mapping).length > 0;
    const hasFreeInput = Object.keys(freeInputMapping).length > 0;
    
    if (placeholders.length > 0 && !hasMapping && !hasFreeInput) {
      showMessage('Пожалуйста, настройте маппинг плейсхолдеров или введите значения', 'error');
      return;
    }

    setIsLoading(true);
    try {
      const formData = new FormData();
      formData.append('template_id', selectedTemplate.id);
      formData.append('excel_file', excelFile);
      
      // Добавляем фильтры
      filters.forEach((filter, index) => {
        formData.append(`filter_column_${index}`, filter.column);
        formData.append(`filter_value_${index}`, filter.value);
      });
      
      // Объединяем маппинг и свободный ввод
      const combinedMapping = { ...mapping };
      Object.keys(freeInputMapping).forEach(placeholder => {
        if (freeInputMapping[placeholder]) {
          combinedMapping[placeholder] = freeInputMapping[placeholder];
        }
      });
      
      formData.append('mapping', JSON.stringify(combinedMapping));
      formData.append('output_format', outputFormat);
      if (outputFilename) {
        formData.append('output_filename', outputFilename);
      }
      if (actFilenameTemplate) {
        formData.append('act_filename_template', actFilenameTemplate);
      }
      if (numberToTextFields.length > 0) {
        formData.append('number_to_text_fields', JSON.stringify(numberToTextFields));
      }
      formData.append('currency', currency);

      const response = await generateActs(formData);
      
      // Скачивание архива
      const blob = new Blob([response.data], { type: 'application/zip' });
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      
      // Используем кастомное название файла или стандартное
      const filename = outputFilename 
        ? `${outputFilename.replace(/[<>:"/\\|?*]/g, '_').trim()}.zip`
        : 'generated_acts.zip';
      
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);

      showMessage('Акты успешно сгенерированы!', 'success');
    } catch (error) {
      console.error('Error generating acts:', error);
      showMessage('Ошибка генерации актов', 'error');
    } finally {
      setIsLoading(false);
    }
  };

  const addNumberToTextField = (field) => {
    if (!numberToTextFields.includes(field)) {
      setNumberToTextFields([...numberToTextFields, field]);
    }
  };

  const removeNumberToTextField = (field) => {
    setNumberToTextFields(numberToTextFields.filter(f => f !== field));
  };

  const showMessage = (text, type) => {
    setMessage(text);
    setMessageType(type);
    setTimeout(() => setMessage(''), 5000);
  };

  return (
    <div className="act-generation-page">
      <div className="container">
        <h1>Генерация актов</h1>
        
        {message && (
          <div className={`message ${messageType}`}>
            {message}
          </div>
        )}

        <div className="generation-form">
          {/* Шаг 1: Выбор шаблона */}
          <div className="form-section">
            <h3>1. Выбор шаблона</h3>
            <div className="form-group">
              <label>Выберите шаблон акта:</label>
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
          </div>

          {/* Шаг 2: Загрузка Excel файла */}
          <div className="form-section">
            <h3>2. Загрузка данных</h3>
            <div className="file-upload-container">
              <div className="file-upload-area">
                <div className="file-upload-icon">📊</div>
                <div className="file-upload-text">
                  <strong>Загрузите Excel файл с данными</strong>
                  <p>Поддерживаются форматы .xlsx и .xls</p>
                </div>
                <input
                  type="file"
                  accept=".xlsx,.xls"
                  onChange={handleExcelUpload}
                  className="file-input"
                  id="excel-file-input"
                />
                <label htmlFor="excel-file-input" className="file-upload-button">
                  Выбрать файл
                </label>
              </div>
              {excelFile && (
                <div className="file-info">
                  <span className="file-icon">📄</span>
                  <span className="file-name">{excelFile.name}</span>
                  <span className="file-size">({(excelFile.size / 1024 / 1024).toFixed(2)} МБ)</span>
                </div>
              )}
            </div>
            
            {/* Анализ данных */}
            {dataAnalysis && (
              <div className="data-analysis">
                <h4>📊 Анализ данных</h4>
                
                {/* Основная статистика */}
                <div className="analysis-grid">
                  <div className="analysis-item">
                    <strong>📈 Всего строк:</strong> {dataAnalysis.total_rows || dataAnalysis.analysis?.total_rows || 0}
                  </div>
                  <div className="analysis-item">
                    <strong>📋 Всего столбцов:</strong> {dataAnalysis.total_columns || dataAnalysis.analysis?.total_columns || 0}
                  </div>
                  <div className="analysis-item">
                    <strong>💾 Размер файла:</strong> {dataAnalysis.memory_usage_mb ? `${dataAnalysis.memory_usage_mb.toFixed(2)} МБ` : dataAnalysis.analysis?.memory_usage_mb ? `${dataAnalysis.analysis.memory_usage_mb.toFixed(2)} МБ` : 'N/A'}
                  </div>
                  <div className="analysis-item">
                    <strong>🔄 Дубликаты:</strong> {dataAnalysis.duplicate_rows || dataAnalysis.analysis?.duplicate_rows || 0}
                  </div>
                </div>
                
                {/* Пустые значения */}
                {(dataAnalysis.missing_data || dataAnalysis.analysis?.missing_data) && 
                 Object.values(dataAnalysis.missing_data || dataAnalysis.analysis?.missing_data || {}).some(count => count > 0) && (
                  <div className="missing-data-warning">
                    <strong>⚠️ Пустые значения:</strong>
                    <div className="missing-data-list">
                      {Object.entries(dataAnalysis.missing_data || dataAnalysis.analysis?.missing_data || {})
                        .filter(([col, count]) => count > 0)
                        .sort(([,a], [,b]) => b - a) // Сортируем по убыванию
                        .map(([col, count]) => (
                          <div key={col} className="missing-data-item">
                            <span className="column-name">{col}</span>
                            <span className="missing-count">{count} пустых</span>
                            <span className="missing-percentage">
                              ({((count / (dataAnalysis.total_rows || dataAnalysis.analysis?.total_rows || 1)) * 100).toFixed(1)}%)
                            </span>
                          </div>
                        ))}
                    </div>
                  </div>
                )}
                
                {/* Статистика по типам данных */}
                {(dataAnalysis.column_types || dataAnalysis.analysis?.column_types) && (
                  <div className="data-types-analysis">
                    <strong>📊 Типы данных:</strong>
                    <div className="data-types-grid">
                      {Object.entries(dataAnalysis.column_types || dataAnalysis.analysis?.column_types || {}).map(([col, type]) => (
                        <div key={col} className="data-type-item">
                          <span className="column-name">{col}</span>
                          <span className="data-type">{type}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
                
                {/* Числовая статистика */}
                {(dataAnalysis.numeric_stats || dataAnalysis.analysis?.numeric_stats) && 
                 Object.keys(dataAnalysis.numeric_stats || dataAnalysis.analysis?.numeric_stats || {}).length > 0 && (
                  <div className="numeric-stats">
                    <strong>📈 Числовая статистика:</strong>
                    <div className="numeric-stats-grid">
                      {Object.entries(dataAnalysis.numeric_stats || dataAnalysis.analysis?.numeric_stats || {}).map(([col, stats]) => (
                        <div key={col} className="numeric-stat-item">
                          <strong>{col}:</strong>
                          <div className="stat-details">
                            {stats.mean !== null && <span>Среднее: {Number(stats.mean).toFixed(2)}</span>}
                            {stats.min !== null && <span>Мин: {Number(stats.min).toFixed(2)}</span>}
                            {stats.max !== null && <span>Макс: {Number(stats.max).toFixed(2)}</span>}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Шаг 3: Настройка фильтров */}
          {excelFile && availableColumns && availableColumns.length > 0 && (
            <div className="form-section">
              <h3>3. Настройка фильтров</h3>
              <div className="filters-container">
                {filters.map((filter, index) => (
                  <div key={index} className="filter-row">
                    <div className="filter-column">
                      <label>Столбец для фильтрации:</label>
                      <select 
                        value={filter.column} 
                        onChange={(e) => updateFilter(index, 'column', e.target.value)}
                        className="form-control"
                      >
                        <option value="">Выберите столбец...</option>
                        {availableColumns && availableColumns.map(column => (
                          <option key={column} value={column}>
                            {column}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div className="filter-value">
                      <label>Значение для фильтрации:</label>
                      {filter.column && columnValues && columnValues[filter.column] && columnValues[filter.column].length > 0 ? (
                        <select
                          value={filter.value}
                          onChange={(e) => updateFilter(index, 'value', e.target.value)}
                          className="form-control"
                        >
                          <option value="">Выберите значение...</option>
                          {columnValues[filter.column].map(value => (
                            <option key={value} value={value}>
                              {value}
                            </option>
                          ))}
                        </select>
                      ) : (
                        <input
                          type="text"
                          value={filter.value}
                          onChange={(e) => updateFilter(index, 'value', e.target.value)}
                          placeholder="Введите значение..."
                          className="form-control"
                        />
                      )}
                    </div>
                    {filters.length > 1 && (
                      <button
                        type="button"
                        onClick={() => removeFilter(index)}
                        className="btn btn-danger btn-small"
                      >
                        ✕
                      </button>
                    )}
                  </div>
                ))}
                <button
                  type="button"
                  onClick={addFilter}
                  className="btn btn-secondary"
                >
                  + Добавить фильтр
                </button>
              </div>
              
              {/* Валидация маппинга */}
              {mappingValidation && (
                <div className="mapping-validation">
                  <h4>🔍 Валидация маппинга</h4>
                  
                  {mappingValidation.errors && mappingValidation.errors.length > 0 && (
                    <div className="validation-errors">
                      <strong>❌ Ошибки:</strong>
                      <ul>
                        {mappingValidation.errors.map((error, index) => (
                          <li key={index}>{error}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                  
                  {mappingValidation.warnings && mappingValidation.warnings.length > 0 && (
                    <div className="validation-warnings">
                      <strong>⚠️ Предупреждения:</strong>
                      <ul>
                        {mappingValidation.warnings.map((warning, index) => (
                          <li key={index}>{warning}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                  
                  {mappingValidation.valid && (
                    <div className="validation-success">
                      <strong>✅ Маппинг корректен</strong>
                      <p>Используется {mappingValidation.mapped_columns?.length || 0} из {availableColumns?.length || 0} столбцов</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {/* Шаг 4: Настройка маппинга */}
          {placeholders && placeholders.length > 0 && availableColumns && availableColumns.length > 0 && (
            <div className="form-section">
              <h3>4. Настройка маппинга</h3>
              <p>Сопоставьте плейсхолдеры шаблона со столбцами таблицы или введите произвольные значения:</p>
              <div className="mapping-container">
                {placeholders && placeholders.map(placeholder => {
                  const isFreeInput = freeInputMapping.hasOwnProperty(placeholder);
                  const hasColumnMapping = mapping.hasOwnProperty(placeholder);
                  
                  return (
                    <div key={placeholder} className="mapping-row">
                      <div className="placeholder">
                        <strong>{placeholder}</strong>
                      </div>
                      <div className="mapping-arrow">→</div>
                      
                      {/* Галочка для переключения режима */}
                      <div className="free-input-toggle">
                        <label className="checkbox-option">
                          <input
                            type="checkbox"
                            checked={isFreeInput}
                            onChange={(e) => handleFreeInputToggle(placeholder, e.target.checked)}
                          />
                          <span>Свободный ввод</span>
                        </label>
                      </div>
                      
                      <div className="column-select">
                        {isFreeInput ? (
                          <input
                            type="text"
                            value={freeInputMapping[placeholder] || ''}
                            onChange={(e) => handleFreeInputChange(placeholder, e.target.value)}
                            placeholder="Введите значение..."
                            className="form-control"
                          />
                        ) : (
                          <select
                            value={mapping[placeholder] || ''}
                            onChange={(e) => handleMappingChange(placeholder, e.target.value)}
                            className="form-control"
                          >
                            <option value="">Выберите столбец...</option>
                            {availableColumns && availableColumns.map(column => (
                              <option key={column} value={column}>
                                {column}
                              </option>
                            ))}
                          </select>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Шаг 5: Выбор формата */}
          <div className="form-section">
            <h3>5. Формат выходных файлов</h3>
            <div className="form-group">
              <label>Выберите формат:</label>
              <div className="radio-options">
                <label className="radio-option">
                  <input
                    type="radio"
                    value="docx"
                    checked={outputFormat === 'docx'}
                    onChange={(e) => setOutputFormat(e.target.value)}
                  />
                  <span>DOCX</span>
                </label>
                <label className="radio-option">
                  <input
                    type="radio"
                    value="pdf"
                    checked={outputFormat === 'pdf'}
                    onChange={(e) => setOutputFormat(e.target.value)}
                  />
                  <span>PDF</span>
                </label>
              </div>
            </div>
          </div>

          {/* Настройка названия файла */}
          <div className="form-section">
            <h3>6. Настройка выгрузки</h3>
            <div className="form-group">
              <label>Название архива (необязательно):</label>
              <input
                type="text"
                value={outputFilename}
                onChange={e => setOutputFilename(e.target.value)}
                className="form-control"
                placeholder="Например: Акты_июнь_2024"
              />
              <small className="form-help">
                Если не указано, будет использовано стандартное название "generated_acts.zip"
              </small>
            </div>
            
            <div className="form-group">
              <label>Шаблон названия файлов актов (необязательно):</label>
              <input
                type="text"
                value={actFilenameTemplate}
                onChange={e => setActFilenameTemplate(e.target.value)}
                className="form-control"
                placeholder="Например: Акт_{{ФИО}}_{{номер_договора}}"
              />
              <small className="form-help">
                Используйте плейсхолдеры в формате {'{{поле}}'} для автоматического формирования названия каждого акта
              </small>
            </div>
          </div>

          {/* Настройка преобразования чисел в текст */}
          {availableColumns && availableColumns.length > 0 && (
            <div className="form-section">
              <h3>7. Преобразование чисел в текст</h3>
              
              <div className="form-group">
                <label>Валюта для расшифровки:</label>
                <input
                  type="text"
                  value={currency}
                  onChange={e => setCurrency(e.target.value)}
                  className="form-control"
                  placeholder="Например: белорусских рубля, российских рубля, долларов"
                />
                <small className="form-help">
                  Укажите валюту для расшифровки чисел (например: рублей, долларов, евро)
                </small>
              </div>
              
              <div className="form-group">
                <label>Выберите поля для преобразования чисел в текст:</label>
                <small className="form-help">
                  Числовые значения в выбранных полях будут преобразованы в текст с расшифровкой в скобках (например: 1574,56 → "1574,56 (Одна тысяча пятьсот семьдесят четыре белорусских рубля 56 копеек)")
                </small>
                <div className="number-to-text-fields">
                  {availableColumns.map(column => (
                    <div key={column} className="field-checkbox">
                      <label>
                        <input
                          type="checkbox"
                          checked={numberToTextFields.includes(column)}
                          onChange={(e) => {
                            if (e.target.checked) {
                              addNumberToTextField(column);
                            } else {
                              removeNumberToTextField(column);
                            }
                          }}
                        />
                        <span>{column}</span>
                      </label>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Кнопка генерации */}
          <div className="form-section">
            {isLoading ? (
              <Loader text="Генерация актов..." />
            ) : (
              <button
                onClick={handleGenerateActs}
                disabled={isLoading}
                className="btn btn-primary btn-large"
              >
                Сгенерировать акты
              </button>
            )}
          </div>
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
};

export default ActGenerationPage; 