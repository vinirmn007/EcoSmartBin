from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from sqlalchemy import text
from supabase import create_client, Client
from schemas.usuario_schemas import UserRegisterSchema, UserLoginSchema, RecoverPasswordSchema, ResetPasswordSchema
from supabase_auth import UserAttributes
from models.usuario_model import PerfilUsuario 
from database import get_db
from settings import settings
from logger import business_logger

supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

router = APIRouter(
    prefix="/auth",
    tags=["Autenticación y Usuarios"]
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido, alterado o expirado.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    print(f"DEBUG BACKEND: get_current_user convocado. Token recibido (truncado): {token[:20]}...")
    try:
        # Validamos llamando directamente a la API de Supabase Auth para verificar el token
        user_response = supabase.auth.get_user(token)
        user = user_response.user
        
        user_id: str = user.id
        email: str = user.email
        
        user_metadata = user.user_metadata or {}
        role: str = user_metadata.get("role", "user")
        
        if user_id is None:
            print("DEBUG BACKEND: El ID del usuario verificado es Nulo.")
            raise credentials_exception
            
        print(f"DEBUG BACKEND: Token verificado con éxito en Supabase para: {email} ({user_id})")
        return {"user_id": user_id, "email": email, "role": role}
    except Exception as e:
        print(f"DEBUG BACKEND: Error al validar token con Supabase: {str(e)}")
        raise credentials_exception




@router.post("/register", status_code=status.HTTP_201_CREATED)
def register_user(user_data: UserRegisterSchema, db: Session = Depends(get_db)):
    """
    Registra al usuario en Supabase Auth y crea en paralelo su perfil 
    detallado en la base de datos PostgreSQL de Supabase usando SQLAlchemy.
    """
    try:
        # 1. Verificar si la cédula o el correo ya existen en nuestra base de datos local
        usuario_existente = db.query(PerfilUsuario).filter(
            (PerfilUsuario.cedula == user_data.cedula) | (PerfilUsuario.email == user_data.email)
        ).first()
        if usuario_existente:
            if usuario_existente.cedula == user_data.cedula:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="La cédula ingresada ya se encuentra registrada."
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="El correo electrónico ingresado ya se encuentra registrado."
                )

        # 2. Registrar las credenciales en Supabase Auth
        supabase_response = supabase.auth.sign_up({
            "email": user_data.email,
            "password": user_data.password,
            "options": {
                "data": {
                    "role": "user"
                },
                "email_redirect_to": "https://ecosmartbin2.web.app/email-verified"
            }
        })
        
        # Extraemos el ID único generado por Supabase para mapearlo
        supabase_uid = supabase_response.user.id


        nuevo_perfil = PerfilUsuario(
            id=supabase_uid,
            email=user_data.email,
            nombres=user_data.nombres,
            apellidos=user_data.apellidos,
            cedula=user_data.cedula,
            telefono=user_data.telefono,
            facultad=user_data.facultad,
            role="user"
        )
        
        db.add(nuevo_perfil)
        db.commit()
        db.refresh(nuevo_perfil)

        business_logger.info("Nuevo usuario registrado en el sistema", extra={
            "event_type": "USER_CREATED",
            "user_email": nuevo_perfil.email,
            "user_id": nuevo_perfil.id,
            "role": nuevo_perfil.role
        })

        return {
            "message": "Usuario y perfil creados exitosamente en el ecosistema EcoSmartBin.",
            "user_id": nuevo_perfil.id,
            "nombres": nuevo_perfil.nombres,
            "email": nuevo_perfil.email
        }

    except HTTPException as http_ex:
        # Re-lanzar excepciones HTTP controladas por nosotros (ej: Cédula duplicada)
        raise http_ex
    except Exception as e:
        db.rollback()  # Si algo falló en la BD relacional, cancelamos la transacción
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error en el proceso de registro: {str(e)}"
        )


