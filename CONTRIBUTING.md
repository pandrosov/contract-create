# Руководство по участию в разработке

Спасибо за интерес к проекту Contract Management System! Мы приветствуем любой вклад в развитие проекта.

## 🚀 Как начать

1. **Форкните репозиторий**
2. **Клонируйте ваш форк**
   ```bash
   git clone https://github.com/your-username/contract-management-system.git
   cd contract-management-system
   ```
3. **Создайте ветку для новой функции**
   ```bash
   git checkout -b feature/amazing-feature
   ```

## 🛠 Разработка

### Настройка окружения

1. **Запустите проект локально**
   ```bash
   docker-compose up --build -d
   ```

2. **Инициализируйте базу данных**
   ```bash
   docker-compose exec backend python init_db.py
   docker-compose exec backend python activate_admin.py
   ```

3. **Откройте приложение**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000

### Структура проекта

```
create_document/
├── app/                    # Backend (FastAPI)
│   ├── api/               # API endpoints
│   ├── core/              # Основные модули
│   ├── models/            # SQLAlchemy модели
│   ├── schemas/           # Pydantic схемы
│   └── services/          # Бизнес-логика
├── frontend/              # Frontend (React)
│   └── src/
│       ├── api/          # API клиенты
│       ├── components/   # React компоненты
│       ├── pages/        # Страницы
│       └── context/      # React контексты
└── templates/             # Хранилище шаблонов
```

## 📝 Стиль кода

### Python (Backend)
- Используйте **Black** для форматирования
- Следуйте **PEP 8** для стиля кода
- Добавляйте **type hints** где возможно
- Пишите **docstrings** для функций

### JavaScript/React (Frontend)
- Используйте **Prettier** для форматирования
- Следуйте **ESLint** правилам
- Используйте **functional components** с hooks
- Добавляйте **PropTypes** для компонентов

## 🧪 Тестирование

### Backend тесты
```bash
# Запуск тестов
docker-compose exec backend python -m pytest

# Покрытие кода
docker-compose exec backend python -m pytest --cov=app
```

### Frontend тесты
```bash
# Запуск тестов
docker-compose exec frontend npm test

# Покрытие кода
docker-compose exec frontend npm test -- --coverage
```

## 🔧 Добавление новых функций

### 1. Backend
1. **Создайте модель** в `app/models/`
2. **Добавьте схему** в `app/schemas/`
3. **Создайте сервис** в `app/services/`
4. **Добавьте API endpoint** в `app/api/`
5. **Напишите тесты**

### 2. Frontend
1. **Создайте компонент** в `frontend/src/components/`
2. **Добавьте страницу** в `frontend/src/pages/`
3. **Создайте API клиент** в `frontend/src/api/`
4. **Обновите роутинг** в `App.js`
5. **Напишите тесты**

### 3. Пример добавления новой функции

```python
# app/models/new_feature.py
from sqlalchemy import Column, Integer, String
from app.core.db import Base

class NewFeature(Base):
    __tablename__ = "new_features"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
```

```python
# app/schemas/new_feature.py
from pydantic import BaseModel

class NewFeatureCreate(BaseModel):
    name: str

class NewFeatureOut(NewFeatureCreate):
    id: int
    model_config = {"from_attributes": True}
```

```python
# app/api/new_feature.py
from fastapi import APIRouter, Depends
from app.schemas.new_feature import NewFeatureCreate, NewFeatureOut

router = APIRouter(prefix="/new-features", tags=["new-features"])

@router.post("/", response_model=NewFeatureOut)
def create_new_feature(feature: NewFeatureCreate):
    # Логика создания
    pass
```

## 🐛 Сообщение об ошибках

При сообщении об ошибке, пожалуйста, включите:

1. **Описание проблемы**
2. **Шаги для воспроизведения**
3. **Ожидаемое поведение**
4. **Фактическое поведение**
5. **Версии компонентов**
6. **Логи ошибок**

## 📋 Pull Request

1. **Обновите документацию** если необходимо
2. **Добавьте тесты** для новой функциональности
3. **Убедитесь, что все тесты проходят**
4. **Обновите CHANGELOG.md** если необходимо
5. **Создайте Pull Request** с описанием изменений

### Шаблон Pull Request

```markdown
## Описание
Краткое описание изменений

## Тип изменений
- [ ] Исправление ошибки
- [ ] Новая функция
- [ ] Улучшение документации
- [ ] Рефакторинг

## Тестирование
- [ ] Добавлены тесты
- [ ] Все тесты проходят
- [ ] Протестировано локально

## Документация
- [ ] Обновлена документация
- [ ] Обновлен README.md
```

## 📞 Связь

- **Issues**: Используйте GitHub Issues для сообщений об ошибках
- **Discussions**: Используйте GitHub Discussions для вопросов
- **Email**: [your-email@example.com]

## 📄 Лицензия

Участвуя в проекте, вы соглашаетесь с условиями MIT License.

Спасибо за ваш вклад! 🎉 