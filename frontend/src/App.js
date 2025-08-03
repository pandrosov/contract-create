import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import NotificationContainer from './components/NotificationContainer';

// Pages
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import DashboardPage from './pages/DashboardPage';
import FoldersPage from './pages/FoldersPage';
import TemplatesPage from './pages/TemplatesPage';
import GenerateDocumentPage from './pages/GenerateDocumentPage';
import UsersPage from './pages/UsersPage';
import PermissionsPage from './pages/PermissionsPage';
import LogsPage from './pages/LogsPage';
import ActGenerationPage from './pages/ActGenerationPage';
import SettingsPage from './pages/SettingsPage';

// Styles
import './styles/global.css';

const ProtectedLayout = ({ children }) => {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  return (
    <div className="app-layout">
      <Sidebar 
        collapsed={sidebarCollapsed} 
        onToggle={() => setSidebarCollapsed(!sidebarCollapsed)}
      />
      <div className={`main-content ${sidebarCollapsed ? 'sidebar-collapsed' : ''}`}>
        <Header />
        <div className="content">
          {children}
        </div>
      </div>
    </div>
  );
};

const App = () => {
  return (
    <AuthProvider>
      <Router>
        <div className="app">
          <NotificationContainer />
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            
            <Route path="/dashboard" element={
              <ProtectedRoute>
                <ProtectedLayout>
                  <DashboardPage />
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
            
            <Route path="/users" element={
              <ProtectedRoute>
                <ProtectedLayout>
                  <UsersPage />
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
            
            <Route path="/acts" element={
              <ProtectedRoute>
                <ProtectedLayout>
                  <ActGenerationPage />
                </ProtectedLayout>
              </ProtectedRoute>
            } />
            
            <Route path="/settings" element={
              <ProtectedRoute>
                <ProtectedLayout>
                  <SettingsPage />
                </ProtectedLayout>
              </ProtectedRoute>
            } />
          </Routes>
        </div>
      </Router>
    </AuthProvider>
  );
};

export default App; 