import re
from pydantic import BaseModel, EmailStr, field_validator

class UserRegisterSchema(BaseModel):
    email: EmailStr
    password: str
    nombres: str
    apellidos: str
    cedula: str
    telefono: str = None
    facultad: str = None
    captcha_token: str = None

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("La contraseña debe tener al menos 6 caracteres.")
        if not re.search(r'[A-Z]', v):
            raise ValueError("La contraseña debe contener al menos una letra mayúscula.")
        if not re.search(r'[^a-zA-Z0-9]', v):
            raise ValueError("La contraseña debe contener al menos un carácter especial.")
        return v


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