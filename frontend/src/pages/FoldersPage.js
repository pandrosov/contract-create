import React, { useEffect, useState } from 'react';
import { getFolders, createFolder, deleteFolder } from '../api/folders';
import { useAuth } from '../context/AuthContext';
import LoadingSpinner from '../components/LoadingSpinner';

function renderTree(folders, parentId, level, onDelete) {
  if (level > 5) return null;
  return (folders || [])
    .filter(f => f.parent_id === parentId)
    .map(f => (
      <div key={f.id} className="folder-item">
        <div className="folder-content">
          <div className="folder-icon">📁</div>
          <div className="folder-info">
            <span className="folder-name">{f.name}</span>
            <span className="folder-path">{f.path}</span>
          </div>
          <div className="folder-actions">
            <button 
              onClick={() => onDelete(f.id)} 
              className="btn btn-danger btn-sm"
              title="Удалить папку"
            >
              <span>🗑️</span>
              Удалить
            </button>
          </div>
        </div>
        <div className="folder-children">
          {renderTree(folders, f.id, level + 1, onDelete)}
        </div>
      </div>
    ));
}

export default function FoldersPage() {
  const { user } = useAuth();
  const [folders, setFolders] = useState([]);
  const [name, setName] = useState('');
  const [parentId, setParentId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);

  const fetchFolders = async () => {
    setLoading(true);
    try {
      const data = await getFolders();
      setFolders(Array.isArray(data) ? data : Array.isArray(data.folders) ? data.folders : []);
    } catch (error) {
      console.error('Error fetching folders:', error);
      window.showNotification?.('Ошибка загрузки папок', 'error');
      setFolders([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFolders();
  }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    if (!name.trim()) return;
    
    setCreating(true);
    try {
      await createFolder({ name: name.trim(), parent_id: parentId });
      window.showNotification?.('Папка успешно создана!', 'success');
      setName('');
      setParentId(null);
      fetchFolders();
    } catch (error) {
      console.error('Error creating folder:', error);
      window.showNotification?.('Ошибка создания папки', 'error');
    } finally {
      setCreating(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Вы уверены, что хотите удалить эту папку и все её содержимое?')) return;
    
    try {
      await deleteFolder(id);
      window.showNotification?.('Папка успешно удалена!', 'success');
      fetchFolders();
    } catch (error) {
      console.error('Error deleting folder:', error);
      window.showNotification?.('Ошибка удаления папки', 'error');
    }
  };

  if (loading) {
    return (
      <div className="page-header">
        <h1 className="page-title">Папки</h1>
        <LoadingSpinner text="Загрузка папок..." />
      </div>
    );
  }

  return (
    <div className="folders-page">
      <div className="page-header">
        <h1 className="page-title">Папки</h1>
        <p className="page-subtitle">Управление структурой папок</p>
      </div>

      <div className="card">
        <div className="card-header">
          <h2 className="card-title">Создать новую папку</h2>
        </div>
        <form onSubmit={handleCreate} className="folder-form">
          <div className="form-row">
            <div className="form-group">
              <label htmlFor="folder-name" className="form-label">
                Название папки
              </label>
              <input
                id="folder-name"
                type="text"
                className="form-input"
                placeholder="Введите название папки"
                value={name}
                onChange={e => setName(e.target.value)}
                required
                disabled={creating}
              />
            </div>
            <div className="form-group">
              <label htmlFor="parent-folder" className="form-label">
                Родительская папка
              </label>
              <select
                id="parent-folder"
                className="form-select"
                value={parentId || ''}
                onChange={e => setParentId(e.target.value ? Number(e.target.value) : null)}
                disabled={creating}
              >
                <option value="">Корневая папка</option>
                {folders.map(folder => (
                  <option key={folder.id} value={folder.id}>
                    {folder.name}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">&nbsp;</label>
              <button 
                type="submit" 
                className="btn btn-primary"
                disabled={creating || !name.trim()}
              >
                {creating ? (
                  <>
                    <div className="spinner spinner-sm"></div>
                    Создание...
                  </>
                ) : (
                  <>
                    <span>📁</span>
                    Создать папку
                  </>
                )}
              </button>
            </div>
          </div>
        </form>
      </div>

      <div className="card">
        <div className="card-header">
          <h2 className="card-title">Структура папок</h2>
          <span className="card-subtitle">
            {folders.length} папок в системе
          </span>
        </div>

        {folders.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">📁</div>
            <h3 className="empty-state-title">Нет папок</h3>
            <p className="empty-state-description">
              Создайте первую папку, чтобы начать работу с системой.
            </p>
            <button
              className="btn btn-primary"
              onClick={() => document.getElementById('folder-name')?.focus()}
            >
              <span>📁</span>
              Создать папку
            </button>
          </div>
        ) : (
          <div className="folders-tree">
            {renderTree(folders, null, 0, handleDelete)}
          </div>
        )}
      </div>

      <div className="card">
        <div className="card-header">
          <h2 className="card-title">Информация</h2>
        </div>
        <div className="info-content">
          <p>
            <strong>📁 Как использовать папки:</strong>
          </p>
          <ul>
            <li>Создавайте папки для организации шаблонов</li>
            <li>Используйте вложенные папки для лучшей структуры</li>
            <li>При удалении папки удаляются все шаблоны внутри неё</li>
            <li>Максимальная глубина вложенности: 5 уровней</li>
          </ul>
        </div>
      </div>
    </div>
  );
} 