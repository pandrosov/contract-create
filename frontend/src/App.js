import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import Sidebar from './components/Sidebar';
import Header from './components/Header';
import NotificationContainer from './components/NotificationContainer';

// Pages
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import FoldersPage from './pages/FoldersPage';
import TemplatesPage from './pages/TemplatesPage';
import GenerateDocumentPage from './pages/GenerateDocumentPage';
import UsersPage from './pages/UsersPage';
import PermissionsPage from './pages/PermissionsPage';
import LogsPage from './pages/LogsPage';

// Styles
import './styles/global.css';

const ProtectedLayout = ({ children }) => (
  <div className="app-layout">
    <Sidebar />
    <div className="main-content">
      <Header />
      <div className="content">
        {children}
      </div>
    </div>
  </div>
);

const App = () => {
  return (
    <AuthProvider>
      <Router>
        <div className="app">
          <NotificationContainer />
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/" element={<Navigate to="/folders" replace />} />
            
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
          </Routes>
        </div>
      </Router>
    </AuthProvider>
  );
};

export default App; 