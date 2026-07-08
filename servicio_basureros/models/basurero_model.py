import uuid
from sqlalchemy import Column, String, Float, Boolean, DateTime, Enum, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from database import Base
import enum


class EstadoBasurero(str, enum.Enum):
    """Estados posibles de un basurero."""
    ACTIVO = "activo"
    INACTIVO = "inactivo"
    MANTENIMIENTO = "mantenimiento"


class Basurero(Base):
    """
    Modelo para la tabla 'basureros'.
    Representa un basurero físico desplegado en una zona del campus.
    """
    __tablename__ = "basureros"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # ID público que se codifica en el QR (ej: "ESB-Q04")
    public_id = Column(String(50), unique=True, index=True, nullable=False)
    
    nombre = Column(String(200), nullable=False)
    ubicacion = Column(String(500), nullable=True)
    
    # Coordenadas GPS opcionales
    latitud = Column(Float, nullable=True)
    longitud = Column(Float, nullable=True)
    
    # Estado operativo del basurero
    estado = Column(
        Enum(EstadoBasurero, name="estado_basurero", create_constraint=True, native_enum=False),
        default=EstadoBasurero.ACTIVO,
        nullable=False
    )
    
    # Indica si un usuario está usando este basurero actualmente
    is_occupied = Column(Boolean, default=False, nullable=False)
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc),
                        onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    # Relación con sesiones
    sesiones = relationship("SesionBasurero", back_populates="basurero", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Basurero(public_id={self.public_id}, nombre={self.nombre}, estado={self.estado})>"


class SesionBasurero(Base):
    """
    Modelo para la tabla 'sesiones_basurero'.
    Representa una sesión temporal entre un usuario y un basurero.
    Tiene un token único y expira tras SESSION_DURATION_MINUTES (default: 5 min).
    """
    __tablename__ = "sesiones_basurero"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # FK al basurero
    basurero_id = Column(String, ForeignKey("basureros.id", ondelete="CASCADE"), nullable=False)
    
    # ID del usuario (viene del JWT de Supabase Auth)
    usuario_id = Column(String, nullable=False)
    
    # Token de sesión que identifica esta vinculación
    session_token = Column(String, unique=True, index=True, nullable=False,
                           default=lambda: str(uuid.uuid4()))
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    
    # Si la sesión sigue vigente (se pone False al desconectar o expirar)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relación inversa
    basurero = relationship("Basurero", back_populates="sesiones")

    def __repr__(self):
        return f"<SesionBasurero(usuario={self.usuario_id}, basurero={self.basurero_id}, activa={self.is_active})>"
