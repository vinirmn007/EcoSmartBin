from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import NullPool
from settings import settings

DATABASE_URL = settings.DATABASE_URL

# NullPool es ideal para entornos serverless (Cloud Run):
# - No mantiene conexiones abiertas entre peticiones
# - Evita agotar el pool de Supabase (límite de 15 en session mode)
# - Funciona perfecto con el pooler en modo transacción (puerto 6543)
engine = create_engine(
    DATABASE_URL,
    poolclass=NullPool,
    # pool_pre_ping detecta conexiones caídas antes de usarlas
    pool_pre_ping=True,
)

# 2. Creamos la fábrica de sesiones para interactuar con las tablas
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 3. Definimos la clase base de la cual heredarán todos nuestros modelos de tablas
Base = declarative_base()

# Dependencia útil para FastAPI que abre y cierra la sesión por cada petición HTTP
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()