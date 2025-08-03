import React, { useState, useEffect } from 'react';
import { getPlaceholderDescriptions, createPlaceholderDescription, deletePlaceholderDescription } from '../api/templates';
import Modal from './Modal';
import LoadingSpinner from './LoadingSpinner';

const PlaceholderDescriptionsModal = ({ isOpen, onClose, template, onUpdate }) => {
  const [descriptions, setDescriptions] = useState({});
  const [loading, setLoading] = useState(false);
  const [newPlaceholder, setNewPlaceholder] = useState('');
  const [newDescription, setNewDescription] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (isOpen && template) {
      loadDescriptions();
    }
  }, [isOpen, template]);

  const loadDescriptions = async () => {
    if (!template) return;
    
    setLoading(true);
    try {
      const response = await getPlaceholderDescriptions(template.id);
      console.log('API response for descriptions:', response);
      setDescriptions(response || {});
    } catch (error) {
      console.error('Error loading placeholder descriptions:', error);
      window.showNotification?.('Ошибка загрузки описаний плейсхолдеров', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleAddDescription = async (e) => {
    e.preventDefault();
    if (!newPlaceholder.trim() || !newDescription.trim()) return;

    setSaving(true);
    try {
      await createPlaceholderDescription(template.id, newPlaceholder.trim(), newDescription.trim());
      setNewPlaceholder('');
      setNewDescription('');
      await loadDescriptions();
      window.showNotification?.('Описание плейсхолдера добавлено', 'success');
      if (onUpdate) onUpdate();
    } catch (error) {
      console.error('Error adding placeholder description:', error);
      window.showNotification?.('Ошибка добавления описания', 'error');
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteDescription = async (placeholderName) => {
    if (!window.confirm('Вы уверены, что хотите удалить это описание?')) return;

    try {
      await deletePlaceholderDescription(template.id, placeholderName);
      await loadDescriptions();
      window.showNotification?.('Описание плейсхолдера удалено', 'success');
      if (onUpdate) onUpdate();
    } catch (error) {
      console.error('Error deleting placeholder description:', error);
      window.showNotification?.('Ошибка удаления описания', 'error');
    }
  };

  if (!template) return null;

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={`Описания плейсхолдеров: ${template.filename}`}>
      <div className="placeholder-descriptions-modal">
        {loading ? (
          <LoadingSpinner text="Загрузка описаний..." />
        ) : (
          <>
            {/* Форма добавления нового описания */}
            <div className="add-description-form">
              <h4>Добавить описание плейсхолдера</h4>
              <form onSubmit={handleAddDescription}>
                <div className="form-group">
                  <label>Название плейсхолдера:</label>
                  <input
                    type="text"
                    value={newPlaceholder}
                    onChange={(e) => setNewPlaceholder(e.target.value)}
                    className="form-control"
                    placeholder="Например: ФИО_клиента"
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Описание:</label>
                  <textarea
                    value={newDescription}
                    onChange={(e) => setNewDescription(e.target.value)}
                    className="form-control"
                    placeholder="Опишите, что должно быть в этом поле"
                    rows="3"
                    required
                  />
                </div>
                <button 
                  type="submit" 
                  disabled={saving || !newPlaceholder.trim() || !newDescription.trim()}
                  className="btn btn-primary"
                >
                  {saving ? 'Добавление...' : 'Добавить описание'}
                </button>
              </form>
            </div>

            {/* Список существующих описаний */}
            <div className="existing-descriptions">
              <h4>Существующие описания</h4>
              {Object.keys(descriptions).length === 0 ? (
                <p className="no-descriptions">Описания плейсхолдеров не найдены</p>
              ) : (
                <div className="descriptions-list">
                  {Object.entries(descriptions).map(([placeholder, description]) => (
                    <div key={placeholder} className="description-item">
                      <div className="description-content">
                        <strong className="placeholder-name">{placeholder}</strong>
                        <p className="description-text">{description}</p>
                      </div>
                      <button
                        onClick={() => handleDeleteDescription(placeholder)}
                        className="btn btn-danger btn-sm"
                        title="Удалить описание"
                      >
                        ✕
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </>
        )}
      </div>
    </Modal>
  );
};

export default PlaceholderDescriptionsModal; 