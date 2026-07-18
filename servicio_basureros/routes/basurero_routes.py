import uuid
from datetime import datetime, timezone, timedelta
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from settings import settings
from logger import business_logger
from auth.dependencies import get_current_user, require_admin
from models.basurero_model import Basurero, SesionBasurero, EstadoBasurero
from schemas.basurero_schemas import (
    BasureroCreateSchema,
    BasureroUpdateSchema,
    BasureroResponseSchema,
    SesionConnectResponseSchema,
    SesionStatusResponseSchema,
    SesionInternalResponseSchema,
)

router = APIRouter(
    prefix="/bins",
    tags=["Basureros"]
)

internal_router = APIRouter(
    prefix="/internal/bins",
    tags=["Interno - Servicio a Servicio"]
)


# ═══════════════════════════════════════════════
# CRUD DE BASUREROS (Solo Admin)
# ═══════════════════════════════════════════════

@router.post("", status_code=status.HTTP_201_CREATED, response_model=BasureroResponseSchema)
def crear_basurero(
    data: BasureroCreateSchema,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Crea un nuevo basurero. Solo administradores."""
    # Verificar que el public_id no exista
    existente = db.query(Basurero).filter(Basurero.public_id == data.public_id).first()
    if existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Ya existe un basurero con el ID público '{data.public_id}'."
        )

    nuevo = Basurero(
        public_id=data.public_id,
        nombre=data.nombre,
        ubicacion=data.ubicacion,
        latitud=data.latitud,
        longitud=data.longitud,
        estado=data.estado.value,
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    business_logger.info("Basurero creado", extra={
        "event_type": "BIN_CREATED",
        "public_id": nuevo.public_id,
        "admin_email": admin["email"]
    })

    return nuevo


@router.get("", response_model=List[BasureroResponseSchema])
def listar_basureros(
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Lista todos los basureros registrados. Solo administradores."""
    return db.query(Basurero).order_by(Basurero.created_at.desc()).all()


@router.get("/{public_id}", response_model=BasureroResponseSchema)
def obtener_basurero(
    public_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Obtiene los detalles de un basurero por su ID público."""
    basurero = db.query(Basurero).filter(Basurero.public_id == public_id).first()
    if not basurero:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Basurero con ID público '{public_id}' no encontrado."
        )
    return basurero


@router.put("/{public_id}", response_model=BasureroResponseSchema)
def actualizar_basurero(
    public_id: str,
    data: BasureroUpdateSchema,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Actualiza un basurero existente. Solo administradores."""
    basurero = db.query(Basurero).filter(Basurero.public_id == public_id).first()
    if not basurero:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Basurero con ID público '{public_id}' no encontrado."
        )

    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        if value is not None:
            # Convertir enum a string para la columna estado
            setattr(basurero, field, value.value if hasattr(value, 'value') else value)

    basurero.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(basurero)

    business_logger.info("Basurero actualizado", extra={
        "event_type": "BIN_UPDATED",
        "public_id": basurero.public_id,
        "admin_email": admin["email"]
    })

    return basurero


@router.delete("/{public_id}", status_code=status.HTTP_200_OK)
def eliminar_basurero(
    public_id: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Desactiva un basurero (soft delete → estado 'inactivo'). Solo administradores."""
    basurero = db.query(Basurero).filter(Basurero.public_id == public_id).first()
    if not basurero:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Basurero con ID público '{public_id}' no encontrado."
        )

    # Si tiene sesión activa, cerrarla primero
    _cerrar_sesiones_activas(basurero.id, db)

    basurero.estado = EstadoBasurero.INACTIVO.value
    basurero.is_occupied = False
    basurero.updated_at = datetime.now(timezone.utc)
    db.commit()

    business_logger.info("Basurero desactivado", extra={
        "event_type": "BIN_DEACTIVATED",
        "public_id": basurero.public_id,
        "admin_email": admin["email"]
    })

    return {"message": f"Basurero '{public_id}' desactivado exitosamente."}


# ═══════════════════════════════════════════════
# SESIONES USUARIO ↔ BASURERO
# ═══════════════════════════════════════════════

@router.post("/{public_id}/connect", response_model=SesionConnectResponseSchema)
def conectar_usuario(
    public_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Vincula al usuario autenticado con un basurero mediante escaneo de QR.
    Crea una sesión temporal (por defecto 5 minutos).
    Si el basurero ya está en uso, retorna 409 Conflict.
    """
    """
    Row level lock de la fila del basurero en la base de datos para evitar condiciones de carrera
    """
    basurero = db.query(Basurero).with_for_update().filter(Basurero.public_id == public_id).first()
    if not basurero:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Basurero '{public_id}' no encontrado."
        )

    # Verificar que el basurero esté activo
    if basurero.estado != EstadoBasurero.ACTIVO.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El basurero '{public_id}' no está disponible. Estado actual: {basurero.estado}."
        )

    # Limpiar sesiones expiradas antes de verificar ocupación
    _limpiar_sesiones_expiradas(basurero.id, db)

    # Verificar que no esté ocupado por otro usuario
    if basurero.is_occupied:
        sesion_activa = db.query(SesionBasurero).filter(
            SesionBasurero.basurero_id == basurero.id,
            SesionBasurero.is_active == True
        ).first()

        if sesion_activa:
            # Si es el mismo usuario, retornar la sesión existente
            if sesion_activa.usuario_id == current_user["user_id"]:
                return SesionConnectResponseSchema(
                    message="Ya tienes una sesión activa con este basurero.",
                    session_token=sesion_activa.session_token,
                    basurero_public_id=basurero.public_id,
                    basurero_nombre=basurero.nombre,
                    usuario_id=current_user["user_id"],
                    created_at=sesion_activa.created_at,
                    expires_at=sesion_activa.expires_at
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Este basurero está siendo utilizado por otro usuario. Intenta de nuevo en unos minutos."
                )

    # Crear nueva sesión
    ahora = datetime.now(timezone.utc)
    nueva_sesion = SesionBasurero(
        basurero_id=basurero.id,
        usuario_id=current_user["user_id"],
        session_token=str(uuid.uuid4()),
        created_at=ahora,
        expires_at=ahora + timedelta(minutes=settings.SESSION_DURATION_MINUTES),
        is_active=True
    )

    basurero.is_occupied = True
    basurero.updated_at = ahora

    db.add(nueva_sesion)
    db.commit()
    db.refresh(nueva_sesion)

    business_logger.info("Usuario conectado a basurero", extra={
        "event_type": "BIN_SESSION_STARTED",
        "public_id": basurero.public_id,
        "user_id": current_user["user_id"],
        "session_token": nueva_sesion.session_token
    })

    return SesionConnectResponseSchema(
        message="Conexión exitosa. Puedes depositar tu desecho.",
        session_token=nueva_sesion.session_token,
        basurero_public_id=basurero.public_id,
        basurero_nombre=basurero.nombre,
        usuario_id=current_user["user_id"],
        created_at=nueva_sesion.created_at,
        expires_at=nueva_sesion.expires_at
    )


