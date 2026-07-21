from fastapi import FastAPI
from contextlib import asynccontextmanager

try:
    import logic
    from routes import router
except ImportError:
    from . import logic
    from .routes import router

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Maneja el ciclo de vida de la app cargando el modelo ONNX en startup y liberándolo en shutdown.
    """
    logic.load_model()
    yield
    logic.unload_model()

app = FastAPI(
    title="Optimized Garbage Classification API",
    description="Multi-engine ONNX inference service (YOLOv26 & ViT).",
    lifespan=lifespan
)

# Incluir las rutas
app.include_router(router)