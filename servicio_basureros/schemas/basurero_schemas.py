from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


# ─────────────────────────────────────────────
# Enums
# ─────────────────────────────────────────────

class EstadoBasureroEnum(str, Enum):
    activo = "activo"
    inactivo = "inactivo"
    mantenimiento = "mantenimiento"


# ─────────────────────────────────────────────
# Schemas de Basurero (CRUD)
# ─────────────────────────────────────────────

class BasureroCreateSchema(BaseModel):
    """Schema para crear un nuevo basurero."""
    public_id: str = Field(..., min_length=2, max_length=50, description="ID público para el QR (ej: ESB-Q04)")
    nombre: str = Field(..., min_length=2, max_length=200, description="Nombre descriptivo del basurero")
    ubicacion: Optional[str] = Field(None, max_length=500, description="Ubicación textual")
    latitud: Optional[float] = Field(None, description="Coordenada GPS latitud")
    longitud: Optional[float] = Field(None, description="Coordenada GPS longitud")
    estado: EstadoBasureroEnum = Field(EstadoBasureroEnum.activo, description="Estado operativo")


class BasureroUpdateSchema(BaseModel):
    """Schema para actualizar un basurero existente."""
    nombre: Optional[str] = Field(None, min_length=2, max_length=200)
    ubicacion: Optional[str] = Field(None, max_length=500)
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    estado: Optional[EstadoBasureroEnum] = None


class BasureroResponseSchema(BaseModel):
    """Schema de respuesta con los datos de un basurero."""
    id: str
    public_id: str
    nombre: str
    ubicacion: Optional[str] = None
    latitud: Optional[float] = None
    longitud: Optional[float] = None
    estado: str
    is_occupied: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────────
# Schemas de Sesión
# ─────────────────────────────────────────────

class SesionConnectResponseSchema(BaseModel):
    """Respuesta al conectar un usuario con un basurero."""
    message: str
    session_token: str
    basurero_public_id: str
    basurero_nombre: str
    usuario_id: str
    created_at: datetime
    expires_at: datetime


class SesionStatusResponseSchema(BaseModel):
    """Estado actual de un basurero (si está ocupado, tiempo restante, etc.)."""
    public_id: str
    nombre: str
    estado: str
    is_occupied: bool
    usuario_id: Optional[str] = None
    session_token: Optional[str] = None
    expires_at: Optional[datetime] = None
    seconds_remaining: Optional[int] = None


class SesionInternalResponseSchema(BaseModel):
    """Respuesta interna para validación servicio-a-servicio (servicio_AI)."""
    basurero_id: str
    basurero_public_id: str
    usuario_id: str
    session_token: str
    is_active: bool
    expires_at: datetime
