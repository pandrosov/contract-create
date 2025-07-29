import React, { createContext, useContext, useState, useEffect } from 'react';
import * as authApi from '../api/auth';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Проверка авторизации при загрузке
  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    setLoading(true);
    try {
      // Сначала проверяем localStorage
      const storedUser = localStorage.getItem('user');
      if (storedUser) {
        const userData = JSON.parse(storedUser);
        setUser(userData);
      }
      
      // Затем проверяем сервер для актуальности данных
      const me = await authApi.getMe();
      setUser(me || null);
      if (me) {
        localStorage.setItem('user', JSON.stringify(me));
      }
    } catch (error) {
      // Если ошибка аутентификации, очищаем данные
      setUser(null);
      localStorage.removeItem('user');
      localStorage.removeItem('token');
    } finally {
      setLoading(false);
    }
  };

  const login = async (username, password) => {
    const response = await authApi.login(username, password);
    setUser(response.user);
    return response;
  };

  const register = async (username, email, password) => {
    const response = await authApi.register(username, email, password);
    return response;
  };

  const logout = async () => {
    try {
      await authApi.logout();
    } catch (error) {
      // Игнорируем ошибки при выходе
      console.error('Logout error:', error);
    } finally {
      setUser(null);
      localStorage.removeItem('user');
      localStorage.removeItem('token');
    }
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, register, checkAuth }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
} 