"""
Tests para los endpoints de sesiones usuario ↔ basurero.
Cubre: conectar, extender sesión, desconectar y consultar estado.
También prueba el endpoint interno servicio-a-servicio.
"""
from datetime import datetime, timezone, timedelta
from models.basurero_model import SesionBasurero


class TestConectarUsuario:
    """Pruebas para POST /bins/{public_id}/connect"""

    def test_conectar_exitoso(self, client, basurero_creado):
        """Debe crear una sesión y retornar los datos de conexión."""
        public_id = basurero_creado["public_id"]
        response = client.post(f"/bins/{public_id}/connect")
        assert response.status_code == 200

        data = response.json()
        assert "session_token" in data
        assert data["basurero_public_id"] == public_id
        assert data["usuario_id"] == "test-user-001"
        assert "expires_at" in data

    def test_conectar_basurero_no_existente(self, client):
        """Debe retornar 404 si el basurero no existe."""
        response = client.post("/bins/NO-EXISTE-999/connect")
        assert response.status_code == 404

    def test_conectar_basurero_inactivo(self, client, basurero_creado):
        """Debe retornar 400 si el basurero está inactivo."""
        public_id = basurero_creado["public_id"]
        # Desactivar el basurero (soft delete)
        client.delete(f"/bins/{public_id}")
        # Intentar conectar
        response = client.post(f"/bins/{public_id}/connect")
        assert response.status_code == 400

    def test_reconectar_mismo_usuario_devuelve_sesion_existente(self, client, basurero_creado):
        """Si el mismo usuario intenta conectar de nuevo, debe devolver la sesión existente."""
        public_id = basurero_creado["public_id"]
        # Primera conexión
        resp1 = client.post(f"/bins/{public_id}/connect")
        token1 = resp1.json()["session_token"]
        # Segunda conexión (mismo usuario)
        resp2 = client.post(f"/bins/{public_id}/connect")
        token2 = resp2.json()["session_token"]
        # Debe ser el mismo token de sesión
        assert token1 == token2


class TestDesconectarUsuario:
    """Pruebas para POST /bins/{public_id}/disconnect"""

    def test_desconectar_exitoso(self, client, basurero_creado):
        """Debe cerrar la sesión activa y liberar el basurero."""
        public_id = basurero_creado["public_id"]
        # Conectar primero
        client.post(f"/bins/{public_id}/connect")
        # Desconectar
        response = client.post(f"/bins/{public_id}/disconnect")
        assert response.status_code == 200
        assert "desconectado" in response.json()["message"].lower()

    def test_desconectar_sin_sesion_activa(self, client, basurero_creado):
        """Debe retornar 404 si no hay sesión activa para desconectar."""
        public_id = basurero_creado["public_id"]
        response = client.post(f"/bins/{public_id}/disconnect")
        assert response.status_code == 404

    def test_desconectar_basurero_no_existente(self, client):
        """Debe retornar 404 si el basurero no existe."""
        response = client.post("/bins/NO-EXISTE-999/disconnect")
        assert response.status_code == 404


class TestExtenderSesion:
    """Pruebas para POST /bins/{public_id}/extend"""

    def test_extender_sesion_exitoso(self, client, basurero_creado):
        """Debe extender la sesión y devolver un nuevo expires_at."""
        public_id = basurero_creado["public_id"]
        # Conectar
        resp_connect = client.post(f"/bins/{public_id}/connect")
        expires_original = resp_connect.json()["expires_at"]
        # Extender
        resp_extend = client.post(f"/bins/{public_id}/extend")
        assert resp_extend.status_code == 200
        expires_nuevo = resp_extend.json()["expires_at"]
        # El nuevo expires_at debe ser posterior al original
        assert expires_nuevo >= expires_original

    def test_extender_sin_sesion_retorna_404(self, client, basurero_creado):
        """Debe retornar 404 si no hay sesión activa para extender."""
        public_id = basurero_creado["public_id"]
        response = client.post(f"/bins/{public_id}/extend")
        assert response.status_code == 404


class TestEstadoBasurero:
    """Pruebas para GET /bins/{public_id}/status"""

    def test_estado_basurero_libre(self, client, basurero_creado):
        """Un basurero sin sesión debe mostrarse como no ocupado."""
        public_id = basurero_creado["public_id"]
        response = client.get(f"/bins/{public_id}/status")
        assert response.status_code == 200

        data = response.json()
        assert data["public_id"] == public_id
        assert data["is_occupied"] is False
        assert data["usuario_id"] is None
        assert data["session_token"] is None

    def test_estado_basurero_ocupado(self, client, basurero_creado):
        """Un basurero con sesión activa debe mostrarse como ocupado."""
        public_id = basurero_creado["public_id"]
        # Conectar
        client.post(f"/bins/{public_id}/connect")
        # Consultar estado
        response = client.get(f"/bins/{public_id}/status")
        assert response.status_code == 200

        data = response.json()
        assert data["is_occupied"] is True
        assert data["usuario_id"] == "test-user-001"
        assert data["session_token"] is not None
        assert data["seconds_remaining"] is not None
        assert data["seconds_remaining"] > 0

    def test_estado_basurero_no_existente(self, client):
        """Debe retornar 404 si el basurero no existe."""
        response = client.get("/bins/NO-EXISTE-999/status")
        assert response.status_code == 404


class TestEndpointInterno:
    """Pruebas para GET /internal/bins/{bin_public_id}/session"""

    def test_sesion_interna_con_sesion_activa(self, client, basurero_creado):
        """Debe retornar la sesión activa para validación servicio-a-servicio."""
        public_id = basurero_creado["public_id"]
        # Conectar usuario
        client.post(f"/bins/{public_id}/connect")
        # Consultar internamente
        response = client.get(f"/internal/bins/{public_id}/session")
        assert response.status_code == 200

        data = response.json()
        assert data["basurero_public_id"] == public_id
        assert data["usuario_id"] == "test-user-001"
        assert data["is_active"] is True

    def test_sesion_interna_sin_sesion_retorna_404(self, client, basurero_creado):
        """Debe retornar 404 si no hay sesión activa."""
        public_id = basurero_creado["public_id"]
        response = client.get(f"/internal/bins/{public_id}/session")
        assert response.status_code == 404

    def test_sesion_interna_basurero_no_existente(self, client):
        """Debe retornar 404 si el basurero no existe."""
        response = client.get("/internal/bins/NO-EXISTE-999/session")
        assert response.status_code == 404
