import axios from 'axios';
import { getCSRFToken } from './auth';

// Определяем API_URL в зависимости от окружения
const API_URL = process.env.REACT_APP_API_URL || 
  (process.env.NODE_ENV === 'development' ? 'http://localhost:8000' : '/api');

export async function getTemplatesByFolder(folderId) {
  try {
    const res = await axios.get(`${API_URL}/templates/folder/${folderId}`, {
      withCredentials: true
    });
    return res.data.data || [];
  } catch (error) {
    console.error('Error fetching templates:', error);
    throw error;
  }
}

export async function getTemplates() {
  try {
    const res = await axios.get(`${API_URL}/templates/`, {
      withCredentials: true
    });
    return res.data.data || [];
  } catch (error) {
    console.error('Error fetching all templates:', error);
    throw error;
  }
}

export async function uploadTemplate(file, folder_id) {
  try {
    const csrfToken = await getCSRFToken();
    const formData = new FormData();
    formData.append('file', file);
    formData.append('folder_id', folder_id);

    const res = await axios.post(`${API_URL}/templates/upload`, formData, {
      withCredentials: true,
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'multipart/form-data'
      }
    });
    return res.data;
  } catch (error) {
    console.error('Error uploading template:', error);
    throw error;
  }
}

export async function deleteTemplate(templateId) {
  try {
    const csrfToken = await getCSRFToken();
    const res = await axios.delete(`${API_URL}/templates/${templateId}`, {
      withCredentials: true,
      headers: { 'X-CSRF-Token': csrfToken }
    });
    return res.data; // Assuming backend returns a success message
  } catch (error) {
    console.error('Error deleting template:', error);
    throw error;
  }
}

export async function getTemplateFields(templateId) {
  try {
    const res = await axios.get(`${API_URL}/templates/${templateId}/fields`, { // No CSRF for GET
      withCredentials: true
    });
    return res.data.data || [];
  } catch (error) {
    console.error('Error fetching template fields:', error);
    throw error;
  }
}

export async function generateDocument(templateId, values, outputFormat = 'docx', filenameTemplate = '') {
  try {
    const csrfToken = await getCSRFToken();
    const formData = new FormData();
    formData.append('values', JSON.stringify(values));
    formData.append('output_format', outputFormat);
    if (filenameTemplate) {
      formData.append('filename_template', filenameTemplate);
    }

    const res = await axios.post(`${API_URL}/templates/${templateId}/generate`, formData, {
      withCredentials: true,
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'multipart/form-data'
      },
      responseType: 'blob'
    });
    return res.data;
  } catch (error) {
    console.error('Error generating document:', error);
    throw error;
  }
} 

// Новые функции для работы с описаниями плейсхолдеров
export async function getPlaceholderDescriptions(templateId) {
  try {
    const res = await axios.get(`${API_URL}/templates/${templateId}/placeholder-descriptions`, {
      withCredentials: true,
    });
    console.log('Raw API response:', res.data);
    return res.data.data || {};
  } catch (error) {
    console.error('Error fetching placeholder descriptions:', error);
    throw error;
  }
}

export async function createPlaceholderDescription(templateId, placeholderName, description) {
  try {
    const formData = new FormData();
    formData.append('placeholder_name', placeholderName);
    formData.append('description', description);

    const res = await axios.post(`${API_URL}/templates/${templateId}/placeholder-descriptions`, formData, {
      withCredentials: true,
    });
    return res.data;
  } catch (error) {
    console.error('Error creating placeholder description:', error);
    throw error;
  }
}

export async function deletePlaceholderDescription(templateId, placeholderName) {
  try {
    const res = await axios.delete(`${API_URL}/templates/${templateId}/placeholder-descriptions/${encodeURIComponent(placeholderName)}`, {
      withCredentials: true,
    });
    return res.data;
  } catch (error) {
    console.error('Error deleting placeholder description:', error);
    throw error;
  }
}

 