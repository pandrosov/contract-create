import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import ProtectedRoute from './components/ProtectedRoute';
import Header from './components/Header';
import Sidebar from './components/Sidebar';
import UsersPage from './pages/UsersPage';
import FoldersPage from './pages/FoldersPage';
import TemplatesPage from './pages/TemplatesPage';
import GenerateDocumentPage from './pages/GenerateDocumentPage';
import PermissionsPage from './pages/PermissionsPage';
import LogsPage from './pages/LogsPage';

function HomePage() {
  return <div><h2>Главная страница</h2><p>Вы успешно вошли в систему!</p></div>;
}

function ProtectedLayout({ children }) {
  return (
    <div className="app-layout">
      <Header />
      <div className="main-content">
        <Sidebar />
        <main className="content-area">
          {children}
        </main>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/" element={
            <ProtectedRoute>
              <ProtectedLayout>
                <HomePage />
              </ProtectedLayout>
            </ProtectedRoute>
          } />
          <Route path="/users" element={
            <ProtectedRoute>
              <ProtectedLayout>
                <UsersPage />
              </ProtectedLayout>
            </ProtectedRoute>
          } />
          <Route path="/folders" element={
            <ProtectedRoute>
              <ProtectedLayout>
                <FoldersPage />
              </ProtectedLayout>
            </ProtectedRoute>
          } />
          <Route path="/templates" element={
            <ProtectedRoute>
              <ProtectedLayout>
                <TemplatesPage />
              </ProtectedLayout>
            </ProtectedRoute>
          } />
          <Route path="/generate" element={
            <ProtectedRoute>
              <ProtectedLayout>
                <GenerateDocumentPage />
              </ProtectedLayout>
            </ProtectedRoute>
          } />
          <Route path="/permissions" element={
            <ProtectedRoute>
              <ProtectedLayout>
                <PermissionsPage />
              </ProtectedLayout>
            </ProtectedRoute>
          } />
          <Route path="/logs" element={
            <ProtectedRoute>
              <ProtectedLayout>
                <LogsPage />
              </ProtectedLayout>
            </ProtectedRoute>
          } />
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </Router>
    </AuthProvider>
  );
} 