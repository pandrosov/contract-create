from pydantic import BaseModel
from typing import Optional

class LogBase(BaseModel):
    user_id: int
    action: str
    target_type: str
    target_id: Optional[int] = None
    details: Optional[str] = None

class LogCreate(LogBase):
    pass

class LogOut(LogBase):
    id: int
    timestamp: str
    model_config = {"from_attributes": True} 