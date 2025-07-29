import axios from 'axios';
import { getCSRFToken } from './auth';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

export async function getFolders() {
  try {
    const res = await axios.get(`${API_URL}/folders/`, { withCredentials: true });
    return res.data || [];
  } catch (error) {
    console.error('Error fetching folders:', error);
    throw error;
  }
}

export async function createFolder(data) {
  try {
    const csrfToken = await getCSRFToken();
    const res = await axios.post(`${API_URL}/folders/`, data, {
      withCredentials: true,
      headers: { 'X-CSRF-Token': csrfToken }
    });
    return res.data;
  } catch (error) {
    console.error('Error creating folder:', error);
    throw error;
  }
}

export async function deleteFolder(folder_id) {
  try {
    const csrfToken = await getCSRFToken();
    await axios.delete(`${API_URL}/folders/${folder_id}`, {
      withCredentials: true,
      headers: { 'X-CSRF-Token': csrfToken }
    });
  } catch (error) {
    console.error('Error deleting folder:', error);
    throw error;
  }
} 