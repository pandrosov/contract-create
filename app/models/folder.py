from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
import datetime
from app.core.db import Base

class Folder(Base):
    __tablename__ = 'folders'
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    parent_id = Column(Integer, ForeignKey('folders.id'), nullable=True)
    path = Column(String, unique=True, nullable=False)
    created_by = Column(Integer, ForeignKey('users.id'))
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    parent = relationship('Folder', remote_side=[id], backref='subfolders')
    created_by_user = relationship('User', back_populates='folders')
    templates = relationship('Template', back_populates='folder', cascade='all, delete-orphan')
    permissions = relationship('Permission', back_populates='folder', cascade='all, delete-orphan') 