from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from settings import settings
from routes import usuario_routes
from database import Base, engine

# Sincroniza el modelo con la base de datos al arrancar
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="EcoSmartBin API",
    description="Backend core para la gestión y clasificación inteligente de residuos",
    version="0.1.0"
)
app.include_router(usuario_routes.router)

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