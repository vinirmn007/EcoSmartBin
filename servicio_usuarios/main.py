import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from settings import settings
from routes import usuario_routes
from database import Base, engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Sincroniza el modelo con la base de datos al arrancar
    try:
        logger.info("Intentando conectar a la base de datos y crear tablas...")
        # Nota: create_all es sincrono, idealmente se ejecuta en un hilo o se usa alembic
        Base.metadata.create_all(bind=engine)
        logger.info("Conexión a la base de datos exitosa. Tablas sincronizadas.")
    except Exception as e:
        logger.error(f"Error crítico al conectar a la base de datos: {e}")
    yield

app = FastAPI(
    title="EcoSmartBin API",
    description="Backend core para la gestión y clasificación inteligente de residuos",
    version="0.1.0",
    lifespan=lifespan
)
app.include_router(usuario_routes.router)

# --- MÉTRICAS DE PROMETHEUS ---
# Instrumentar la aplicación para recolectar métricas HTTP automáticamente.
# Expondrá los datos en la ruta /metrics para que Prometheus los raspe.
Instrumentator().instrument(app).expose(app)

# --- CONFIGURACIÓN DINÁMICA DE CORS ---
# Si settings.CORS_ORIGINS contiene ["*"], allow_credentials DEBE ser False por especificación de seguridad.
# Manejamos esa regla de manera automática:
allow_all = "*" in settings.CORS_ORIGINS

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=not allow_all,  # True en prod con dominios fijos, False si se usa "*" en dev
    allow_methods=["*"],              # Permite todos los métodos (GET, POST, PUT, DELETE, etc.)
    allow_headers=["*"],              # Permite todas las cabeceras (incluyendo Authorization Bearer JWT)
)


@app.get("/")
def read_root():
    return {
        "message": "Bienvenido al Backend de Ussuarios EcoSmartBin API v1",
        "environment": settings.ENV.lower()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)