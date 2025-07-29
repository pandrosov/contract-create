from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from app.core.db import get_db
from app.core.security import get_current_user, check_csrf
from app.schemas.template import TemplateOut
from app.services.template_service import (
    create_template, 
    get_templates_by_folder, 
    delete_template,
    extract_fields_from_template,
    generate_document_from_template
)
import json
from urllib.parse import quote
import io

router = APIRouter(prefix="/templates", tags=["templates"])

@router.post("/", response_model=TemplateOut)
def upload_template_route(
    file: UploadFile = File(...),
    folder_id: int = Form(...),
    db: Session = Depends(get_db), 
    user=Depends(get_current_user), 
    request: Request = None
):
    """Загружает шаблон docx в указанную папку"""
    # check_csrf(request)  # Временно отключено для тестирования
    return create_template(db, file, folder_id, user.id)

@router.get("/folder/{folder_id}")
def get_templates_by_folder_route(
    folder_id: int, 
    db: Session = Depends(get_db), 
    user=Depends(get_current_user)
):
    """Получает все шаблоны в папке"""
    templates = get_templates_by_folder(db, folder_id)
    return [TemplateOut.model_validate(template) for template in templates]

@router.delete("/{template_id}")
def delete_template_route(
    template_id: int, 
    db: Session = Depends(get_db), 
    user=Depends(get_current_user),
    request: Request = None
):
    """Удаляет шаблон"""
    # check_csrf(request)  # Временно отключено для тестирования
    success = delete_template(db, template_id)
    if not success:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    return {"message": "Шаблон удалён"}

@router.get("/{template_id}/fields")
def get_template_fields(template_id: int, db: Session = Depends(get_db), user=Depends(get_current_user)):
    """Получает список полей из шаблона"""
    try:
        fields = extract_fields_from_template(template_id, db)
        return {"fields": fields}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка извлечения полей: {str(e)}")

@router.post("/{template_id}/generate")
def generate_document_route(
    template_id: int,
    values: str = Form(...),  # JSON строка с значениями
    output_format: str = Form("docx"),  # Формат выходного файла: docx или pdf
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
    request: Request = None
):
    """Генерирует документ из шаблона с подстановкой значений"""
    # check_csrf(request)  # Временно отключено для тестирования
    
    try:
        values_dict = json.loads(values)
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Неверный формат JSON")
    
    # Проверяем формат
    if output_format.lower() not in ["docx", "pdf"]:
        raise HTTPException(status_code=400, detail="Поддерживаются только форматы docx и pdf")
    
    try:
        doc_bytes = generate_document_from_template(template_id, values_dict, db, output_format)
        
        # Получаем информацию о шаблону для имени файла
        from app.services.template_service import get_template_by_id
        template = get_template_by_id(db, template_id)
        if not template:
            raise HTTPException(status_code=404, detail="Шаблон не найден")
        
        original_name = template.filename
        base_name = original_name.replace('.docx', '')
        extension = '.pdf' if output_format.lower() == 'pdf' else '.docx'
        generated_name = f"generated_{base_name}{extension}"
        
        safe_ascii = generated_name.encode('ascii', 'ignore').decode('ascii') or f'contract{extension}'
        safe_utf8 = quote(generated_name)
        
        # Определяем MIME тип
        if output_format.lower() == 'pdf':
            media_type = "application/pdf"
        else:
            media_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        
        headers = {
            "Content-Disposition": f"attachment; filename={safe_ascii}; filename*=UTF-8''{safe_utf8}"
        }
        
        return StreamingResponse(
            io.BytesIO(doc_bytes),
            media_type=media_type,
            headers=headers
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка генерации документа: {str(e)}")

@router.get("/{template_id}/download")
def download_template_route(
    template_id: int,
    db: Session = Depends(get_db),
    user=Depends(get_current_user)
):
    """Скачивает оригинальный шаблон"""
    from app.services.template_service import get_template_by_id, get_template_file_path
    template = get_template_by_id(db, template_id)
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    file_path = get_template_file_path(template)
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Файл шаблона не найден")
    
    with open(file_path, "rb") as f:
        content = f.read()
    
    safe_ascii = template.filename.encode('ascii', 'ignore').decode('ascii') or 'template.docx'
    safe_utf8 = quote(template.filename)
    
    headers = {
        "Content-Disposition": f"attachment; filename={safe_ascii}; filename*=UTF-8''{safe_utf8}"
    }
    
    return StreamingResponse(
        io.BytesIO(content),
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        headers=headers
    ) 