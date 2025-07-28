import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || '';

export async function getPermissionsForUser(user_id) {
  try {
    const res = await axios.get(`${API_URL}/permissions/user/${user_id}`, { withCredentials: true });
    return res.data || [];
  } catch (error) {
    console.error('Error fetching permissions:', error);
    throw error;
  }
}

export async function setPermission(data, csrfToken) {
  try {
    const res = await axios.post(`${API_URL}/permissions`, data, {
      withCredentials: true,
      headers: { 'X-CSRF-Token': csrfToken }
    });
    return res.data;
  } catch (error) {
    console.error('Error setting permission:', error);
    throw error;
  }
} 