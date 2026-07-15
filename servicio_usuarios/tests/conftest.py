"""
Configuración compartida (fixtures) para las pruebas del servicio de usuarios.
Usa una base de datos SQLite en memoria y mockea el cliente de Supabase.
"""
import sys
import os
from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# ─── Agregar el directorio raíz del servicio al path ─────────────
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# ─── Parchear settings ANTES de importar cualquier módulo del servicio ───
os.environ.setdefault("SUPABASE_URL", "https://fake.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "fake-key")
os.environ.setdefault("SUPABASE_JWT_SECRET", "fake-jwt-secret")
os.environ.setdefault("DATABASE_URL", "sqlite:///./test.db")
os.environ.setdefault("ENV", "dev")

# ─── Mockear Supabase Client ANTES de importar dependencias ───
# Como supabase.create_client se ejecuta a nivel de módulo en routes.usuario_routes,
# lo interceptamos y mockeamos para evitar peticiones HTTP reales.
import supabase
original_create_client = supabase.create_client

mock_auth = MagicMock()
mock_supabase_client_instance = MagicMock()
mock_supabase_client_instance.auth = mock_auth

def fake_create_client(supabase_url: str, supabase_key: str):
    return mock_supabase_client_instance

# Reemplazamos temporalmente la función a nivel de librería
supabase.create_client = fake_create_client

from database import Base, get_db  # noqa: E402
from main import app  # noqa: E402

# Restauramos la función original por seguridad
supabase.create_client = original_create_client

# Base de datos de prueba (SQLite en memoria)
SQLALCHEMY_TEST_URL = "sqlite:///./test.db"
test_engine = create_engine(
    SQLALCHEMY_TEST_URL,
    connect_args={"check_same_thread": False},
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


@pytest.fixture(scope="function")
def db_session():
    """
    Crea todas las tablas antes de cada test y las elimina después.
    Devuelve una sesión de base de datos limpia.
    """
    Base.metadata.create_all(bind=test_engine)
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=test_engine)


@pytest.fixture(scope="function")
def mock_supabase():
    """
    Fixture para interactuar y configurar las respuestas del mock de Supabase Auth
    en cada caso de prueba individual.
    """
    mock_auth.reset_mock(return_value=True, side_effect=True)
    # Limpiar side_effects y configurar valores de retorno limpios por defecto
    mock_auth.get_user.side_effect = None
    mock_auth.get_user.return_value = MagicMock()
    mock_auth.sign_up.side_effect = None
    mock_auth.sign_up.return_value = MagicMock()
    mock_auth.sign_in_with_password.side_effect = None
    mock_auth.sign_in_with_password.return_value = MagicMock()
    mock_auth.reset_password_for_email.side_effect = None
    mock_auth.reset_password_for_email.return_value = MagicMock()
    mock_auth.update_user.side_effect = None
    mock_auth.update_user.return_value = MagicMock()
    yield mock_auth


@pytest.fixture(scope="function")
def client(db_session):
    """
    TestClient de FastAPI que inyecta la base de datos de prueba.
    """
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
