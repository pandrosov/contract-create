from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.schemas.folder import FolderCreate, FolderOut
from app.services.folder_service import create_folder, get_folder_by_id, delete_folder, get_subfolders, list_folders, list_folders_for_user
from app.core.db import get_db
from app.core.security import get_current_user, check_csrf

router = APIRouter(prefix="/folders", tags=["folders"])

@router.get("/", response_model=list[FolderOut])
def list_folders_route(db: Session = Depends(get_db), user=Depends(get_current_user)):
    # Возвращаем только папки, на которые у пользователя есть права
    return list_folders_for_user(db, user.id)

@router.post("/", response_model=FolderOut)
def create_folder_route(folder: FolderCreate, db: Session = Depends(get_db), user=Depends(get_current_user), request: Request = None):
    check_csrf(request)
    parent_path = ""
    if folder.parent_id:
        parent = get_folder_by_id(db, folder.parent_id)
        if not parent:
            raise HTTPException(status_code=404, detail="Родительская папка не найдена")
        parent_path = parent.path
    path = f"{parent_path}/{folder.name}".replace("//", "/")
    return create_folder(db, folder, created_by=user.id, path=path)

@router.get("/{folder_id}", response_model=FolderOut)
def get_folder_route(folder_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)):
    folder = get_folder_by_id(db, folder_id)
    if not folder:
        raise HTTPException(status_code=404, detail="Папка не найдена")
    return folder

@router.delete("/{folder_id}")
def delete_folder_route(folder_id: int, db: Session = Depends(get_db), user=Depends(get_current_user), request: Request = None):
    check_csrf(request)
    folder = delete_folder(db, folder_id)
    if not folder:
        raise HTTPException(status_code=404, detail="Папка не найдена")
    return {"status": "deleted", "folder_id": folder_id} 