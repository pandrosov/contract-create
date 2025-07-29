import React, { useEffect, useState } from 'react';
import { getUsers, activateUser } from '../api/users';
import { useAuth } from '../context/AuthContext';

export default function UsersPage() {
  const { user: currentUser } = useAuth();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const fetchUsers = async () => {
    setLoading(true);
    setError('');
    try {
      const data = await getUsers();
      setUsers(data || []);
    } catch {
      setError('Ошибка загрузки пользователей');
      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
    // eslint-disable-next-line
  }, []);

  const handleActivate = async (user_id, is_active) => {
    setError('');
    setSuccess('');
    try {
      await activateUser(user_id, is_active);
      setSuccess('Статус пользователя обновлён');
      fetchUsers();
    } catch {
      setError('Ошибка обновления статуса пользователя');
    }
  };

  return (
    <div>
      <h2>Пользователи</h2>
      {error && <div className="auth-error">{error}</div>}
      {success && <div className="auth-success">{success}</div>}
      {loading ? (
        <div>Загрузка...</div>
      ) : (
        <table style={{ width: '100%', marginTop: 18, borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: '#f7fafc' }}>
              <th style={{ padding: 8, border: '1px solid #e0e7ef' }}>ID</th>
              <th style={{ padding: 8, border: '1px solid #e0e7ef' }}>Имя</th>
              <th style={{ padding: 8, border: '1px solid #e0e7ef' }}>Email</th>
              <th style={{ padding: 8, border: '1px solid #e0e7ef' }}>Роль</th>
              <th style={{ padding: 8, border: '1px solid #e0e7ef' }}>Статус</th>
              <th style={{ padding: 8, border: '1px solid #e0e7ef' }}>Действия</th>
            </tr>
          </thead>
          <tbody>
            {(users || []).map(u => (
              <tr key={u.id} style={{ background: u.is_active ? '#fff' : '#fff8f8' }}>
                <td style={{ padding: 8, border: '1px solid #e0e7ef' }}>{u.id}</td>
                <td style={{ padding: 8, border: '1px solid #e0e7ef' }}>{u.username}</td>
                <td style={{ padding: 8, border: '1px solid #e0e7ef' }}>{u.email}</td>
                <td style={{ padding: 8, border: '1px solid #e0e7ef' }}>{u.is_admin ? 'Админ' : 'Пользователь'}</td>
                <td style={{ padding: 8, border: '1px solid #e0e7ef' }}>{u.is_active ? 'Активен' : 'Не активен'}</td>
                <td style={{ padding: 8, border: '1px solid #e0e7ef' }}>
                  {currentUser && u.id !== currentUser.id && (
                    u.is_active ? (
                      <button onClick={() => handleActivate(u.id, false)} style={{ color: '#e53935', border: 'none', background: 'none', cursor: 'pointer' }}>Деактивировать</button>
                    ) : (
                      <button onClick={() => handleActivate(u.id, true)} style={{ color: '#388e3c', border: 'none', background: 'none', cursor: 'pointer' }}>Активировать</button>
                    )
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
} 