@router.post("/{public_id}/extend", response_model=SesionConnectResponseSchema)
def extender_sesion(
    public_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Extiende la sesión activa del usuario con el basurero por 5 minutos más.
    Solo el usuario que tiene la sesión activa puede extenderla.
    """
    basurero = db.query(Basurero).with_for_update().filter(Basurero.public_id == public_id).first()
    if not basurero:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Basurero '{public_id}' no encontrado."
        )

    sesion = db.query(SesionBasurero).filter(
        SesionBasurero.basurero_id == basurero.id,
        SesionBasurero.usuario_id == current_user["user_id"],
        SesionBasurero.is_active == True
    ).first()

    if not sesion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No tienes una sesión activa con este basurero."
        )

    # Verificar que la sesión no haya expirado
    ahora = datetime.now(timezone.utc)
    if sesion.expires_at < ahora:
        sesion.is_active = False
        basurero.is_occupied = False
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="Tu sesión ha expirado. Escanea el QR nuevamente para reconectarte."
        )

    # Extender la sesión
    sesion.expires_at = ahora + timedelta(minutes=settings.SESSION_DURATION_MINUTES)
    db.commit()
    db.refresh(sesion)

    business_logger.info("Sesión de basurero extendida", extra={
        "event_type": "BIN_SESSION_EXTENDED",
        "public_id": basurero.public_id,
        "user_id": current_user["user_id"]
    })

    return SesionConnectResponseSchema(
        message=f"Sesión extendida por {settings.SESSION_DURATION_MINUTES} minutos más.",
        session_token=sesion.session_token,
        basurero_public_id=basurero.public_id,
        basurero_nombre=basurero.nombre,
        usuario_id=current_user["user_id"],
        created_at=sesion.created_at,
        expires_at=sesion.expires_at
    )


@router.post("/{public_id}/disconnect")
def desconectar_usuario(
    public_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Desconecta al usuario del basurero y libera el recurso.
    Solo el usuario con sesión activa puede desconectarse.
    """
    basurero = db.query(Basurero).with_for_update().filter(Basurero.public_id == public_id).first()
    if not basurero:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Basurero '{public_id}' no encontrado."
        )

    sesion = db.query(SesionBasurero).filter(
        SesionBasurero.basurero_id == basurero.id,
        SesionBasurero.usuario_id == current_user["user_id"],
        SesionBasurero.is_active == True
    ).first()

    if not sesion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No tienes una sesión activa con este basurero."
        )

    sesion.is_active = False
    basurero.is_occupied = False
    basurero.updated_at = datetime.now(timezone.utc)
    db.commit()

    business_logger.info("Usuario desconectado de basurero", extra={
        "event_type": "BIN_SESSION_ENDED",
        "public_id": basurero.public_id,
        "user_id": current_user["user_id"]
    })

    return {"message": f"Desconectado exitosamente del basurero '{public_id}'."}


