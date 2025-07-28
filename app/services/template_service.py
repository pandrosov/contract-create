import os
import shutil
from fastapi import HTTPException, UploadFile
from sqlalchemy.orm import Session
from app.models.template import Template
from app.models.folder import Folder
from docx import Document
import re
import io

TEMPLATES_BASE_DIR = "templates"
FIELD_PATTERN = re.compile(r'\{\{([^}]+)\}\}')

def ensure_folder_exists(folder_id: int) -> str:
    """Создаёт папку для шаблонов если её нет"""
    folder_path = os.path.join(TEMPLATES_BASE_DIR, str(folder_id))
    os.makedirs(folder_path, exist_ok=True)
    return folder_path

def create_template(db: Session, file: UploadFile, folder_id: int, uploaded_by: int) -> Template:
    """Создаёт шаблон, сохраняя файл в правильную папку"""
    if not file.filename.endswith('.docx'):
        raise HTTPException(status_code=400, detail="Поддерживаются только .docx файлы")
    
    folder_path = ensure_folder_exists(folder_id)
    
    # Генерируем уникальное имя файла
    base_name = os.path.splitext(file.filename)[0]
    extension = os.path.splitext(file.filename)[1]
    counter = 1
    final_filename = file.filename
    
    while os.path.exists(os.path.join(folder_path, final_filename)):
        final_filename = f"{base_name}_{counter}{extension}"
        counter += 1
    
    file_path = os.path.join(folder_path, final_filename)
    
    try:
        with open(file_path, "wb") as f:
            content = file.file.read()
            f.write(content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка сохранения файла: {str(e)}")
    
    db_template = Template(
        filename=final_filename,
        folder_id=folder_id,
        uploaded_by=uploaded_by
    )
    db.add(db_template)
    db.commit()
    db.refresh(db_template)
    return db_template

def get_templates_by_folder(db: Session, folder_id: int) -> list[Template]:
    """Получает все шаблоны в папке"""
    return db.query(Template).filter(Template.folder_id == folder_id).all()

def get_template_by_id(db: Session, template_id: int) -> Template:
    """Получает шаблон по ID"""
    return db.query(Template).filter(Template.id == template_id).first()

def delete_template(db: Session, template_id: int) -> bool:
    """Удаляет шаблон"""
    template = get_template_by_id(db, template_id)
    if not template:
        return False
    
    # Удаляем физический файл
    file_path = os.path.join(TEMPLATES_BASE_DIR, str(template.folder_id), template.filename)
    if os.path.exists(file_path):
        try:
            os.remove(file_path)
        except Exception as e:
            print(f"Ошибка удаления файла: {e}")
    
    # Удаляем запись из БД
    db.delete(template)
    db.commit()
    return True

def extract_fields_from_template(template_id: int, db: Session) -> list:
    """Извлекает поля из шаблона"""
    template = get_template_by_id(db, template_id)
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    file_path = os.path.join(TEMPLATES_BASE_DIR, str(template.folder_id), template.filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Файл шаблона не найден")
    
    try:
        with open(file_path, "rb") as f:
            doc = Document(f)
        
        fields = set()
        for para in doc.paragraphs:
            fields.update(FIELD_PATTERN.findall(para.text))
        
        for table in doc.tables:
            for row in table.rows:
                for cell in row.cells:
                    fields.update(FIELD_PATTERN.findall(cell.text))
        
        return list(fields)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка чтения шаблона: {str(e)}")

def generate_document_from_template(template_id: int, values: dict, db: Session) -> bytes:
    """Генерирует документ из шаблона с подстановкой значений"""
    template = get_template_by_id(db, template_id)
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    file_path = os.path.join(TEMPLATES_BASE_DIR, str(template.folder_id), template.filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Файл шаблона не найден")
    
    try:
        with open(file_path, "rb") as f:
            doc = Document(f)
        
        for para in doc.paragraphs:
            for key, val in values.items():
                para.text = para.text.replace(f"{{{{{key}}}}}", str(val))
        
        for table in doc.tables:
            for row in table.rows:
                for cell in row.cells:
                    for key, val in values.items():
                        cell.text = cell.text.replace(f"{{{{{key}}}}}", str(val))
        
        output = io.BytesIO()
        doc.save(output)
        output.seek(0)
        return output.getvalue()
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка генерации документа: {str(e)}")

def cleanup_folder_on_delete(folder_id: int):
    """Удаляет папку с шаблонами при удалении папки"""
    folder_path = os.path.join(TEMPLATES_BASE_DIR, str(folder_id))
    if os.path.exists(folder_path):
        try:
            shutil.rmtree(folder_path)
        except Exception as e:
            print(f"Ошибка удаления папки шаблонов: {e}") 