from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from app.schemas.permission import PermissionCreate, PermissionOut
from app.services.permission_service import set_permission, get_permission, get_permissions_for_user
from app.core.db import get_db
from app.core.security import require_admin, check_csrf

router = APIRouter(prefix="/permissions", tags=["permissions"])

@router.post("/", response_model=PermissionOut)
def set_permission_route(perm: PermissionCreate, db: Session = Depends(get_db), admin=Depends(require_admin), request: Request = None):
    check_csrf(request)
    return set_permission(db, perm)

@router.get("/user/{user_id}", response_model=list[PermissionOut])
def get_user_permissions(user_id: int, db: Session = Depends(get_db), admin=Depends(require_admin)):
    return get_permissions_for_user(db, user_id) 