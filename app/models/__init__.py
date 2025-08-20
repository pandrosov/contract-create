# Импорты всех моделей для правильной инициализации базы данных
from .user import User
from .folder import Folder
from .template import Template
from .permission import Permission
from .action_log import ActionLog
from .settings import Settings
from .placeholder_description import PlaceholderDescription
from .log import Log

__all__ = [
    "User",
    "Folder", 
    "Template",
    "Permission",
    "ActionLog",
    "Settings",
    "PlaceholderDescription",
    "Log"
] 