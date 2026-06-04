from sqlalchemy import Column, String, Integer, DateTime, Boolean
from datetime import datetime
from database import Base

class PerfilUsuario(Base):
    __tablename__ = "perfiles"

    # ID proveniente de Supabase Auth
    id = Column(String, primary_key=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    
    nombres = Column(String, nullable=False)
    apellidos = Column(String, nullable=False)
    cedula = Column(String, unique=True, index=True, nullable=False) 
    
    facultad = Column(String, nullable=True) 
    
    role = Column(String, default="user", nullable=False) 
    
    puntos_ecologicos = Column(Integer, default=0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    def __repr__(self):
        return f"<PerfilUsuario(email={self.email}, nombres={self.nombres}, puntos={self.puntos_ecologicos})>"