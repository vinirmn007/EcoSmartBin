import os
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    SUPABASE_URL: str
    SUPABASE_KEY: str
    SUPABASE_JWT_SECRET: str
    DATABASE_URL: str

    # Entorno actual: 'dev' o 'prod' (por defecto 'dev' si no se especifica)
    ENV: str = "dev"

    # Duración de la sesión basurero-usuario en minutos
    SESSION_DURATION_MINUTES: int = 5

    # URL del servicio de usuarios (para validaciones futuras)
    USERS_SERVICE_URL: str = "http://localhost:8000"

    # Lista de orígenes para producción (separados por comas en el .env)
    ALLOWED_ORIGINS_PROD: str = ""

    # Propiedad calculada dinámicamente para los orígenes de CORS
    @property
    def CORS_ORIGINS(self) -> List[str]:
        if self.ENV.lower() == "dev":
            return [
                "http://localhost",
                "http://localhost:8000",
                "http://localhost:3000",
                "http://localhost:8080",
                "http://localhost:8081",
                "http://localhost:8082",
                "http://127.0.0.1",
                "*"
            ]
        else:
            if not self.ALLOWED_ORIGINS_PROD:
                return []
            return [origin.strip() for origin in self.ALLOWED_ORIGINS_PROD.split(",")]

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
