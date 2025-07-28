import React, { useEffect, useState } from 'react';
import { getFolders, createFolder, deleteFolder } from '../api/folders';
import { useAuth } from '../context/AuthContext';

function renderTree(folders, parentId, level, onDelete) {
  if (level > 5) return null;
  return (folders || [])
    .filter(f => f.parent_id === parentId)
    .map(f => (
      <div key={f.id} style={{ marginLeft: level * 18, display: 'flex', alignItems: 'center', gap: 8 }}>
        <span>{f.name}</span>
        <button onClick={() => onDelete(f.id)} style={{ color: '#e53935', border: 'none', background: 'none', cursor: 'pointer', fontSize: 14 }}>Удалить</button>
        {renderTree(folders, f.id, level + 1, onDelete)}
      </div>
    ));
}

export default function FoldersPage() {
  const { csrfToken, user } = useAuth();
  const [folders, setFolders] = useState([]);
  const [name, setName] = useState('');
  const [parentId, setParentId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const fetchFolders = async () => {
    setLoading(true);
    setError('');
    try {
      console.log('[FoldersPage] Отправляю запрос на получение списка папок...');
      const data = await getFolders();
      console.log('[FoldersPage] Получен список папок:', data);
      setFolders(Array.isArray(data) ? data : Array.isArray(data.folders) ? data.folders : []);
    } catch (e) {
      setError('Ошибка загрузки папок');
      setFolders([]);
      console.error('[FoldersPage] Ошибка при получении папок:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFolders();
    // eslint-disable-next-line
  }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    try {
      console.log('[FoldersPage] Отправляю запрос на создание папки:', { name, parent_id: parentId });
      await createFolder({ name, parent_id: parentId }, csrfToken);
      setSuccess('Папка создана');
      setName('');
      setParentId(null);
      fetchFolders();
    } catch (err) {
      setError('Ошибка создания папки');
      console.error('[FoldersPage] Ошибка при создании папки:', err);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Удалить папку и все вложенные элементы?')) return;
    setError('');
    setSuccess('');
    try {
      await deleteFolder(id, csrfToken);
      setSuccess('Папка удалена');
      fetchFolders();
    } catch {
      setError('Ошибка удаления папки');
    }
  };

  return (
    <div>
      <h2>Папки</h2>
      {error && <div className="auth-error">{error}</div>}
      {success && <div className="auth-success">{success}</div>}
      <form onSubmit={handleCreate} style={{ margin: '18px 0', display: 'flex', gap: 10, alignItems: 'center' }}>
        <input
          type="text"
          placeholder="Название папки"
          value={name}
          onChange={e => setName(e.target.value)}
          required
        />
        <select value={parentId || ''} onChange={e => setParentId(e.target.value ? Number(e.target.value) : null)}>
          <option value="">Корневая папка</option>
          {(folders || []).map(f => (
            <option key={f.id} value={f.id}>{f.name} (id: {f.id})</option>
          ))}
        </select>
        <button type="submit">Создать папку</button>
      </form>
      {loading ? (
        <div>Загрузка...</div>
      ) : (
        <div style={{ marginTop: 18 }}>
          {renderTree(folders, null, 0, handleDelete)}
        </div>
      )}
    </div>
  );
} 