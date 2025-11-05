# Импортируем все модели для правильной инициализации relationships
# Порядок импорта важен: сначала базовые модели без зависимостей, потом зависимые

# Базовые модели (без relationships к другим моделям)
from app.models.settings import Settings
from app.models.action_log import ActionLog
from app.models.placeholder_description import PlaceholderDescription

# Модели с зависимостями (User должен быть первым, так как на него ссылаются другие)
from app.models.user import User
from app.models.folder import Folder
from app.models.template import Template
from app.models.permission import Permission

__all__ = ['User', 'Folder', 'Template', 'Permission', 'ActionLog', 'PlaceholderDescription', 'Settings'] 