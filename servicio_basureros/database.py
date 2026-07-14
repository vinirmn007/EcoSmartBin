from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from settings import settings

DATABASE_URL = settings.DATABASE_URL

engine = create_engine(
    DATABASE_URL,
    # El pool_pre_ping ayuda a reconectar automáticamente si Supabase cierra la conexión por inactividad
    pool_pre_ping=True
)

# Fábrica de sesiones para interactuar con las tablas
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Clase base de la cual heredarán todos los modelos de tablas
Base = declarative_base()

# Dependencia útil para FastAPI que abre y cierra la sesión por cada petición HTTP
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
