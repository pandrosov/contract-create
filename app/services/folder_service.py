from sqlalchemy.orm import Session
from app.models.folder import Folder
from app.schemas.folder import FolderCreate
from app.models.permission import Permission

def list_folders(db: Session):
    return db.query(Folder).all()

def get_folder_by_id(db: Session, folder_id: int):
    return db.query(Folder).filter(Folder.id == folder_id).first()

def create_folder(db: Session, folder: FolderCreate, created_by: int, path: str) -> Folder:
    db_folder = Folder(
        name=folder.name,
        parent_id=folder.parent_id,
        path=path,
        created_by=created_by
    )
    db.add(db_folder)
    db.commit()
    db.refresh(db_folder)
    # Выдаём права создателю
    db_perm = Permission(user_id=created_by, folder_id=db_folder.id, level="manage")
    db.add(db_perm)
    db.commit()
    return db_folder

def delete_folder(db: Session, folder_id: int):
    folder = get_folder_by_id(db, folder_id)
    if folder:
        # Удаляем запись из БД
        db.delete(folder)
        db.commit()
    return folder

def get_subfolders(db: Session, parent_id: int):
    return db.query(Folder).filter(Folder.parent_id == parent_id).all()

def list_folders_for_user(db: Session, user_id: int):
    """Возвращает папки, на которые у пользователя есть права"""
    # Пока что возвращаем все папки, но здесь можно добавить логику прав доступа
    return db.query(Folder).all() 