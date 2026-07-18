"""
Configuración compartida (fixtures) para todas las pruebas del servicio de basureros.

Usa una base de datos SQLite en memoria para no depender de PostgreSQL/Supabase,
y sobreescribe las dependencias de autenticación para no necesitar tokens reales.
"""
import sys
import os
from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# ─── Agregar el directorio raíz del servicio al path ─────────────
# Esto permite que los imports como `from database import ...` funcionen
# sin necesidad de instalar el paquete.
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# ─── Parchear settings ANTES de importar cualquier módulo del servicio ───
# Esto evita que pydantic-settings intente leer el .env real con credenciales
# de Supabase/PostgreSQL que no existen en el entorno de CI.
os.environ.setdefault("SUPABASE_URL", "https://fake.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "fake-key")
os.environ.setdefault("SUPABASE_JWT_SECRET", "fake-jwt-secret")
os.environ.setdefault("DATABASE_URL", "sqlite:///./test.db")
os.environ.setdefault("ENV", "dev")

from database import Base, get_db  # noqa: E402
from auth.dependencies import get_current_user, require_admin  # noqa: E402
from main import app  # noqa: E402


# ═══════════════════════════════════════════════
# Base de datos de prueba (SQLite en memoria)
# ═══════════════════════════════════════════════

SQLALCHEMY_TEST_URL = "sqlite:///./test.db"

test_engine = create_engine(
    SQLALCHEMY_TEST_URL,
    connect_args={"check_same_thread": False},  # Necesario para SQLite + threading
)

TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

# ─── Parche para que SQLite devuelva datetimes con timezone (UTC) ───
# SQLite no almacena información de zona horaria. Parcheamos directamente
# las columnas DateTime de los modelos para que tengan timezone=True.
# Esto se hace importando los modelos y modificando las columnas antes
# de crear las tablas con create_all().
from models.basurero_model import Basurero, SesionBasurero  # noqa: E402
from sqlalchemy import inspect as sa_inspect, TypeDecorator, DateTime as _SADateTime, Table, Column, String

# Registrar una tabla ficticia 'perfiles' en la metadata de Base para que las FKs se resuelvan en los tests de SQLite
if "perfiles" not in Base.metadata.tables:
    Table(
        "perfiles",
        Base.metadata,
        Column("id", String, primary_key=True)
    )

class TZDateTime(TypeDecorator):
    impl = _SADateTime
    cache_ok = True

    def process_result_value(self, value, dialect):
        if value is not None:
            if not value.tzinfo:
                value = value.replace(tzinfo=timezone.utc)
        return value

def _patch_datetime_columns_to_utc(*models):
    """Reemplaza los tipos DateTime por TZDateTime en los modelos."""
    for model in models:
        mapper = sa_inspect(model)
        for col in mapper.columns:
            if isinstance(col.type, _SADateTime):
                col.type = TZDateTime()

_patch_datetime_columns_to_utc(Basurero, SesionBasurero)


# ═══════════════════════════════════════════════
# Mocks de autenticación
# ═══════════════════════════════════════════════

def fake_current_user():
    """Simula un usuario autenticado normal."""
    return {
        "user_id": "test-user-001",
        "email": "testuser@ecosmartbin.com",
        "role": "user",
    }


def fake_admin_user():
    """Simula un usuario autenticado con rol de administrador."""
    return {
        "user_id": "test-admin-001",
        "email": "admin@ecosmartbin.com",
        "role": "admin",
    }


# ═══════════════════════════════════════════════
# Fixtures de pytest
# ═══════════════════════════════════════════════

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
def client(db_session):
    """
    TestClient de FastAPI que inyecta la base de datos de prueba
    y los mocks de autenticación.
    """
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    # Sobreescribir las dependencias reales por las de prueba
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user] = fake_current_user
    app.dependency_overrides[require_admin] = fake_admin_user

    with TestClient(app) as test_client:
        yield test_client

    # Limpiar las sobreescrituras después del test
    app.dependency_overrides.clear()


@pytest.fixture
def basurero_data():
    """Datos de ejemplo para crear un basurero en los tests."""
    return {
        "public_id": "ESB-TEST-01",
        "nombre": "Basurero de Prueba - Entrada Principal",
        "ubicacion": "Entrada principal del campus UNL",
        "latitud": -4.0079,
        "longitud": -79.2113,
        "estado": "activo",
    }


@pytest.fixture
def basurero_creado(client, basurero_data):
    """Crea un basurero en la DB y lo retorna como dict (respuesta JSON)."""
    response = client.post("/bins", json=basurero_data)
    assert response.status_code == 201
    return response.json()
