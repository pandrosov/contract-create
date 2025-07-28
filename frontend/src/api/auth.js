import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

export async function login(username, password) {
  try {
    const form = new FormData();
    form.append('username', username);
    form.append('password', password);
    const res = await axios.post(`${API_URL}/auth/token`, form, {
      withCredentials: true,
    });
    return res.headers['x-csrf-token'] || '';
  } catch (error) {
    console.error('Error during login:', error);
    throw error;
  }
}

export async function register(username, email, password) {
  try {
    await axios.post(`${API_URL}/auth/register`, { username, email, password }, {
      withCredentials: true,
    });
  } catch (error) {
    console.error('Error during registration:', error);
    throw error;
  }
}

export async function logout() {
  try {
    await axios.post(`${API_URL}/auth/logout`, {}, {
      withCredentials: true,
    });
  } catch (error) {
    console.error('Error during logout:', error);
    throw error;
  }
}

export async function getMe() {
  try {
    const res = await axios.get(`${API_URL}/auth/me`, {
      withCredentials: true,
    });
    return res.data || null;
  } catch (error) {
    console.error('Error fetching user data:', error);
    throw error;
  }
} 