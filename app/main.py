from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import auth, folders, templates, users, permissions, logs, acts, settings

# Импортируем все модели для правильной инициализации relationships
from app.models import user, folder, template, permission, action_log, placeholder_description
from app.models import settings as settings_model

app = FastAPI(
    title="Contract Management API",
    description="API для системы управления договорами",
    version="2.0.0",
    openapi_version="3.1.0",
    docs_url=None,  # Отключаем встроенную документацию
    redoc_url=None,  # Отключаем встроенную документацию
    openapi_url="/openapi.json"
)

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",  # Разработка
        "https://contract.alnilam.by",  # Продакшен
        "https://www.contract.alnilam.by",  # Продакшен с www
        "https://178.172.138.229",  # IP адрес
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Подключаем роутеры
app.include_router(auth.router)
app.include_router(folders.router)
app.include_router(templates.router)
app.include_router(users.router)
app.include_router(permissions.router)
app.include_router(logs.router)
app.include_router(acts.router)
app.include_router(settings.router)

@app.get("/health")
async def health_check():
    """Health check endpoint for deployment scripts"""
    return {"status": "healthy", "service": "contract-management-api"}

@app.get("/docs")
async def custom_docs():
    """Custom documentation endpoint"""
    from fastapi.responses import HTMLResponse
    from fastapi import Response
    
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Contract Management API - Swagger UI</title>
        <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui.css" />
        <style>
            html { box-sizing: border-box; overflow: -moz-scrollbars-vertical; overflow-y: scroll; }
            *, *:before, *:after { box-sizing: inherit; }
            body { margin:0; background: #fafafa; }
        </style>
    </head>
    <body>
        <div id="swagger-ui"></div>
        <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui-bundle.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5.9.0/swagger-ui-standalone-preset.js"></script>
        <script>
            window.onload = function() {
                const ui = SwaggerUIBundle({
                    url: window.location.origin + '/api/openapi.json?t=' + Date.now(),
                    dom_id: '#swagger-ui',
                    deepLinking: true,
                    presets: [
                        SwaggerUIBundle.presets.apis,
                        SwaggerUIStandalonePreset
                    ],
                    plugins: [
                        SwaggerUIBundle.plugins.DownloadUrl
                    ],
                    layout: "BaseLayout"
                });
            };
        </script>
    </body>
    </html>
    """
    return HTMLResponse(
        content=html_content,
        headers={
            "Cache-Control": "no-cache, no-store, must-revalidate",
            "Pragma": "no-cache",
            "Expires": "0"
        }
    ) 