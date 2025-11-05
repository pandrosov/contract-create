import os
import zipfile
import pandas as pd
from typing import Dict, List, Any
from sqlalchemy.orm import Session
from app.services.template_service import TemplateService
from app.utils.number_to_text import number_to_text, format_number_with_text, get_currency_declension
from datetime import datetime

class ActService:
    def __init__(self, db: Session):
        self.db = db
        self.template_service = TemplateService(db)

    def format_value(self, value, original_format=None):
        """Форматирует значение с сохранением оригинального формата"""
        if pd.isna(value):
            return ""
        
        # Если это datetime объект, форматируем как дату
        if isinstance(value, datetime):
            if original_format:
                try:
                    return value.strftime(original_format)
                except:
                    pass
            # Пытаемся определить формат из значения
            if value.hour == 0 and value.minute == 0 and value.second == 0:
                # Это дата без времени
                return value.strftime("%d.%m.%Y")
            else:
                # Это дата со временем
                return value.strftime("%d.%m.%Y %H:%M")
        
        # Если это pandas Timestamp
        if hasattr(value, 'strftime'):
            if original_format:
                try:
                    return value.strftime(original_format)
                except:
                    pass
            # Пытаемся определить формат из значения
            if hasattr(value, 'hour') and value.hour == 0 and value.minute == 0 and value.second == 0:
                # Это дата без времени
                return value.strftime("%d.%m.%Y")
            else:
                # Это дата со временем
                return value.strftime("%d.%m.%Y %H:%M")
        
        # Для остальных типов используем строковое представление
        result = str(value)
        
        # Экранируем фигурные скобки для Jinja2 (заменяем { на {{ и } на }})
        # Но избегаем двойного экранирования
        if '{' in result or '}' in result:
            result = result.replace('{', '{{').replace('}', '}}')
            # Если значение уже было экранировано, исправляем
            result = result.replace('{{{{', '{{').replace('}}}}', '}}')
        
        return result

    def analyze_excel_file(self, file) -> Dict[str, Any]:
        """Анализирует Excel файл и возвращает информацию о структуре"""
        try:
            # Читаем Excel файл
            df = pd.read_excel(file.file, engine='openpyxl')
            
            # Получаем информацию о столбцах
            columns = list(df.columns)
            
            # Получаем статистику
            total_rows = len(df)
            total_columns = len(columns)
            
            # Получаем образец данных (первые 5 строк)
            sample_data = df.head().to_dict('records')
            
            # Безопасная сериализация для JSON
            def safe_serialize(value):
                if pd.isna(value):
                    return None
                elif isinstance(value, (int, float)):
                    if pd.isna(value):
                        return None
                    return value
                else:
                    return str(value)
            
            # Обрабатываем sample_data
            processed_sample_data = []
            for row in sample_data:
                processed_row = {}
                for key, value in row.items():
                    processed_row[key] = safe_serialize(value)
                processed_sample_data.append(processed_row)
            
            # Получаем числовую статистику
            numeric_stats = {}
            for col in df.select_dtypes(include=['number']).columns:
                numeric_stats[col] = {
                    'mean': safe_serialize(df[col].mean()),
                    'min': safe_serialize(df[col].min()),
                    'max': safe_serialize(df[col].max()),
                    'std': safe_serialize(df[col].std())
                }
            
            return {
                'columns': columns,
                'total_rows': total_rows,
                'total_columns': total_columns,
                'sample_data': processed_sample_data,
                'numeric_stats': numeric_stats
            }
            
        except Exception as e:
            raise ValueError(f"Ошибка анализа Excel файла: {str(e)}")

    def analyze_data_quality(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Анализирует качество данных в Excel файле"""
        try:
            
            # Анализ качества данных
            total_rows = len(df)
            total_columns = len(df.columns)
            
            # Подсчет пустых значений
            missing_data = {}
            for col in df.columns:
                missing_count = df[col].isna().sum()
                missing_data[col] = int(missing_count)
            
            # Подсчет дубликатов
            duplicate_rows = df.duplicated().sum()
            
            # Размер файла в памяти
            memory_usage_mb = df.memory_usage(deep=True).sum() / 1024 / 1024
            
            # Безопасная сериализация
            def safe_serialize(value):
                if pd.isna(value):
                    return None
                elif isinstance(value, (int, float)):
                    if pd.isna(value):
                        return None
                    return value
                else:
                    return str(value)
            
            return {
                'analysis': {
                    'total_rows': total_rows,
                    'total_columns': total_columns,
                    'missing_data': missing_data,
                    'duplicate_rows': int(duplicate_rows),
                    'memory_usage_mb': round(memory_usage_mb, 2)
                }
            }
            
        except Exception as e:
            raise ValueError(f"Ошибка анализа качества данных: {str(e)}")

    def validate_mapping(self, df: pd.DataFrame, mapping: Dict[str, str]) -> Dict[str, Any]:
        """Валидирует маппинг плейсхолдеров со столбцами"""
        try:
            errors = []
            warnings = []
            mapped_columns = []
            
            for placeholder, column_or_value in mapping.items():
                if not placeholder:
                    errors.append(f"Пустой плейсхолдер")
                    continue
                
                if not column_or_value:
                    errors.append(f"Плейсхолдер '{placeholder}' не привязан к столбцу или значению")
                    continue
                
                # Проверяем, является ли значение названием столбца или свободным вводом
                if column_or_value in df.columns:
                    # Это столбец из Excel файла
                    mapped_columns.append(column_or_value)
                    
                    # Проверяем наличие данных в столбце
                    non_null_count = df[column_or_value].notna().sum()
                    if non_null_count == 0:
                        warnings.append(f"Столбец '{column_or_value}' для плейсхолдера '{placeholder}' не содержит данных")
                    elif non_null_count < len(df):
                        warnings.append(f"Столбец '{column_or_value}' для плейсхолдера '{placeholder}' содержит пустые значения")
                else:
                    # Это свободный ввод - проверяем, что значение не пустое
                    if not column_or_value.strip():
                        errors.append(f"Свободный ввод для плейсхолдера '{placeholder}' пустой")
                    else:
                        # Для свободного ввода не добавляем в mapped_columns, так как это не столбец
                        pass
            
            # Проверяем, что все плейсхолдеры имеют значения
            if len(mapping) == 0:
                errors.append("Не настроен ни один плейсхолдер")
            
            # Проверяем уникальность столбцов (только для столбцов, не для свободного ввода)
            column_mappings = {k: v for k, v in mapping.items() if v in df.columns}
            if len(column_mappings.values()) != len(set(column_mappings.values())):
                warnings.append("Некоторые столбцы используются для нескольких плейсхолдеров")
            
            return {
                'valid': len(errors) == 0,
                'errors': errors,
                'warnings': warnings,
                'mapped_columns': mapped_columns
            }
            
        except Exception as e:
            raise ValueError(f"Ошибка валидации маппинга: {str(e)}")

    def generate_acts(self, template_id: int, data: pd.DataFrame, mapping: Dict[str, str], 
                     output_format: str = 'docx', user_id: int = None, filename_template: str = None,
                     number_to_text_fields: list = None, currency: str = "рублей") -> str:
        """Генерирует акты на основе шаблона и данных"""
        try:
            print(f"Начало генерации актов: template_id={template_id}, rows={len(data)}")
            print(f"Маппинг: {mapping}")
            print(f"Поля для преобразования чисел: {number_to_text_fields}")
            
            # Создаем временную папку для актов
            import tempfile
            temp_dir = tempfile.mkdtemp()
            print(f"Временная папка создана: {temp_dir}")
            
            # Генерируем акты для каждой строки данных
            generated_files = []
            
            for index, row in data.iterrows():
                try:
                    print(f"Обрабатываем строку {index + 1}")
                    
                    # Подготавливаем значения для замены
                    values = {}
                    for placeholder, column_or_value in mapping.items():
                        # Проверяем, является ли значение названием столбца или свободным вводом
                        if column_or_value in data.columns:
                            # Это столбец из Excel файла
                            value = row[column_or_value]
                            
                            # Проверяем, нужно ли преобразовать число в текст
                            if number_to_text_fields and column_or_value in number_to_text_fields:
                                try:
                                    # Пытаемся преобразовать в число
                                    numeric_value = float(value) if value else 0
                                    values[placeholder] = format_number_with_text(numeric_value, currency)
                                    print(f"Преобразовано число для {placeholder}: {value} -> {values[placeholder]}")
                                except (ValueError, TypeError):
                                    # Если не удалось преобразовать в число, форматируем как обычное значение
                                    values[placeholder] = self.format_value(value)
                                    print(f"Не удалось преобразовать число для {placeholder}: {value}")
                            else:
                                # Форматируем значение с сохранением формата дат
                                values[placeholder] = self.format_value(value)
                                print(f"Обычное значение для {placeholder}: {value} -> {values[placeholder]}")
                        else:
                            # Это свободный ввод - используем значение как есть, но экранируем фигурные скобки
                            value_str = str(column_or_value)
                            # Экранируем фигурные скобки для Jinja2
                            if '{' in value_str or '}' in value_str:
                                value_str = value_str.replace('{', '{{').replace('}', '}}')
                                value_str = value_str.replace('{{{{', '{{').replace('}}}}', '}}')
                            values[placeholder] = value_str
                            print(f"Свободный ввод для {placeholder}: {column_or_value}")
                    
                    print(f"Подготовленные значения: {values}")
                    
                    # Генерируем документ
                    output_path = self.template_service.generate_document(
                        template_id=template_id,
                        values=values,
                        output_format=output_format
                    )
                    
                    print(f"Документ сгенерирован: {output_path}")
                    
                    # Формируем название файла
                    if filename_template:
                        try:
                            # Заменяем плейсхолдеры в шаблоне названия файла
                            custom_filename = filename_template
                            for key, value in values.items():
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
                            filename = f"act_{index + 1}.{output_format}"
                    else:
                        filename = f"act_{index + 1}.{output_format}"
                    
                    temp_file_path = os.path.join(temp_dir, filename)
                    
                    import shutil
                    shutil.copy2(output_path, temp_file_path)
                    generated_files.append(temp_file_path)
                    
                except Exception as e:
                    print(f"Ошибка генерации акта для строки {index + 1}: {e}")
                    continue
            
            if not generated_files:
                raise ValueError("Не удалось сгенерировать ни одного акта")
            
            # Создаем ZIP архив
            zip_path = os.path.join(temp_dir, "generated_acts.zip")
            
            with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for file_path in generated_files:
                    filename = os.path.basename(file_path)
                    zipf.write(file_path, filename)
            
            return zip_path
            
        except Exception as e:
            raise ValueError(f"Ошибка генерации актов: {str(e)}") 