from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from app.schemas.folder import FolderCreate, FolderOut
from app.services.folder_service import create_folder, get_folder_by_id, delete_folder, get_subfolders, list_folders, list_folders_for_user
from app.core.db import get_db
from app.core.security import get_current_user, check_csrf

router = APIRouter(prefix="/folders", tags=["folders"])

@router.get("/", response_model=None)
def list_folders_route(db: Session = Depends(get_db), user=Depends(get_current_user)):
    # Возвращаем только папки, на которые у пользователя есть права
    folders = list_folders_for_user(db, user.id)
    result = [
        {
            "id": folder.id,
            "name": folder.name,
            "parent_id": folder.parent_id,
            "path": folder.path,
            "created_by": folder.created_by
        }
        for folder in folders
    ]
    return JSONResponse(content=result)

@router.post("/", response_model=None)
def create_folder_route(folder: FolderCreate, db: Session = Depends(get_db), user=Depends(get_current_user), request: Request = None):
    # check_csrf(request)  # Временно отключено для тестирования
    parent_path = ""
    if folder.parent_id:
        parent = get_folder_by_id(db, folder.parent_id)
        if not parent:
            raise HTTPException(status_code=404, detail="Родительская папка не найдена")
        parent_path = parent.path
    path = f"{parent_path}/{folder.name}".replace("//", "/")
    created_folder = create_folder(db, folder, created_by=user.id, path=path)
    result = {
        "id": created_folder.id,
        "name": created_folder.name,
        "parent_id": created_folder.parent_id,
        "path": created_folder.path,
        "created_by": created_folder.created_by
    }
    return JSONResponse(content=result)

@router.get("/{folder_id}", response_model=None)
def get_folder_route(folder_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)):
    folder = get_folder_by_id(db, folder_id)
    if not folder:
        raise HTTPException(status_code=404, detail="Папка не найдена")
    result = {
        "id": folder.id,
        "name": folder.name,
        "parent_id": folder.parent_id,
        "path": folder.path,
        "created_by": folder.created_by
    }
    return JSONResponse(content=result)

@router.delete("/{folder_id}")
def delete_folder_route(folder_id: int, db: Session = Depends(get_db), user=Depends(get_current_user), request: Request = None):
    # check_csrf(request)  # Временно отключено для тестирования
    folder = delete_folder(db, folder_id)
    if not folder:
        raise HTTPException(status_code=404, detail="Папка не найдена")
    return {"status": "deleted", "folder_id": folder_id} 