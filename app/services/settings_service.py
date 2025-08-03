from sqlalchemy.orm import Session
from app.models.settings import Settings
from typing import Dict, List, Optional

class SettingsService:
    def __init__(self, db: Session):
        self.db = db
    
    def get_setting(self, key: str) -> Optional[str]:
        """Получает значение настройки по ключу"""
        setting = self.db.query(Settings).filter(
            Settings.key == key,
            Settings.is_active == True
        ).first()
        return setting.value if setting else None
    
    def set_setting(self, key: str, value: str, description: str = None) -> Settings:
        """Устанавливает или обновляет настройку"""
        setting = self.db.query(Settings).filter(Settings.key == key).first()
        
        if setting:
            setting.value = value
            if description:
                setting.description = description
        else:
            setting = Settings(
                key=key,
                value=value,
                description=description
            )
            self.db.add(setting)
        
        self.db.commit()
        self.db.refresh(setting)
        return setting
    
    def get_all_settings(self) -> List[Settings]:
        """Получает все активные настройки"""
        return self.db.query(Settings).filter(Settings.is_active == True).all()
    
    def delete_setting(self, key: str) -> bool:
        """Удаляет настройку (деактивирует)"""
        setting = self.db.query(Settings).filter(Settings.key == key).first()
        if setting:
            setting.is_active = False
            self.db.commit()
            return True
        return False 