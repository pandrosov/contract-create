import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

export async function getSettings() {
  try {
    const res = await axios.get(`${API_URL}/settings/`, {
      withCredentials: true,
    });
    return res;
  } catch (error) {
    console.error('Error fetching settings:', error);
    throw error;
  }
}

export async function getSetting(key) {
  try {
    const res = await axios.get(`${API_URL}/settings/${key}`, {
      withCredentials: true,
    });
    return res;
  } catch (error) {
    console.error('Error fetching setting:', error);
    throw error;
  }
}

export async function createSetting(setting) {
  try {
    const res = await axios.post(`${API_URL}/settings/`, setting, {
      withCredentials: true,
    });
    return res;
  } catch (error) {
    console.error('Error creating setting:', error);
    throw error;
  }
}

export async function updateSetting(key, setting) {
  try {
    const res = await axios.put(`${API_URL}/settings/${key}`, setting, {
      withCredentials: true,
    });
    return res;
  } catch (error) {
    console.error('Error updating setting:', error);
    throw error;
  }
}

export async function deleteSetting(key) {
  try {
    const res = await axios.delete(`${API_URL}/settings/${key}`, {
      withCredentials: true,
    });
    return res;
  } catch (error) {
    console.error('Error deleting setting:', error);
    throw error;
  }
} 