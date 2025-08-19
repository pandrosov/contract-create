from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Dict, Any
import pandas as pd
import io
import zipfile
import tempfile
import os
from pathlib import Path
import json

from app.core.db import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.services.template_service import TemplateService
from app.services.act_service import ActService

router = APIRouter(prefix="/acts", tags=["acts"])

@router.post("/analyze-excel")
async def analyze_excel_file(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Анализирует Excel файл и возвращает список столбцов"""
    try:
        # Проверяем расширение файла
        if not file.filename.endswith(('.xlsx', '.xls')):
            raise HTTPException(status_code=400, detail="Поддерживаются только файлы Excel (.xlsx, .xls)")
        
        # Читаем содержимое файла
        content = await file.read()
        
        # Анализируем Excel файл с помощью pandas
        df = pd.read_excel(io.BytesIO(content), engine='openpyxl')
        
        # Получаем список столбцов
        columns = df.columns.tolist()
        
        # Функция для безопасной сериализации значений
        def safe_serialize(value):
            if pd.isna(value):
                return None
            elif isinstance(value, (int, float)):
                if pd.isna(value):
                    return None
                return value
            else:
                return str(value)
        
        # Получаем подробную информацию о данных с помощью pandas
        data_info = {
            "columns": columns,
            "total_rows": len(df),
            "filename": file.filename,
            "column_types": {col: str(dtype) for col, dtype in df.dtypes.to_dict().items()},
            "null_counts": {col: int(count) for col, count in df.isnull().sum().to_dict().items()},
            "unique_values": {col: int(df[col].nunique()) for col in columns if df[col].dtype == 'object'},
            "memory_usage_mb": round(df.memory_usage(deep=True).sum() / 1024 / 1024, 2)
        }
        
        # Безопасно обрабатываем числовую статистику
        numeric_df = df.select_dtypes(include=['number'])
        if numeric_df.shape[1] > 0:
            numeric_stats = {}
            for col in numeric_df.columns:
                col_stats = numeric_df[col].describe()
                numeric_stats[col] = {
                    'count': safe_serialize(col_stats.get('count')),
                    'mean': safe_serialize(col_stats.get('mean')),
                    'std': safe_serialize(col_stats.get('std')),
                    'min': safe_serialize(col_stats.get('min')),
                    '25%': safe_serialize(col_stats.get('25%')),
                    '50%': safe_serialize(col_stats.get('50%')),
                    '75%': safe_serialize(col_stats.get('75%')),
                    'max': safe_serialize(col_stats.get('max'))
                }
            data_info["numeric_stats"] = numeric_stats
        else:
            data_info["numeric_stats"] = {}
        
        # Безопасно обрабатываем примеры данных
        if len(df) > 0:
            sample_data = []
            for _, row in df.head(5).iterrows():
                sample_row = {}
                for col in df.columns:
                    sample_row[col] = safe_serialize(row[col])
                sample_data.append(sample_row)
            data_info["sample_data"] = sample_data
        else:
            data_info["sample_data"] = []
        
        return data_info
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Ошибка анализа файла: {str(e)}")

@router.post("/get-column-values")
async def get_column_values(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Получает уникальные значения для всех столбцов Excel файла"""
    try:
        # Проверяем расширение файла
        if not file.filename.endswith(('.xlsx', '.xls')):
            raise HTTPException(status_code=400, detail="Поддерживаются только файлы Excel (.xlsx, .xls)")
        
        # Читаем содержимое файла
        content = await file.read()
        
        # Анализируем Excel файл с помощью pandas
        df = pd.read_excel(io.BytesIO(content), engine='openpyxl')
        
        # Функция для безопасной сериализации значений
        def safe_serialize(value):
            if pd.isna(value):
                return None
            elif isinstance(value, (int, float)):
                if pd.isna(value):
                    return None
                return str(value)
            else:
                return str(value)
        
        # Получаем уникальные значения для каждого столбца
        column_values = {}
        for col in df.columns:
            # Получаем уникальные значения, исключая NaN
            unique_vals = df[col].dropna().unique()
            # Преобразуем в строки и сортируем
            column_values[col] = sorted([safe_serialize(val) for val in unique_vals])
        
        return {
            "column_values": column_values,
            "total_rows": len(df),
            "columns": df.columns.tolist()
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Ошибка получения значений столбцов: {str(e)}")

@router.get("/template-placeholders/{template_id}")
async def get_template_placeholders(
    template_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Получает плейсхолдеры из шаблона"""
    try:
        template_service = TemplateService(db)
        placeholders = template_service.extract_placeholders(template_id)
        
        return {
            "placeholders": placeholders,
            "template_id": template_id
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Ошибка извлечения плейсхолдеров: {str(e)}")

@router.post("/generate")
async def generate_acts(
    template_id: int = Form(...),
    excel_file: UploadFile = File(...),
    mapping: str = Form(...),
    output_format: str = Form(...),
    output_filename: str = Form(None),  # Кастомное название файла
    act_filename_template: str = Form(None),  # Шаблон названия файлов актов
    number_to_text_fields: str = Form(None),  # JSON строка с полями для преобразования в текст
    currency: str = Form("рублей"),  # Валюта для расшифровки чисел
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    # Добавляем параметры для фильтров
    filter_column_0: str = Form(None),
    filter_value_0: str = Form(None),
    filter_column_1: str = Form(None),
    filter_value_1: str = Form(None),
    filter_column_2: str = Form(None),
    filter_value_2: str = Form(None),
    filter_column_3: str = Form(None),
    filter_value_3: str = Form(None),
    filter_column_4: str = Form(None),
    filter_value_4: str = Form(None),
):
    """Генерирует акты на основе шаблона и данных из Excel"""
    print(f"Начало генерации актов: template_id={template_id}, output_format={output_format}")
    try:
        # Проверяем формат выходных файлов
        if output_format not in ['docx', 'pdf']:
            raise HTTPException(status_code=400, detail="Поддерживаются только форматы DOCX и PDF")
        
        # Парсим маппинг
        try:
            mapping_dict = json.loads(mapping)
            print(f"Маппинг успешно распарсен: {mapping_dict}")
        except json.JSONDecodeError as e:
            print(f"Ошибка парсинга маппинга: {e}")
            print(f"Сырые данные маппинга: {mapping}")
            raise HTTPException(status_code=400, detail="Неверный формат маппинга")
        
        # Читаем Excel файл с помощью pandas
        content = await excel_file.read()
        df = pd.read_excel(
            io.BytesIO(content), 
            engine='openpyxl',
            parse_dates=True,  # Автоматически определяем даты
            keep_default_na=True,  # Сохраняем NaN значения
            na_values=['', 'nan', 'NaN', 'NULL', 'null']  # Дополнительные значения для NaN
        )
        print(f"Excel файл прочитан: {len(df)} строк, {len(df.columns)} столбцов")
        print(f"Типы данных столбцов: {df.dtypes.to_dict()}")
        
        # Получаем фильтры из параметров функции
        filters = []
        for i in range(5):  # Поддерживаем до 5 фильтров
            column_param = f'filter_column_{i}'
            value_param = f'filter_value_{i}'
            
            column = locals().get(column_param)
            value = locals().get(value_param)
            
            if column and value:
                print(f"Найден фильтр {i}: column={column}, value={value}")
                filters.append({'column': column, 'value': value})
        
        print(f"Итоговые фильтры: {filters}")
        
        if not filters:
            print("Ошибка: Не указаны фильтры для генерации")
            raise HTTPException(status_code=400, detail="Не указаны фильтры для генерации")
        
        # Применяем множественные фильтры
        filtered_df = df.copy()
        print(f"Начальная фильтрация: {len(filtered_df)} строк")
        
        # Группируем фильтры по столбцам
        column_filters = {}
        for filter_item in filters:
            column = filter_item['column']
            value = filter_item['value']
            if column not in column_filters:
                column_filters[column] = []
            column_filters[column].append(value)
        
        print(f"Сгруппированные фильтры: {column_filters}")
        
        # Применяем фильтры по столбцам
        for column, values in column_filters.items():
            if column not in filtered_df.columns:
                available_columns = list(filtered_df.columns)
                raise HTTPException(
                    status_code=400, 
                    detail=f"Столбец '{column}' не найден в файле. Доступные столбцы: {available_columns}"
                )
            
            # Фильтруем данные - используем OR для множественных значений одного столбца
            mask = filtered_df[column].astype(str).isin(values)
            filtered_df = filtered_df[mask]
            print(f"После фильтра по столбцу '{column}' с значениями {values}: {len(filtered_df)} строк")
        
        if len(filtered_df) == 0:
            # Показываем уникальные значения в первом столбце для помощи пользователю
            first_filter = filters[0]
            unique_values = df[first_filter['column']].dropna().unique()[:10]  # Первые 10 значений
            raise HTTPException(
                status_code=400, 
                detail=f"Не найдено записей с указанными фильтрами. "
                       f"Доступные значения в столбце '{first_filter['column']}': {list(unique_values)}"
            )
        
        # Парсим поля для преобразования чисел в текст
        number_to_text_fields_list = []
        if number_to_text_fields:
            try:
                number_to_text_fields_list = json.loads(number_to_text_fields)
            except json.JSONDecodeError:
                print(f"Ошибка парсинга number_to_text_fields: {number_to_text_fields}")
        
        # Генерируем акты
        act_service = ActService(db)
        zip_path = act_service.generate_acts(
            template_id=template_id,
            data=filtered_df,
            mapping=mapping_dict,
            output_format=output_format,
            user_id=current_user.id,
            filename_template=act_filename_template,
            number_to_text_fields=number_to_text_fields_list,
            currency=currency
        )
        
        # Формируем название файла
        if output_filename:
            # Очищаем название от недопустимых символов
            import re
            clean_filename = re.sub(r'[<>:"/\\|?*]', '_', output_filename.strip())
            filename = f"{clean_filename}.zip"
        else:
            filename = f"generated_acts_{len(filtered_df)}_records.zip"
        
        # Возвращаем архив
        return FileResponse(
            path=zip_path,
            filename=filename,
            media_type="application/zip"
        )
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Ошибка генерации актов: {str(e)}")

@router.get("/generation-status/{task_id}")
async def get_generation_status(
    task_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Получает статус генерации актов"""
    try:
        act_service = ActService(db)
        status = act_service.get_generation_status(task_id)
        
        return {
            "task_id": task_id,
            "status": status
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Ошибка получения статуса: {str(e)}")

@router.post("/analyze-data-quality")
async def analyze_data_quality(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Анализирует качество данных в Excel файле"""
    try:
        # Проверяем расширение файла
        if not file.filename.endswith(('.xlsx', '.xls')):
            raise HTTPException(status_code=400, detail="Поддерживаются только файлы Excel (.xlsx, .xls)")
        
        # Читаем содержимое файла
        content = await file.read()
        df = pd.read_excel(io.BytesIO(content), engine='openpyxl')
        
        # Функция для безопасной сериализации значений
        def safe_serialize(value):
            if pd.isna(value):
                return None
            elif isinstance(value, (int, float)):
                if pd.isna(value):
                    return None
                return value
            else:
                return str(value)
        
        # Анализируем качество данных
        act_service = ActService(db)
        analysis = act_service.analyze_data_quality(df)
        
        # Безопасно обрабатываем числовую статистику
        if "numeric_stats" in analysis:
            safe_numeric_stats = {}
            for col, stats in analysis["numeric_stats"].items():
                safe_stats = {}
                for stat_name, stat_value in stats.items():
                    safe_stats[stat_name] = safe_serialize(stat_value)
                safe_numeric_stats[col] = safe_stats
            analysis["numeric_stats"] = safe_numeric_stats
        
        return {
            "filename": file.filename,
            "analysis": analysis
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Ошибка анализа данных: {str(e)}")

@router.post("/validate-mapping")
async def validate_mapping(
    file: UploadFile = File(...),
    mapping: str = Form(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Проверяет корректность маппинга с данными"""
    try:
        # Парсим маппинг
        try:
            mapping_dict = json.loads(mapping)
        except json.JSONDecodeError:
            raise HTTPException(status_code=400, detail="Неверный формат маппинга")
        
        # Читаем Excel файл
        content = await file.read()
        df = pd.read_excel(io.BytesIO(content), engine='openpyxl')
        
        # Проверяем маппинг
        act_service = ActService(db)
        validation = act_service.validate_mapping(df, mapping_dict)
        
        return {
            "filename": file.filename,
            "validation": validation
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Ошибка валидации маппинга: {str(e)}") 