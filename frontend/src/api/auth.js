import axios from 'axios';

// Определяем API_URL в зависимости от окружения
const API_URL = process.env.REACT_APP_API_URL || 
  (process.env.NODE_ENV === 'development' ? 'http://localhost:8000' : '/api');

export async function login(username, password) {
  try {
    const res = await axios.post(`${API_URL}/auth/login`, {
      username,
      password
    }, {
      withCredentials: true
    });
    
    if (res.data.access_token) {
      localStorage.setItem('token', res.data.access_token);
      localStorage.setItem('user', JSON.stringify(res.data.user));
    }
    
    return res.data;
  } catch (error) {
    console.error('Login error:', error);
    throw error;
  }
}

export async function register(username, email, password) {
  try {
    const res = await axios.post(`${API_URL}/auth/register`, {
      username,
      email,
      password
    }, {
      withCredentials: true
    });
    return res.data;
  } catch (error) {
    console.error('Registration error:', error);
    throw error;
  }
}

export async function logout() {
  try {
    await axios.post(`${API_URL}/auth/logout`, {}, {
      withCredentials: true
    });
  } catch (error) {
    console.error('Logout error:', error);
  } finally {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  }
}

export async function getMe() {
  try {
    const res = await axios.get(`${API_URL}/auth/me`, {
      withCredentials: true
    });
    return res.data;
  } catch (error) {
    console.error('Error getting user info:', error);
    throw error;
  }
}

export async function getCSRFToken() {
  try {
    const res = await axios.get(`${API_URL}/auth/csrf-token`, {
      withCredentials: true
    });
    return res.data.csrf_token;
  } catch (error) {
    console.error('Error getting CSRF token:', error);
    throw error;
  }
}

export async function activateUser(userId) {
  try {
    const res = await axios.post(`${API_URL}/auth/activate-user`, {
      user_id: userId
    }, {
      withCredentials: true
    });
    return res.data;
  } catch (error) {
    console.error('Error activating user:', error);
    throw error;
  }
} 