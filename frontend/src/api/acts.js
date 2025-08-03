import axios from 'axios';

const API_URL = process.env.NODE_ENV === 'development' 
  ? 'http://localhost:8000' 
  : '/api';

const actsApi = {
  // Анализ Excel файла и получение столбцов
  analyzeExcelFile: async (file) => {
    const formData = new FormData();
    formData.append('file', file);
    
    const response = await axios.post(`${API_URL}/acts/analyze-excel`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      withCredentials: true,
    });
    return response;
  },

  // Анализ качества данных
  analyzeDataQuality: async (file) => {
    const formData = new FormData();
    formData.append('file', file);
    
    const response = await axios.post(`${API_URL}/acts/analyze-data-quality`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      withCredentials: true,
    });
    return response;
  },

  // Валидация маппинга
  validateMapping: async (file, mapping) => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('mapping', JSON.stringify(mapping));
    
    const response = await axios.post(`${API_URL}/acts/validate-mapping`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      withCredentials: true,
    });
    return response;
  },

  // Получение плейсхолдеров из шаблона
  getTemplatePlaceholders: async (templateId) => {
    const response = await axios.get(`${API_URL}/acts/template-placeholders/${templateId}`, {
      withCredentials: true,
    });
    return response;
  },

  // Генерация актов
  generateActs: async (formData) => {
    const response = await axios.post(`${API_URL}/acts/generate`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      responseType: 'blob',
      withCredentials: true,
    });
    return response;
  },

  // Получение статуса генерации
  getGenerationStatus: async (taskId) => {
    const response = await axios.get(`${API_URL}/acts/generation-status/${taskId}`, {
      withCredentials: true,
    });
    return response;
  },
};

export default actsApi;
export const { 
  analyzeExcelFile, 
  analyzeDataQuality, 
  validateMapping, 
  getTemplatePlaceholders, 
  generateActs, 
  getGenerationStatus 
} = actsApi; 