import os

class Settings:
    PROJECT_NAME: str = "Contract Service"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "supersecretkey")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./service.db")
    TEMPLATES_DIR: str = os.getenv("TEMPLATES_DIR", "templates")
    COOKIE_SECURE: bool = os.getenv("COOKIE_SECURE", "true").lower() in ("1", "true", "yes", "on")
    CORS_ORIGINS: list[str] = [
        origin.strip()
        for origin in os.getenv(
            "CORS_ORIGINS",
            "https://contract.alnilam.by,https://www.contract.alnilam.by"
        ).split(",")
        if origin.strip()
    ]

settings = Settings() 