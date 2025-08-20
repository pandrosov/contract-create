import api from './axiosConfig';

export async function getSettings() {
  try {
    const res = await api.get('/settings/');
    return res;
  } catch (error) {
    console.error('Error fetching settings:', error);
    throw error;
  }
}

export async function getSetting(key) {
  try {
    const res = await api.get(`/settings/${key}`);
    return res;
  } catch (error) {
    console.error('Error fetching setting:', error);
    throw error;
  }
}

export async function createSetting(setting) {
  try {
    const res = await api.post('/settings/', setting);
    return res;
  } catch (error) {
    console.error('Error creating setting:', error);
    throw error;
  }
}

export async function updateSetting(key, setting) {
  try {
    const res = await api.put(`/settings/${key}`, setting);
    return res;
  } catch (error) {
    console.error('Error updating setting:', error);
    throw error;
  }
}

export async function deleteSetting(key) {
  try {
    const res = await api.delete(`/settings/${key}`);
    return res;
  } catch (error) {
    console.error('Error deleting setting:', error);
    throw error;
  }
} 