@router.get("/{public_id}/status", response_model=SesionStatusResponseSchema)
def estado_basurero(
    public_id: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    Consulta el estado de un basurero: si está libre u ocupado,
    y si tiene sesión activa muestra el tiempo restante.
    """
    basurero = db.query(Basurero).filter(Basurero.public_id == public_id).first()
    if not basurero:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Basurero '{public_id}' no encontrado."
        )

    # Limpiar sesiones expiradas
    _limpiar_sesiones_expiradas(basurero.id, db)

    sesion_activa = db.query(SesionBasurero).filter(
        SesionBasurero.basurero_id == basurero.id,
        SesionBasurero.is_active == True
    ).first()

    seconds_remaining = None
    if sesion_activa:
        ahora = datetime.now(timezone.utc)
        delta = (sesion_activa.expires_at - ahora).total_seconds()
        seconds_remaining = max(0, int(delta))

    return SesionStatusResponseSchema(
        public_id=basurero.public_id,
        nombre=basurero.nombre,
        estado=basurero.estado,
        is_occupied=basurero.is_occupied,
        usuario_id=sesion_activa.usuario_id if sesion_activa else None,
        session_token=sesion_activa.session_token if sesion_activa else None,
        expires_at=sesion_activa.expires_at if sesion_activa else None,
        seconds_remaining=seconds_remaining
    )


# ═══════════════════════════════════════════════
# ENDPOINT INTERNO (Servicio-a-Servicio)
# ═══════════════════════════════════════════════

@internal_router.get("/{bin_public_id}/session", response_model=SesionInternalResponseSchema)
def verificar_sesion_activa(
    bin_public_id: str,
    db: Session = Depends(get_db)
):
    """
    Endpoint interno para que el servicio_AI verifique si un basurero
    tiene una sesión activa antes de procesar una imagen.
    
    NO requiere autenticación JWT (es comunicación servicio-a-servicio).
    Retorna 404 si no hay sesión activa o si el basurero no existe.
    """

    """
    Row level lock del basurero en la base de datos para evitar condiciones de carrera
    """
    basurero = db.query(Basurero).with_for_update().filter(Basurero.public_id == bin_public_id).first()
    if not basurero:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Basurero '{bin_public_id}' no registrado en el sistema."
        )

    # Limpiar expiradas
    _limpiar_sesiones_expiradas(basurero.id, db)

    sesion = db.query(SesionBasurero).filter(
        SesionBasurero.basurero_id == basurero.id,
        SesionBasurero.is_active == True
    ).first()

    if not sesion:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No hay sesión activa para el basurero '{bin_public_id}'. El usuario debe escanear el QR primero."
        )

    # Verificar que no haya expirado
    ahora = datetime.now(timezone.utc)
    if sesion.expires_at < ahora:
        sesion.is_active = False
        basurero.is_occupied = False
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"La sesión del basurero '{bin_public_id}' ha expirado."
        )

    return SesionInternalResponseSchema(
        basurero_id=basurero.id,
        basurero_public_id=basurero.public_id,
        usuario_id=sesion.usuario_id,
        session_token=sesion.session_token,
        is_active=True,
        expires_at=sesion.expires_at
    )


# ═══════════════════════════════════════════════
# FUNCIONES AUXILIARES
# ═══════════════════════════════════════════════

def _limpiar_sesiones_expiradas(basurero_id: str, db: Session):
    ahora = datetime.now(timezone.utc)
    
    # Actualización masiva y atómica directa en SQL
    filas_afectadas = db.query(SesionBasurero).filter(
        SesionBasurero.basurero_id == basurero_id,
        SesionBasurero.is_active == True,
        SesionBasurero.expires_at < ahora
    ).update({"is_active": False}, synchronize_session=False)

    # Si se expiró alguna sesión, verificamos si debemos liberar el basurero
    if filas_afectadas > 0:
        activa = db.query(SesionBasurero).filter(
            SesionBasurero.basurero_id == basurero_id,
            SesionBasurero.is_active == True
        ).first()

        if not activa:
            db.query(Basurero).filter(Basurero.id == basurero_id).update({"is_occupied": False})

    db.commit()

def _cerrar_sesiones_activas(basurero_id: str, db: Session):
    """Cierra todas las sesiones activas de un basurero."""
    sesiones = db.query(SesionBasurero).filter(
        SesionBasurero.basurero_id == basurero_id,
        SesionBasurero.is_active == True
    ).all()

    for sesion in sesiones:
        sesion.is_active = False

    db.commit()
