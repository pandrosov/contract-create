import React, { createContext, useContext, useState, useEffect } from 'react';
import * as authApi from '../api/auth';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [csrfToken, setCsrfToken] = useState('');
  const [loading, setLoading] = useState(true);

  // Получить CSRF-токен из cookie
  const getCsrfFromCookie = () => {
    const match = document.cookie.match(/csrf_token=([^;]+)/);
    return match ? decodeURIComponent(match[1]) : '';
  };

  // Проверка авторизации при загрузке
  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    setLoading(true);
    try {
      const me = await authApi.getMe();
      setUser(me || null);
      setCsrfToken(getCsrfFromCookie());
    } catch {
      setUser(null);
      setCsrfToken('');
    } finally {
      setLoading(false);
    }
  };

  const login = async (username, password) => {
    await authApi.login(username, password);
    await checkAuth();
  };

  const register = async (username, email, password) => {
    await authApi.register(username, email, password);
  };

  const logout = async () => {
    try {
      await authApi.logout();
    } catch {
      // Игнорируем ошибки при выходе
    }
    setUser(null);
    setCsrfToken('');
  };

  return (
    <AuthContext.Provider value={{ user, csrfToken, loading, login, logout, register, checkAuth }}>
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