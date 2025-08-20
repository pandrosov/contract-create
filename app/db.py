from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import declarative_base, relationship
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import datetime

Base = declarative_base()

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
    templates = relationship('Template', back_populates='folder')

class Template(Base):
    __tablename__ = 'templates'
    id = Column(Integer, primary_key=True)
    filename = Column(String, nullable=False)
    folder_id = Column(Integer, ForeignKey('folders.id'))
    uploaded_by = Column(Integer, ForeignKey('users.id'))
    uploaded_at = Column(DateTime, default=datetime.datetime.utcnow)
    folder = relationship('Folder', back_populates='templates')
    uploaded_by_user = relationship('User', back_populates='templates')

class Permission(Base):
    __tablename__ = 'permissions'
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    folder_id = Column(Integer, ForeignKey('folders.id'))
    level = Column(String, nullable=False)  # view, upload, delete, manage

class ActionLog(Base):
    __tablename__ = 'action_logs'
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    action = Column(String, nullable=False)  # download, upload, delete, manage, login, etc.
    target_type = Column(String, nullable=False)  # folder, template, user
    target_id = Column(Integer, nullable=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    details = Column(Text)

# Настройка PostgreSQL для продакшена
import os
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://contract_user:secure_password_123@postgres:5432/contract_db")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Для Alembic и инициализации
if __name__ == "__main__":
    Base.metadata.create_all(bind=engine) 