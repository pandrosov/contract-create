from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class TemplateBase(BaseModel):
    filename: str
    folder_id: Optional[int] = None

class TemplateCreate(TemplateBase):
    pass

class TemplateOut(TemplateBase):
    id: int
    uploaded_by: Optional[int] = None
    uploaded_at: Optional[str] = None
    
    class Config:
        orm_mode = True 