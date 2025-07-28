import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || '';

export async function getUsers() {
  try {
    const res = await axios.get(`${API_URL}/users`, { withCredentials: true });
    return res.data || [];
  } catch (error) {
    console.error('Error fetching users:', error);
    throw error;
  }
}

export async function activateUser(user_id, is_active, csrfToken) {
  try {
    await axios.post(
      `${API_URL}/auth/activate-user`,
      { user_id, is_active },
      {
        withCredentials: true,
        headers: { 'X-CSRF-Token': csrfToken }
      }
    );
  } catch (error) {
    console.error('Error activating user:', error);
    throw error;
  }
} 