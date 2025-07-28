import React from 'react';
import { NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Sidebar() {
  const { user } = useAuth();
  if (!user) return null;
  const isAdmin = user.is_admin || false;
  return (
    <aside className="sidebar">
      <nav className="sidebar-nav">
        <NavLink to="/" end className={({ isActive }) => isActive ? 'sidebar-link active' : 'sidebar-link'}>Главная</NavLink>
        {isAdmin && <NavLink to="/users" className={({ isActive }) => isActive ? 'sidebar-link active' : 'sidebar-link'}>Пользователи</NavLink>}
        <NavLink to="/folders" className={({ isActive }) => isActive ? 'sidebar-link active' : 'sidebar-link'}>Папки</NavLink>
        <NavLink to="/templates" className={({ isActive }) => isActive ? 'sidebar-link active' : 'sidebar-link'}>Шаблоны</NavLink>
        <NavLink to="/generate" className={({ isActive }) => isActive ? 'sidebar-link active' : 'sidebar-link'}>Создать документ</NavLink>
        {isAdmin && <NavLink to="/permissions" className={({ isActive }) => isActive ? 'sidebar-link active' : 'sidebar-link'}>Права</NavLink>}
        {isAdmin && <NavLink to="/logs" className={({ isActive }) => isActive ? 'sidebar-link active' : 'sidebar-link'}>Логи</NavLink>}
      </nav>
    </aside>
  );
} 