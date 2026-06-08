from pydantic import BaseModel, EmailStr

class UserRegisterSchema(BaseModel):
    email: EmailStr
    password: str          # Mínimo 6 caracteres (regla de Supabase)
    nombres: str
    apellidos: str
    cedula: str
    facultad: str = None              # Opcional, puede ser None


class UserLoginSchema(BaseModel):
    email: EmailStr
    password: str


class RecoverPasswordSchema(BaseModel):
    email: EmailStr
    redirect_url: str = None


class ResetPasswordSchema(BaseModel):
    access_token: str
    refresh_token: str
    new_password: str