from pydantic import BaseModel

class PermissionBase(BaseModel):
    user_id: int
    folder_id: int
    level: str  # view, upload, delete, manage

class PermissionCreate(PermissionBase):
    pass

class PermissionOut(PermissionBase):
    id: int
    model_config = {"from_attributes": True} 