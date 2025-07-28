from sqlalchemy.orm import Session
from app.models.permission import Permission
from app.schemas.permission import PermissionCreate

def set_permission(db: Session, perm: PermissionCreate) -> Permission:
    db_perm = Permission(
        user_id=perm.user_id,
        folder_id=perm.folder_id,
        level=perm.level
    )
    db.add(db_perm)
    db.commit()
    db.refresh(db_perm)
    return db_perm

def get_permission(db: Session, user_id: int, folder_id: int):
    return db.query(Permission).filter(Permission.user_id == user_id, Permission.folder_id == folder_id).first()

def get_permissions_for_user(db: Session, user_id: int):
    return db.query(Permission).filter(Permission.user_id == user_id).all() 