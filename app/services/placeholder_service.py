from sqlalchemy.orm import Session
from app.models.placeholder_description import PlaceholderDescription
from typing import List, Dict, Optional

class PlaceholderService:
    def __init__(self, db: Session):
        self.db = db
    
    def get_placeholder_descriptions(self, template_id: int) -> List[PlaceholderDescription]:
        """Получает все описания плейсхолдеров для шаблона"""
        return self.db.query(PlaceholderDescription).filter(
            PlaceholderDescription.template_id == template_id
        ).all()
    
    def get_placeholder_description(self, template_id: int, placeholder_name: str) -> Optional[PlaceholderDescription]:
        """Получает описание конкретного плейсхолдера"""
        return self.db.query(PlaceholderDescription).filter(
            PlaceholderDescription.template_id == template_id,
            PlaceholderDescription.placeholder_name == placeholder_name
        ).first()
    
    def create_or_update_description(self, template_id: int, placeholder_name: str, description: str) -> PlaceholderDescription:
        """Создает или обновляет описание плейсхолдера"""
        existing = self.get_placeholder_description(template_id, placeholder_name)
        
        if existing:
            existing.description = description
            self.db.commit()
            self.db.refresh(existing)
            return existing
        else:
            new_description = PlaceholderDescription(
                template_id=template_id,
                placeholder_name=placeholder_name,
                description=description
            )
            self.db.add(new_description)
            self.db.commit()
            self.db.refresh(new_description)
            return new_description
    
    def delete_description(self, template_id: int, placeholder_name: str) -> bool:
        """Удаляет описание плейсхолдера"""
        existing = self.get_placeholder_description(template_id, placeholder_name)
        if existing:
            self.db.delete(existing)
            self.db.commit()
            return True
        return False
    
    def get_descriptions_dict(self, template_id: int) -> Dict[str, str]:
        """Возвращает словарь {placeholder_name: description} для шаблона"""
        descriptions = self.get_placeholder_descriptions(template_id)
        return {desc.placeholder_name: desc.description for desc in descriptions if desc.description} 