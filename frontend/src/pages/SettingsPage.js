import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { getSettings, createSetting, updateSetting, deleteSetting } from '../api/settings';

export default function SettingsPage() {
  const { user } = useAuth();
  const [settings, setSettings] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [editingSetting, setEditingSetting] = useState(null);
  const [newSetting, setNewSetting] = useState({ key: '', value: '', description: '' });

  useEffect(() => {
    if (user && user.is_admin) {
      loadSettings();
    }
  }, [user]);

  const loadSettings = async () => {
    setLoading(true);
    try {
      const response = await getSettings();
      setSettings(response.data.data || []);
    } catch (error) {
      console.error('Error loading settings:', error);
      setError('Ошибка загрузки настроек');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateSetting = async (e) => {
    e.preventDefault();
    if (!newSetting.key || !newSetting.value) {
      setError('Заполните обязательные поля');
      return;
    }

    setLoading(true);
    try {
      await createSetting(newSetting);
      setNewSetting({ key: '', value: '', description: '' });
      await loadSettings();
      setSuccess('Настройка успешно создана');
    } catch (error) {
      console.error('Error creating setting:', error);
      setError('Ошибка создания настройки');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateSetting = async (key, updatedData) => {
    setLoading(true);
    try {
      await updateSetting(key, updatedData);
      setEditingSetting(null);
      await loadSettings();
      setSuccess('Настройка успешно обновлена');
    } catch (error) {
      console.error('Error updating setting:', error);
      setError('Ошибка обновления настройки');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteSetting = async (key) => {
    if (!window.confirm('Вы уверены, что хотите удалить эту настройку?')) {
      return;
    }

    setLoading(true);
    try {
      await deleteSetting(key);
      await loadSettings();
      setSuccess('Настройка успешно удалена');
    } catch (error) {
      console.error('Error deleting setting:', error);
      setError('Ошибка удаления настройки');
    } finally {
      setLoading(false);
    }
  };

  if (!user || !user.is_admin) {
    return (
      <div className="settings-page">
        <div className="container">
          <h1>Настройки</h1>
          <div className="auth-error">
            У вас нет прав для доступа к этой странице
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="settings-page">
      <div className="container">
        <h1>Настройки системы</h1>
        
        {error && <div className="auth-error">{error}</div>}
        {success && <div className="auth-success">{success}</div>}
        
        <div className="settings-layout">
          {/* Создание новой настройки */}
          <div className="form-section">
            <h3>Создать новую настройку</h3>
            <form onSubmit={handleCreateSetting} className="setting-form">
              <div className="form-group">
                <label>Ключ настройки:</label>
                <input
                  type="text"
                  value={newSetting.key}
                  onChange={e => setNewSetting({...newSetting, key: e.target.value})}
                  className="form-control"
                  placeholder="Например: document_help_info"
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Значение:</label>
                <textarea
                  value={newSetting.value}
                  onChange={e => setNewSetting({...newSetting, value: e.target.value})}
                  className="form-control"
                  rows="4"
                  placeholder="Введите значение настройки..."
                  required
                />
              </div>
              
              <div className="form-group">
                <label>Описание (необязательно):</label>
                <input
                  type="text"
                  value={newSetting.description}
                  onChange={e => setNewSetting({...newSetting, description: e.target.value})}
                  className="form-control"
                  placeholder="Краткое описание назначения настройки"
                />
              </div>
              
              <button type="submit" disabled={loading} className="btn btn-primary">
                {loading ? 'Создание...' : 'Создать настройку'}
              </button>
            </form>
          </div>

          {/* Список настроек */}
          <div className="form-section">
            <h3>Существующие настройки</h3>
            {loading ? (
              <div className="loading">Загрузка настроек...</div>
            ) : (
              <div className="settings-list">
                {settings.map(setting => (
                  <div key={setting.id} className="setting-item">
                    <div className="setting-header">
                      <h4>{setting.key}</h4>
                      <div className="setting-actions">
                        <button
                          onClick={() => setEditingSetting(setting)}
                          className="btn btn-secondary btn-small"
                        >
                          Редактировать
                        </button>
                        <button
                          onClick={() => handleDeleteSetting(setting.key)}
                          className="btn btn-danger btn-small"
                        >
                          Удалить
                        </button>
                      </div>
                    </div>
                    
                    {editingSetting && editingSetting.id === setting.id ? (
                      <div className="setting-edit">
                        <textarea
                          value={editingSetting.value}
                          onChange={e => setEditingSetting({...editingSetting, value: e.target.value})}
                          className="form-control"
                          rows="4"
                        />
                        <div className="edit-actions">
                          <button
                            onClick={() => handleUpdateSetting(setting.key, { value: editingSetting.value })}
                            className="btn btn-primary btn-small"
                          >
                            Сохранить
                          </button>
                          <button
                            onClick={() => setEditingSetting(null)}
                            className="btn btn-secondary btn-small"
                          >
                            Отмена
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div className="setting-content">
                        <p>{setting.value}</p>
                        {setting.description && (
                          <small className="setting-description">{setting.description}</small>
                        )}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
} 