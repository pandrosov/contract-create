from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
import datetime
from app.core.db import Base

class Template(Base):
    __tablename__ = 'templates'
    id = Column(Integer, primary_key=True)
    filename = Column(String, nullable=False)
    file_path = Column(String, nullable=False)
    folder_id = Column(Integer, ForeignKey('folders.id'))
    user_id = Column(Integer, ForeignKey('users.id'))
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    folder = relationship('Folder', back_populates='templates')
    uploaded_by_user = relationship('User', back_populates='templates')
    # placeholder_descriptions = relationship('PlaceholderDescription', back_populates='template', cascade='all, delete-orphan') 