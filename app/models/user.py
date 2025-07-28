from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import relationship
import datetime
from app.core.db import Base

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    is_active = Column(Boolean, default=False)
    is_admin = Column(Boolean, default=False)
    date_joined = Column(DateTime, default=datetime.datetime.utcnow)
    templates = relationship('Template', back_populates='uploaded_by_user')
    folders = relationship('Folder', back_populates='created_by_user') 