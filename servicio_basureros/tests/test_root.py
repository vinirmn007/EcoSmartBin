"""
Tests para el endpoint raíz (/) de la aplicación FastAPI.
Verifica que el servicio levanta correctamente y responde
con la información básica esperada.
"""


class TestRootEndpoint:
    """Pruebas para GET /"""

    def test_root_devuelve_200(self, client):
        """El endpoint raíz debe responder con HTTP 200 OK."""
        response = client.get("/")
        assert response.status_code == 200

    def test_root_contiene_mensaje_bienvenida(self, client):
        """La respuesta debe contener el mensaje de bienvenida del servicio."""
        response = client.get("/")
        data = response.json()
        assert "message" in data
        assert "Bienvenido" in data["message"] or "EcoSmartBin" in data["message"]

    def test_root_contiene_environment(self, client):
        """La respuesta debe indicar el entorno actual (dev/prod)."""
        response = client.get("/")
        data = response.json()
        assert "environment" in data
        assert data["environment"] in ("dev", "prod")
