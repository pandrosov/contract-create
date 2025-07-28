from pydantic import BaseModel, field_serializer
from typing import Optional
from datetime import datetime

class TemplateBase(BaseModel):
    filename: str
    folder_id: int

class TemplateCreate(TemplateBase):
    pass

class TemplateOut(TemplateBase):
    id: int
    uploaded_by: int
    uploaded_at: datetime
    
    @field_serializer('uploaded_at')
    def serialize_uploaded_at(self, value: datetime) -> str:
        return value.isoformat() if value else None
    
    model_config = {"from_attributes": True} 