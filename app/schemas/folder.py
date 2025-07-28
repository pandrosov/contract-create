from pydantic import BaseModel
from typing import Optional, List

class FolderBase(BaseModel):
    name: str
    parent_id: Optional[int] = None

class FolderCreate(FolderBase):
    pass

class FolderOut(FolderBase):
    id: int
    path: str
    created_by: int
    model_config = {"from_attributes": True} 