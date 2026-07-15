import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from settings import settings
from routes.basurero_routes import router, internal_router
from database import Base, engine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Sincroniza los modelos con la base de datos al arrancar
    try:
        logger.info("Intentando conectar a la base de datos y crear tablas de basureros...")
        # Importar modelos para que SQLAlchemy los registre antes de create_all
        from models.basurero_model import Basurero, SesionBasurero  # noqa: F401
        Base.metadata.create_all(bind=engine)
        logger.info("Conexión a la base de datos exitosa. Tablas de basureros sincronizadas.")
    except Exception as e:
        logger.error(f"Error crítico al conectar a la base de datos: {e}")
    yield

app = FastAPI(
    title="EcoSmartBin - Servicio de Basureros",
    description="Microservicio para la gestión de basureros inteligentes, sesiones de usuario y vinculación por QR",
    version="0.1.0",
    lifespan=lifespan
)

# Registrar routers
app.include_router(router)
app.include_router(internal_router)

# --- MÉTRICAS DE PROMETHEUS ---
Instrumentator().instrument(app).expose(app)

# --- CONFIGURACIÓN DINÁMICA DE CORS ---
allow_all = "*" in settings.CORS_ORIGINS

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=not allow_all,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def read_root():
    return {
        "message": "Bienvenido al Servicio de Basureros EcoSmartBin API v1",
        "environment": settings.ENV.lower()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8082, reload=True)
