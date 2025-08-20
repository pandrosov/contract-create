import axios from 'axios';

// Создаем экземпляр axios с базовой конфигурацией
const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || '/api',
  withCredentials: true,
});

// Добавляем interceptor для автоматического добавления JWT токена
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Добавляем interceptor для обработки ошибок аутентификации
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Если токен истек или недействителен, очищаем localStorage
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      // Можно добавить редирект на страницу логина
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
