import React, { useEffect, useState } from 'react';
import { getFolders } from '../api/folders';
import { getTemplatesByFolder, uploadTemplate, deleteTemplate } from '../api/templates';
import { useAuth } from '../context/AuthContext';

export default function TemplatesPage() {
  const { csrfToken } = useAuth();
  const [folders, setFolders] = useState([]);
  const [selectedFolder, setSelectedFolder] = useState(null);
  const [templates, setTemplates] = useState([]);
  const [file, setFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    (async () => {
      try {
        const data = await getFolders();
        setFolders(Array.isArray(data) ? data : Array.isArray(data.folders) ? data.folders : []);
        if ((Array.isArray(data) && data.length > 0)) setSelectedFolder(data[0].id);
        else if (Array.isArray(data.folders) && data.folders.length > 0) setSelectedFolder(data.folders[0].id);
      } catch {
        setError('Ошибка загрузки папок');
        setFolders([]);
      }
    })();
  }, []);

  useEffect(() => {
    if (!selectedFolder) return;
    setLoading(true);
    setError('');
    (async () => {
      try {
        const data = await getTemplatesByFolder(selectedFolder);
        setTemplates(Array.isArray(data) ? data : Array.isArray(data.templates) ? data.templates : []);
      } catch {
        setError('Ошибка загрузки шаблонов');
        setTemplates([]);
      } finally {
        setLoading(false);
      }
    })();
  }, [selectedFolder]);

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!file || !selectedFolder) return;
    setError('');
    setSuccess('');
    setLoading(true);
    try {
      await uploadTemplate(file, selectedFolder, csrfToken);
      setSuccess('Шаблон загружен');
      setFile(null);
      const data = await getTemplatesByFolder(selectedFolder);
      setTemplates(Array.isArray(data) ? data : Array.isArray(data.templates) ? data.templates : []);
    } catch {
      setError('Ошибка загрузки шаблона');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Удалить шаблон?')) return;
    setError('');
    setSuccess('');
    setLoading(true);
    try {
      await deleteTemplate(id, csrfToken);
      setSuccess('Шаблон удалён');
      const data = await getTemplatesByFolder(selectedFolder);
      setTemplates(Array.isArray(data) ? data : Array.isArray(data.templates) ? data.templates : []);
    } catch {
      setError('Ошибка удаления шаблона');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <h2>Управление шаблонами</h2>
      {error && <div className="auth-error">{error}</div>}
      {success && <div className="auth-success">{success}</div>}
      
      {/* Форма загрузки шаблона */}
      <div style={{ margin: '18px 0', display: 'flex', gap: 10, alignItems: 'center' }}>
        <select value={selectedFolder || ''} onChange={e => setSelectedFolder(Number(e.target.value))}>
          {(folders || []).map(f => (
            <option key={f.id} value={f.id}>{f.name} (id: {f.id})</option>
          ))}
        </select>
        <form onSubmit={handleUpload} style={{ display: 'inline-flex', gap: 8, alignItems: 'center' }}>
          <input type="file" accept=".docx" onChange={e => setFile(e.target.files[0])} />
          <button type="submit" disabled={!file || !selectedFolder || loading}>Загрузить шаблон</button>
        </form>
      </div>

      {/* Список шаблонов */}
      {loading ? (
        <div>Загрузка...</div>
      ) : (
        <table style={{ width: '100%', marginTop: 18, borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: '#f7fafc' }}>
              <th style={{ padding: 8, border: '1px solid #e0e7ef' }}>ID</th>
              <th style={{ padding: 8, border: '1px solid #e0e7ef' }}>Имя файла</th>
              <th style={{ padding: 8, border: '1px solid #e0e7ef' }}>Дата загрузки</th>
              <th style={{ padding: 8, border: '1px solid #e0e7ef' }}>Действия</th>
            </tr>
          </thead>
          <tbody>
            {(templates || []).map(t => (
              <tr key={t.id}>
                <td style={{ padding: 8, border: '1px solid #e0e7ef' }}>{t.id}</td>
                <td style={{ padding: 8, border: '1px solid #e0e7ef' }}>{t.filename}</td>
                <td style={{ padding: 8, border: '1px solid #e0e7ef' }}>
                  {new Date(t.uploaded_at).toLocaleDateString()}
                </td>
                <td style={{ padding: 8, border: '1px solid #e0e7ef' }}>
                  <button 
                    onClick={() => handleDelete(t.id)} 
                    style={{ 
                      color: '#e53935', 
                      border: 'none', 
                      background: 'none', 
                      cursor: 'pointer' 
                    }}
                  >
                    Удалить
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
      
      <div style={{ marginTop: 20, padding: 16, background: '#f0f8ff', borderRadius: 8, border: '1px solid #b3d9ff' }}>
        <h4>💡 Подсказка</h4>
        <p>Для создания документов из шаблонов перейдите в раздел <strong>"Создать документ"</strong> в боковом меню.</p>
      </div>
    </div>
  );
} 