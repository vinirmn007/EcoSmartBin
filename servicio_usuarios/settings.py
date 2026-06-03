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
    
    # Lista de orígenes para producción (separados por comas en el .env)
    # Ejemplo en .env: ALLOWED_ORIGINS_PROD=https://ecosmartbin.web.app,https://admin.ecosmartbin.edu
    ALLOWED_ORIGINS_PROD: str = ""

    # Propiedad calculada dinámicamente para los orígenes de CORS
    @property
    def CORS_ORIGINS(self) -> List[str]:
        if self.ENV.lower() == "dev":
            # En desarrollo permitimos orígenes comunes de localhost (Flutter web, React, etc.) y comodines
            return [
                "http://localhost",
                "http://localhost:8000",
                "http://localhost:3000",
                "http://127.0.0.1",
                "*" # Permite cualquier origen temporalmente en desarrollo local
            ]
        else:
            # En producción, transformamos el string del .env en una lista real limpia
            if not self.ALLOWED_ORIGINS_PROD:
                return []
            return [origin.strip() for origin in self.ALLOWED_ORIGINS_PROD.split(",")]

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()