from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse, JSONResponse
from sqlalchemy.orm import Session
from typing import List
import os
import shutil
import zipfile
from app.core.db import get_db
from app.models.template import Template
from app.models.folder import Folder
from app.services.template_service import TemplateService
from app.services.placeholder_service import PlaceholderService
from app.api.auth import get_current_user
from app.models.user import User
import datetime

router = APIRouter(prefix="/templates", tags=["templates"])

def format_datetime(dt):
    """Форматирует дату в читаемый формат для фронтенда"""
    if dt is None:
        return None
    if isinstance(dt, str):
        return dt
    # Форматируем в формат ДД.ММ.ГГГГ ЧЧ:ММ
    return dt.strftime("%d.%m.%Y %H:%M")

@router.post("/upload")
async def upload_template(
    file: UploadFile = File(...),
    folder_id: int = Form(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Загружает шаблон в указанную папку"""
    if not file.filename.endswith('.docx'):
        raise HTTPException(status_code=400, detail="Поддерживаются только .docx файлы")
    
    # Проверяем существование папки
    folder = db.query(Folder).filter(Folder.id == folder_id).first()
    if not folder:
        raise HTTPException(status_code=404, detail="Папка не найдена")
    
    try:
        template_service = TemplateService(db)
        template = template_service.upload_template(file, folder_id, current_user.id)
        
        return {
            "message": "Шаблон успешно загружен",
            "template": {
                "id": template.id,
                "filename": template.filename,
                "folder_id": template.folder_id,
                "uploaded_at": format_datetime(template.uploaded_at)
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка загрузки шаблона: {str(e)}")

@router.get("/", response_model=None)
async def get_templates(db: Session = Depends(get_db)):
    """Получает все шаблоны"""
    template_service = TemplateService(db)
    templates = template_service.get_all_templates()
    
    result = {
        "data": [
            {
                "id": template.id,
                "filename": template.filename,
                "folder_id": template.folder_id,
                "uploaded_by": template.uploaded_by,
                "uploaded_at": format_datetime(template.uploaded_at)
            }
            for template in templates
        ]
    }
    return JSONResponse(content=result)

@router.get("/folder/{folder_id}", response_model=None)
async def get_templates_by_folder(folder_id: int, db: Session = Depends(get_db)):
    """Получает шаблоны в папке"""
    template_service = TemplateService(db)
    templates = template_service.get_templates_by_folder(folder_id)
    
    result = {
        "data": [
            {
                "id": template.id,
                "filename": template.filename,
                "folder_id": template.folder_id,
                "uploaded_by": template.uploaded_by,
                "uploaded_at": format_datetime(template.uploaded_at)
            }
            for template in templates
        ]
    }
    return JSONResponse(content=result)

@router.delete("/{template_id}")
async def delete_template(
    template_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Удаляет шаблон"""
    template_service = TemplateService(db)
    template = template_service.get_template_by_id(template_id)
    
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    if template.uploaded_by != current_user.id:
        raise HTTPException(status_code=403, detail="Нет прав для удаления этого шаблона")
    
    success = template_service.delete_template(template_id)
    if not success:
        raise HTTPException(status_code=500, detail="Ошибка удаления шаблона")
    
    return {"message": "Шаблон успешно удален"}

@router.get("/{template_id}/fields")
async def get_template_fields(template_id: int, db: Session = Depends(get_db)):
    """Извлекает поля из шаблона"""
    template_service = TemplateService(db)
    placeholder_service = PlaceholderService(db)
    template = template_service.get_template_by_id(template_id)
    
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    try:
        placeholders = template_service.extract_placeholders(template_id)
        descriptions = placeholder_service.get_descriptions_dict(template_id)
        
        # Объединяем плейсхолдеры с описаниями
        fields_with_descriptions = []
        for placeholder in placeholders:
            fields_with_descriptions.append({
                "name": placeholder,
                "description": descriptions.get(placeholder, "")
            })
        
        return {"data": fields_with_descriptions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка извлечения полей: {str(e)}")

@router.post("/{template_id}/generate")
async def generate_document(
    template_id: int,
    values: str = Form(...),  # JSON строка с значениями
    output_format: str = Form("docx"),
    filename_template: str = Form(None),  # Шаблон названия файла
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Генерирует документ из шаблона"""
    import json
    
    template_service = TemplateService(db)
    template = template_service.get_template_by_id(template_id)
    
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    try:
        # Парсим JSON с значениями
        values_dict = json.loads(values)
        
        # Генерируем документ
        output_path = template_service.generate_document(
            template_id=template_id,
            values=values_dict,
            output_format=output_format
        )
        
        # Формируем название файла
        if filename_template:
            try:
                # Заменяем плейсхолдеры в шаблоне названия файла
                custom_filename = filename_template
                for key, value in values_dict.items():
                    placeholder = f"{{{{{key}}}}}"
                    custom_filename = custom_filename.replace(placeholder, str(value))
                
                # Убираем недопустимые символы для имени файла
                import re
                custom_filename = re.sub(r'[<>:"/\\|?*]', '_', custom_filename)
                custom_filename = custom_filename.strip()
                
                # Добавляем расширение
                if not custom_filename.endswith(f'.{output_format}'):
                    custom_filename += f'.{output_format}'
                
                filename = custom_filename
            except Exception as e:
                print(f"Ошибка формирования названия файла: {e}")
                filename = os.path.basename(output_path)
        else:
            filename = os.path.basename(output_path)
        
        return FileResponse(
            path=output_path,
            filename=filename,
            media_type="application/octet-stream"
        )
        
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Неверный формат JSON")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка генерации документа: {str(e)}")

@router.get("/{template_id}/placeholder-descriptions")
async def get_placeholder_descriptions(
    template_id: int,
    db: Session = Depends(get_db)
):
    """Получает описания плейсхолдеров для шаблона"""
    # Проверяем существование шаблона
    template = db.query(Template).filter(Template.id == template_id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    placeholder_service = PlaceholderService(db)
    descriptions = placeholder_service.get_descriptions_dict(template_id)
    
    return {"data": descriptions}

@router.post("/{template_id}/placeholder-descriptions")
async def create_placeholder_description(
    template_id: int,
    placeholder_name: str = Form(...),
    description: str = Form(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Создает или обновляет описание плейсхолдера"""
    # Проверяем существование шаблона
    template = db.query(Template).filter(Template.id == template_id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    placeholder_service = PlaceholderService(db)
    
    try:
        result = placeholder_service.create_or_update_description(
            template_id=template_id,
            placeholder_name=placeholder_name,
            description=description
        )
        
        return {
            "message": "Описание плейсхолдера сохранено",
            "data": {
                "id": result.id,
                "placeholder_name": result.placeholder_name,
                "description": result.description
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка сохранения описания: {str(e)}")

@router.delete("/{template_id}/placeholder-descriptions/{placeholder_name}")
async def delete_placeholder_description(
    template_id: int,
    placeholder_name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Удаляет описание плейсхолдера"""
    # Проверяем существование шаблона
    template = db.query(Template).filter(Template.id == template_id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    placeholder_service = PlaceholderService(db)
    
    success = placeholder_service.delete_description(template_id, placeholder_name)
    
    if success:
        return {"message": "Описание плейсхолдера удалено"}
    else:
        raise HTTPException(status_code=404, detail="Описание не найдено") 