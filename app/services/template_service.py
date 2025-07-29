import os
import shutil
from pathlib import Path
from fastapi import HTTPException, UploadFile
from sqlalchemy.orm import Session
from app.models.template import Template
from app.models.folder import Folder
from docx import Document
from docx.shared import Inches, Pt
import re
import io
from docx.oxml.shared import qn
from docx.oxml import OxmlElement
import subprocess
import tempfile

TEMPLATES_BASE_DIR = "templates"
FIELD_PATTERN = re.compile(r'\{\{([^}]+)\}\}')

def replace_text_in_run(run, old_text, new_text):
    """Заменяет текст в run с сохранением форматирования"""
    if old_text in run.text:
        run.text = run.text.replace(old_text, new_text)

def replace_text_in_paragraph(paragraph, old_text, new_text):
    """Заменяет текст в параграфе с сохранением форматирования"""
    # Проверяем, есть ли плейсхолдер в параграфе
    if old_text in paragraph.text:
        # Проходим по всем runs и заменяем текст
        for run in paragraph.runs:
            if old_text in run.text:
                run.text = run.text.replace(old_text, new_text)

def replace_text_with_formatting(paragraph, old_text, new_text):
    """Заменяет текст с сохранением оригинального форматирования"""
    print(f"Trying to replace '{old_text}' with '{new_text}' in paragraph: '{paragraph.text[:50]}...'")
    
    if old_text not in paragraph.text:
        print(f"Placeholder '{old_text}' not found in paragraph")
        return
    
    print(f"Found placeholder '{old_text}' in paragraph")
    
    # Сохраняем оригинальное форматирование параграфа
    original_paragraph_style = paragraph.style
    original_alignment = paragraph.alignment
    original_indent = paragraph.paragraph_format.left_indent
    original_space_before = paragraph.paragraph_format.space_before
    original_space_after = paragraph.paragraph_format.space_after
    
    # Сохраняем форматирование из первого run
    original_font_name = None
    original_font_size = None
    original_bold = None
    original_italic = None
    original_underline = None
    
    if paragraph.runs:
        first_run = paragraph.runs[0]
        original_font_name = first_run.font.name
        original_font_size = first_run.font.size
        original_bold = first_run.font.bold
        original_italic = first_run.font.italic
        original_underline = first_run.font.underline
    
    # Собираем весь текст параграфа
    full_text = paragraph.text
    new_full_text = full_text.replace(old_text, new_text)
    
    print(f"Full paragraph text: '{full_text}'")
    print(f"New paragraph text: '{new_full_text}'")
    
    # Очищаем параграф
    paragraph.clear()
    
    # Восстанавливаем стиль параграфа
    paragraph.style = original_paragraph_style
    paragraph.alignment = original_alignment
    paragraph.paragraph_format.left_indent = original_indent
    paragraph.paragraph_format.space_before = original_space_before
    paragraph.paragraph_format.space_after = original_space_after
    
    # Добавляем новый текст
    new_run = paragraph.add_run(new_full_text)
    
    # Применяем сохраненное форматирование или Times New Roman по умолчанию
    if original_font_name:
        new_run.font.name = original_font_name
    else:
        new_run.font.name = "Times New Roman"
    
    if original_font_size:
        new_run.font.size = original_font_size
    else:
        new_run.font.size = Pt(12)  # Размер по умолчанию
    
    if original_bold is not None:
        new_run.font.bold = original_bold
    if original_italic is not None:
        new_run.font.italic = original_italic
    if original_underline:
        new_run.font.underline = original_underline
    
    print(f"Replacement completed with preserved formatting")

