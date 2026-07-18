"""
Tests para los endpoints CRUD de basureros (/bins).
Cubre: crear, listar, obtener por ID, actualizar y eliminar (soft delete).
"""


class TestCrearBasurero:
    """Pruebas para POST /bins"""

    def test_crear_basurero_exitoso(self, client, basurero_data):
        """Debe crear un basurero y retornar 201 con los datos correctos."""
        response = client.post("/bins", json=basurero_data)
        assert response.status_code == 201

        data = response.json()
        assert data["public_id"] == basurero_data["public_id"].lower()
        assert data["nombre"] == basurero_data["nombre"]
        assert data["ubicacion"] == basurero_data["ubicacion"]
        assert data["estado"] == "activo"
        assert data["is_occupied"] is False
        assert "id" in data
        assert "created_at" in data

    def test_crear_basurero_duplicado_retorna_409(self, client, basurero_data):
        """Si ya existe un basurero con el mismo public_id, debe retornar 409 Conflict."""
        # Crear el primero
        client.post("/bins", json=basurero_data)
        # Intentar crear otro con el mismo public_id
        response = client.post("/bins", json=basurero_data)
        assert response.status_code == 409

    def test_crear_basurero_sin_nombre_retorna_422(self, client):
        """Si falta un campo requerido (nombre), debe retornar 422 Unprocessable Entity."""
        data_incompleta = {
            "public_id": "ESB-FAIL-01",
            # Falta "nombre"
        }
        response = client.post("/bins", json=data_incompleta)
        assert response.status_code == 422

    def test_crear_basurero_con_estado_mantenimiento(self, client):
        """Debe permitir crear un basurero con estado 'mantenimiento'."""
        data = {
            "public_id": "ESB-MANT-01",
            "nombre": "Basurero en mantenimiento",
            "estado": "mantenimiento",
        }
        response = client.post("/bins", json=data)
        assert response.status_code == 201
        assert response.json()["estado"] == "mantenimiento"


class TestListarBasureros:
    """Pruebas para GET /bins"""

    def test_listar_vacio(self, client):
        """Si no hay basureros, debe retornar una lista vacía."""
        response = client.get("/bins")
        assert response.status_code == 200
        assert response.json() == []

    def test_listar_con_basureros(self, client, basurero_creado):
        """Después de crear uno, la lista debe contener un elemento."""
        response = client.get("/bins")
        assert response.status_code == 200

        data = response.json()
        assert len(data) == 1
        assert data[0]["public_id"] == basurero_creado["public_id"]

    def test_listar_multiples_basureros(self, client):
        """Debe listar todos los basureros creados."""
        for i in range(3):
            client.post("/bins", json={
                "public_id": f"ESB-MULTI-{i:02d}",
                "nombre": f"Basurero Multi {i}",
            })

        response = client.get("/bins")
        assert response.status_code == 200
        assert len(response.json()) == 3


class TestObtenerBasurero:
    """Pruebas para GET /bins/{public_id}"""

    def test_obtener_existente(self, client, basurero_creado):
        """Debe retornar el basurero con el public_id dado."""
        public_id = basurero_creado["public_id"]
        response = client.get(f"/bins/{public_id}")
        assert response.status_code == 200
        assert response.json()["public_id"] == public_id

    def test_obtener_no_existente_retorna_404(self, client):
        """Debe retornar 404 si el basurero no existe."""
        response = client.get("/bins/NO-EXISTE-999")
        assert response.status_code == 404


class TestActualizarBasurero:
    """Pruebas para PUT /bins/{public_id}"""

    def test_actualizar_nombre(self, client, basurero_creado):
        """Debe actualizar el nombre del basurero."""
        public_id = basurero_creado["public_id"]
        response = client.put(f"/bins/{public_id}", json={
            "nombre": "Nombre Actualizado"
        })
        assert response.status_code == 200
        assert response.json()["nombre"] == "Nombre Actualizado"

    def test_actualizar_estado_a_mantenimiento(self, client, basurero_creado):
        """Debe poder cambiar el estado a 'mantenimiento'."""
        public_id = basurero_creado["public_id"]
        response = client.put(f"/bins/{public_id}", json={
            "estado": "mantenimiento"
        })
        assert response.status_code == 200
        assert response.json()["estado"] == "mantenimiento"

    def test_actualizar_no_existente_retorna_404(self, client):
        """Debe retornar 404 si el basurero a actualizar no existe."""
        response = client.put("/bins/NO-EXISTE-999", json={"nombre": "Nada"})
        assert response.status_code == 404

    def test_actualizar_ubicacion_y_coordenadas(self, client, basurero_creado):
        """Debe poder actualizar ubicación, latitud y longitud."""
        public_id = basurero_creado["public_id"]
        response = client.put(f"/bins/{public_id}", json={
            "ubicacion": "Nueva ubicación - Biblioteca Central",
            "latitud": -4.0100,
            "longitud": -79.2200,
        })
        assert response.status_code == 200

        data = response.json()
        assert data["ubicacion"] == "Nueva ubicación - Biblioteca Central"
        assert data["latitud"] == -4.0100
        assert data["longitud"] == -79.2200


class TestEliminarBasurero:
    """Pruebas para DELETE /bins/{public_id} (soft delete → estado inactivo)"""

    def test_eliminar_basurero(self, client, basurero_creado):
        """Debe desactivar el basurero (soft delete) y retornar 200."""
        public_id = basurero_creado["public_id"]
        response = client.delete(f"/bins/{public_id}")
        assert response.status_code == 200
        assert "desactivado" in response.json()["message"].lower()

        # Verificar que ahora está inactivo
        get_response = client.get(f"/bins/{public_id}")
        assert get_response.json()["estado"] == "inactivo"
        assert get_response.json()["is_occupied"] is False

    def test_eliminar_no_existente_retorna_404(self, client):
        """Debe retornar 404 si el basurero a eliminar no existe."""
        response = client.delete("/bins/NO-EXISTE-999")
        assert response.status_code == 404
