from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.services.log_service import get_logs
from app.core.db import get_db
from app.core.security import require_admin
from app.schemas.log import LogOut

router = APIRouter(prefix="/logs", tags=["logs"])

@router.get("/", response_model=list[LogOut])
def list_logs(user_id: int = None, action: str = None, db: Session = Depends(get_db), admin=Depends(require_admin)):
    return get_logs(db, user_id=user_id, action=action) 