def convert_docx_to_pdf(docx_bytes: bytes) -> bytes:
    """Конвертирует DOCX в PDF используя LibreOffice"""
    try:
        # Создаем временные файлы
        with tempfile.NamedTemporaryFile(suffix='.docx', delete=False) as docx_file:
            docx_file.write(docx_bytes)
            docx_path = docx_file.name
        
        pdf_path = docx_path.replace('.docx', '.pdf')
        
        # Конвертируем с помощью LibreOffice
        cmd = [
            'libreoffice', 
            '--headless', 
            '--convert-to', 'pdf', 
            '--outdir', os.path.dirname(docx_path),
            docx_path
        ]
        
        print(f"Running command: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        
        print(f"LibreOffice stdout: {result.stdout}")
        print(f"LibreOffice stderr: {result.stderr}")
        print(f"LibreOffice return code: {result.returncode}")
        
        if result.returncode != 0:
            raise Exception(f"LibreOffice conversion failed: {result.stderr}")
        
        # Проверяем, создался ли PDF файл
        if not os.path.exists(pdf_path):
            raise Exception(f"PDF file was not created at {pdf_path}")
        
        # Читаем PDF файл
        with open(pdf_path, 'rb') as f:
            pdf_bytes = f.read()
        
        print(f"PDF file size: {len(pdf_bytes)} bytes")
        
        # Удаляем временные файлы
        try:
            os.unlink(docx_path)
            os.unlink(pdf_path)
        except Exception as e:
            print(f"Warning: Could not delete temp files: {e}")
        
        return pdf_bytes
        
    except Exception as e:
        # Если конвертация не удалась, возвращаем оригинальный DOCX
        print(f"PDF conversion failed: {e}")
        return docx_bytes

def ensure_folder_exists(folder_id: int) -> str:
    """Создаёт папку для шаблонов если её нет"""
    folder_path = os.path.join(TEMPLATES_BASE_DIR, str(folder_id))
    os.makedirs(folder_path, exist_ok=True)
    return folder_path

def get_template_file_path(template: Template) -> Path:
    """Получает путь к файлу шаблона"""
    return Path(TEMPLATES_BASE_DIR) / str(template.folder_id) / template.filename

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
    file_path = get_template_file_path(template)
    if file_path.exists():
        try:
            file_path.unlink()
        except Exception as e:
            print(f"Ошибка удаления файла: {e}")
    
    # Удаляем запись из БД
    db.delete(template)
    db.commit()
    return True

def extract_fields_from_template(template_id: int, db: Session) -> list:
    """Извлекает поля из шаблона в порядке их появления в документе"""
    template = get_template_by_id(db, template_id)
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    file_path = get_template_file_path(template)
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Файл шаблона не найден")
    
    try:
        with open(file_path, "rb") as f:
            doc = Document(f)
        
        fields = []
        seen_fields = set()
        
        # Функция для добавления полей в порядке появления
        def add_fields_from_text(text):
            found_fields = FIELD_PATTERN.findall(text)
            for field in found_fields:
                if field not in seen_fields:
                    fields.append(field)
                    seen_fields.add(field)
        
        # Извлекаем поля из параграфов
        for para in doc.paragraphs:
            add_fields_from_text(para.text)
        
        # Извлекаем поля из таблиц
        for table in doc.tables:
            for row in table.rows:
                for cell in row.cells:
                    for para in cell.paragraphs:
                        add_fields_from_text(para.text)
        
        # Извлекаем поля из заголовков и футеров
        for section in doc.sections:
            for header in section.header.paragraphs:
                add_fields_from_text(header.text)
            for footer in section.footer.paragraphs:
                add_fields_from_text(footer.text)
        
        return fields
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка чтения файла: {str(e)}")

def generate_document_from_template(template_id: int, values: dict, db: Session, output_format: str = "docx") -> bytes:
    """Генерирует документ из шаблона с подстановкой значений"""
    template = get_template_by_id(db, template_id)
    if not template:
        raise HTTPException(status_code=404, detail="Шаблон не найден")
    
    file_path = get_template_file_path(template)
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Файл шаблона не найден")
    
    try:
        with open(file_path, "rb") as f:
            doc = Document(f)
        
        print(f"Starting document generation with values: {values}")
        
        # Заменяем поля в параграфах с сохранением форматирования
        for para in doc.paragraphs:
            for field in values:
                placeholder = f"{{{{{field}}}}}"
                if placeholder in para.text:
                    print(f"Found placeholder {placeholder} in paragraph")
                    replace_text_with_formatting(para, placeholder, str(values[field]))
        
        # Заменяем поля в таблицах с сохранением форматирования
        for table in doc.tables:
            for row in table.rows:
                for cell in row.cells:
                    for para in cell.paragraphs:
                        for field in values:
                            placeholder = f"{{{{{field}}}}}"
                            if placeholder in para.text:
                                replace_text_with_formatting(para, placeholder, str(values[field]))
        
        # Заменяем поля в заголовках и футерах
        for section in doc.sections:
            for header in section.header.paragraphs:
                for field in values:
                    placeholder = f"{{{{{field}}}}}"
                    if placeholder in header.text:
                        replace_text_with_formatting(header, placeholder, str(values[field]))
            
            for footer in section.footer.paragraphs:
                for field in values:
                    placeholder = f"{{{{{field}}}}}"
                    if placeholder in footer.text:
                        replace_text_with_formatting(footer, placeholder, str(values[field]))
        
        # Сохраняем в байты
        output = io.BytesIO()
        doc.save(output)
        output.seek(0)
        docx_bytes = output.getvalue()
        
        # Конвертируем в PDF если нужно
        if output_format.lower() == "pdf":
            return convert_docx_to_pdf(docx_bytes)
        else:
            return docx_bytes
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка генерации документа: {str(e)}")

def cleanup_folder_on_delete(folder_id: int):
    """Очищает папку при удалении"""
    folder_path = os.path.join(TEMPLATES_BASE_DIR, str(folder_id))
    if os.path.exists(folder_path):
        try:
            shutil.rmtree(folder_path)
        except Exception as e:
            print(f"Ошибка удаления папки: {e}") 