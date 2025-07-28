from sqlalchemy import Column, Integer, String, ForeignKey
from app.core.db import Base

class Permission(Base):
    __tablename__ = 'permissions'
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    folder_id = Column(Integer, ForeignKey('folders.id'))
    level = Column(String, nullable=False)  # view, upload, delete, manage 