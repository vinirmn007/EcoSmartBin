from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from supabase import create_client, Client
from settings import settings

supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    """
    Valida el JWT de Supabase y retorna los datos del usuario autenticado.
    Reutiliza la misma lógica de validación que servicio_usuarios.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token inválido, alterado o expirado.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        user_response = supabase.auth.get_user(token)
        user = user_response.user

        user_id: str = user.id
        email: str = user.email

        user_metadata = user.user_metadata or {}
        role: str = user_metadata.get("role", "user")

        if user_id is None:
            raise credentials_exception

        return {"user_id": user_id, "email": email, "role": role}
    except Exception:
        raise credentials_exception


def require_admin(current_user: dict = Depends(get_current_user)) -> dict:
    """
    Dependencia que exige que el usuario autenticado tenga rol 'admin'.
    Se usa en los endpoints CRUD de basureros.
    """
    if current_user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso denegado. Se requiere rol de administrador."
        )
    return current_user
