from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.db import Base

class PlaceholderDescription(Base):
    __tablename__ = "placeholder_descriptions"
    
    id = Column(Integer, primary_key=True, index=True)
    template_id = Column(Integer, ForeignKey("templates.id", ondelete="CASCADE"), nullable=False)
    placeholder_name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Связь с шаблоном (временно отключена для избежания циклических импортов)
    # template = relationship("Template", back_populates="placeholder_descriptions")
    
    def __repr__(self):
        return f"<PlaceholderDescription(id={self.id}, template_id={self.template_id}, placeholder='{self.placeholder_name}', description='{self.description[:50] if self.description else None}...')>" 