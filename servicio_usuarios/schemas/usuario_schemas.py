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

    @field_validator("cedula")
    @classmethod
    def validate_cedula(cls, v: str) -> str:
        clean = v.strip()
        if not re.match(r'^\d{10}$', clean):
            raise ValueError("La cédula debe contener exactamente 10 dígitos numéricos.")
        return clean

    @field_validator("telefono")
    @classmethod
    def validate_telefono(cls, v: str) -> str:
        if not v:
            return v
        clean = v.strip()
        if not re.match(r'^09\d{8}$', clean):
            raise ValueError("El teléfono debe tener 10 dígitos y empezar con 09.")
        return clean


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