@router.post("/login")
def login_user(user_data: UserLoginSchema):
    """
    Autentica al usuario en Supabase y le entrega su JWT Token para la App.
    """
    try:
        response = supabase.auth.sign_in_with_password({
            "email": user_data.email,
            "password": user_data.password
        })
        
        business_logger.info("Usuario inició sesión", extra={
            "event_type": "USER_LOGIN_SUCCESS",
            "user_email": response.user.email,
            "user_id": response.user.id
        })
        
        return {
            "access_token": response.session.access_token,
            "token_type": "bearer",
            "refresh_token": response.session.refresh_token,
            "user": {
                "id": response.user.id,
                "email": response.user.email,
                "role": response.user.user_metadata.get("role", "user")
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Credenciales incorrectas o cuenta no verificada. Detalle: {str(e)}"
        )


@router.get("/me")
def get_my_profile(current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Trae la información combinada del JWT y los datos guardados en la tabla perfiles.
    """
    print(f"DEBUG BACKEND: get_my_profile convocado para usuario: {current_user}")
    try:
        perfil = db.query(PerfilUsuario).filter(PerfilUsuario.id == current_user["user_id"]).first()
        if not perfil:
            print(f"DEBUG BACKEND: No se encontró perfil en PostgreSQL para el ID: {current_user['user_id']}")
            raise HTTPException(status_code=404, detail="Perfil no encontrado en la base de datos.")
        
        print(f"DEBUG BACKEND: Perfil encontrado en base de datos: {perfil}")
        return {
            "user_id": perfil.id,
            "email": perfil.email,
            "nombres": perfil.nombres,
            "apellidos": perfil.apellidos,
            "cedula": perfil.cedula,
            "telefono": perfil.telefono,
            "facultad": perfil.facultad,
            "role": perfil.role,
            "puntos_ecologicos": perfil.puntos_ecologicos,
            "is_active": perfil.is_active,
            "created_at": perfil.created_at
        }
    except Exception as e:
        print(f"DEBUG BACKEND: Error en get_my_profile: {str(e)}")
        raise e


@router.post("/email-reset-password")
def send_email_reset_password(data: RecoverPasswordSchema):
    """
    Envía un correo de recuperación de contraseña a través de Supabase Auth.
    """
    try:
        options = {}
        if data.redirect_url:
            options["redirect_to"] = data.redirect_url
        
        supabase.auth.reset_password_for_email(data.email, options=options)
        
        business_logger.info("Usuario solicitó recuperación de contraseña", extra={
            "event_type": "PASSWORD_RESET_REQUESTED",
            "user_email": data.email
        })
        
        return {"message": "Correo de recuperación enviado exitosamente."}
    except Exception as e:
        print(f"DEBUG BACKEND: Error en recover_password: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al enviar correo de recuperación: {str(e)}"
        )


@router.post("/change-password")
def change_password(data: ResetPasswordSchema):
    """
    Actualiza la contraseña del usuario utilizando los tokens de recuperación
    (access_token y refresh_token) que Supabase generó en el enlace del correo.
    """
    try:
        # Creamos un cliente temporal para asociarlo con la sesión del token de recuperación
        temp_supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        temp_supabase.auth.set_session(data.access_token, data.refresh_token)
        
        # Actualizamos la contraseña del usuario autenticado con la sesión de recuperación
        user_response = temp_supabase.auth.update_user(UserAttributes(password=data.new_password))
        
        user = user_response.user
        business_logger.info("Usuario cambió su contraseña exitosamente", extra={
            "event_type": "PASSWORD_CHANGED",
            "user_email": user.email if user else "Desconocido",
            "user_id": user.id if user else "Desconocido"
        })
        
        return {"message": "Contraseña restablecida exitosamente."}
    except Exception as e:
        print(f"DEBUG BACKEND: Error en change_password: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al restablecer la contraseña: {str(e)}"
        )


# ═══════════════════════════════════════════════
# UTILERÍAS DE ADMINISTRACIÓN DE USUARIOS
# ═══════════════════════════════════════════════

def require_admin(current_user: dict = Depends(get_current_user)) -> dict:
    if current_user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Operación no autorizada. Se requieren privilegios de administrador."
        )
    return current_user


@router.get("/users", response_model=None)
def list_users(
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """
    Lista todos los usuarios registrados en el sistema (perfiles).
    Solo accesible para administradores.
    """
    try:
        users = db.query(PerfilUsuario).order_by(PerfilUsuario.created_at.desc()).all()
        return [
            {
                "id": u.id,
                "email": u.email,
                "nombres": u.nombres,
                "apellidos": u.apellidos,
                "cedula": u.cedula,
                "telefono": u.telefono,
                "facultad": u.facultad,
                "role": u.role,
                "puntos_ecologicos": u.puntos_ecologicos,
                "is_active": u.is_active,
                "created_at": u.created_at
            }
            for u in users
        ]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al listar usuarios: {str(e)}"
        )


@router.put("/users/{user_id}", response_model=None)
def update_user_admin(
    user_id: str,
    data: dict,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """
    Actualiza la información de un usuario desde el panel de admin.
    Actualiza tanto 'perfiles' como 'auth.users' de Supabase directamente vía SQL.
    """
    try:
        perfil = db.query(PerfilUsuario).filter(PerfilUsuario.id == user_id).first()
        if not perfil:
            raise HTTPException(status_code=404, detail="Usuario no encontrado.")
        
        email = data.get("email")
        nombres = data.get("nombres")
        apellidos = data.get("apellidos")
        cedula = data.get("cedula")
        telefono = data.get("telefono")
        facultad = data.get("facultad")
        role = data.get("role")
        is_active = data.get("is_active")

        # 1. Actualizar perfiles local
        if email is not None:
            perfil.email = email
        if nombres is not None:
            perfil.nombres = nombres
        if apellidos is not None:
            perfil.apellidos = apellidos
        if cedula is not None:
            perfil.cedula = cedula
        if telefono is not None:
            perfil.telefono = telefono
        if facultad is not None:
            perfil.facultad = facultad
        if role is not None:
            perfil.role = role
        if is_active is not None:
            perfil.is_active = is_active
        
        db.commit()

        # 2. Sincronizar con auth.users en Supabase directamente por SQL
        if email is not None:
            db.execute(
                text("UPDATE auth.users SET email = :email WHERE id = :uid"),
                {"email": email, "uid": user_id}
            )
        
        if role is not None:
            db.execute(
                text("""
                    UPDATE auth.users 
                    SET raw_user_meta_data = jsonb_set(
                        COALESCE(raw_user_meta_data, '{}'::jsonb), 
                        '{role}', 
                        :role
                    ) 
                    WHERE id = :uid
                """),
                {"role": f'"{role}"', "uid": user_id}
            )
        
        db.commit()
        return {"message": "Usuario actualizado exitosamente."}
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al actualizar usuario: {str(e)}"
        )


@router.delete("/users/{user_id}", response_model=None)
def delete_user_admin(
    user_id: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """
    Elimina un usuario y su perfil tanto de la tabla local como de auth.users de Supabase.
    """
    try:
        perfil = db.query(PerfilUsuario).filter(PerfilUsuario.id == user_id).first()
        if not perfil:
            raise HTTPException(status_code=404, detail="Usuario no encontrado.")
        
        # 1. Eliminar perfil de 'perfiles'
        db.delete(perfil)
        db.commit()

        # 2. Eliminar usuario de 'auth.users'
        db.execute(
            text("DELETE FROM auth.users WHERE id = :uid"),
            {"uid": user_id}
        )
        db.commit()

        return {"message": "Usuario eliminado exitosamente."}
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Error al eliminar usuario: {str(e)}"
        )