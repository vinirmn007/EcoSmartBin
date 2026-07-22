from unittest.mock import MagicMock
from models.usuario_model import PerfilUsuario


def test_register_user_success(client, mock_supabase):
    # Configurar mock de Supabase
    mock_user = MagicMock()
    mock_user.id = "supabase-uid-999"
    
    mock_response = MagicMock()
    mock_response.user = mock_user
    mock_supabase.sign_up.return_value = mock_response

    # Datos de registro
    # Datos de registro
    payload = {
        "email": "nuevo@ecosmartbin.com",
        "password": "Supersecurepassword123!",
        "nombres": "Josué",
        "apellidos": "Pérez",
        "cedula": "1723456789",
        "telefono": "0991234567",
        "facultad": "Sistemas"
    }

    # Llamar endpoint
    response = client.post("/auth/register", json=payload)

    # Validaciones
    assert response.status_code == 201
    res_data = response.json()
    assert "user_id" in res_data
    assert res_data["user_id"] == "supabase-uid-999"
    assert res_data["email"] == "nuevo@ecosmartbin.com"
    assert "creados exitosamente" in res_data["message"]

    # Verificar que el método sign_up fue llamado con los argumentos correctos
    mock_supabase.sign_up.assert_called_once()
    args = mock_supabase.sign_up.call_args[0][0]
    assert args["email"] == "nuevo@ecosmartbin.com"
    assert args["password"] == "Supersecurepassword123!"


def test_register_user_duplicate_cedula(client, db_session):
    # Insertar un perfil de prueba previo
    perfil = PerfilUsuario(
        id="previo-id",
        email="previo@ecosmartbin.com",
        nombres="Juan",
        apellidos="Castro",
        cedula="1723456789",
        facultad="Medicina",
        role="user"
    )
    db_session.add(perfil)
    db_session.commit()

    payload = {
        "email": "nuevo@ecosmartbin.com",
        "password": "Supersecurepassword123!",
        "nombres": "Josué",
        "apellidos": "Pérez",
        "cedula": "1723456789",  # Cédula duplicada
        "telefono": "0991234567",
        "facultad": "Sistemas"
    }

    response = client.post("/auth/register", json=payload)
    assert response.status_code == 400
    assert response.json()["detail"] == "La cédula ingresada ya se encuentra registrada."


def test_register_user_duplicate_email(client, db_session):
    perfil = PerfilUsuario(
        id="previo-id",
        email="duplicado@ecosmartbin.com",
        nombres="Juan",
        apellidos="Castro",
        cedula="1723456780",
        facultad="Medicina",
        role="user"
    )
    db_session.add(perfil)
    db_session.commit()

    payload = {
        "email": "duplicado@ecosmartbin.com",  # Email duplicado
        "password": "Supersecurepassword123!",
        "nombres": "Josué",
        "apellidos": "Pérez",
        "cedula": "1723456789",
        "telefono": "0991234567",
        "facultad": "Sistemas"
    }

    response = client.post("/auth/register", json=payload)
    assert response.status_code == 400
    assert response.json()["detail"] == "El correo electrónico ingresado ya se encuentra registrado."


def test_register_user_supabase_fails(client, mock_supabase):
    mock_supabase.sign_up.side_effect = Exception("Supabase Auth Server error")

    payload = {
        "email": "error@ecosmartbin.com",
        "password": "Supersecurepassword123!",
        "nombres": "Josué",
        "apellidos": "Pérez",
        "cedula": "1723456789",
        "telefono": "0991234567",
        "facultad": "Sistemas"
    }

    response = client.post("/auth/register", json=payload)
    assert response.status_code == 400
    assert "Error en el proceso de registro" in response.json()["detail"]


def test_login_user_success(client, mock_supabase):
    # Configurar mock de Supabase
    mock_user = MagicMock()
    mock_user.id = "supabase-uid-123"
    mock_user.email = "usuario@ecosmartbin.com"
    mock_user.user_metadata = {"role": "user"}

    mock_session = MagicMock()
    mock_session.access_token = "valid-access-token"
    mock_session.refresh_token = "valid-refresh-token"

    mock_response = MagicMock()
    mock_response.user = mock_user
    mock_response.session = mock_session
    
    mock_supabase.sign_in_with_password.return_value = mock_response

    payload = {
        "email": "usuario@ecosmartbin.com",
        "password": "correctpassword"
    }

    response = client.post("/auth/login", json=payload)
    assert response.status_code == 200
    res_data = response.json()
    assert res_data["access_token"] == "valid-access-token"
    assert res_data["token_type"] == "bearer"
    assert res_data["user"]["id"] == "supabase-uid-123"


def test_login_user_invalid_credentials(client, mock_supabase):
    mock_supabase.sign_in_with_password.side_effect = Exception("Invalid login credentials")

    payload = {
        "email": "usuario@ecosmartbin.com",
        "password": "wrongpassword"
    }

    response = client.post("/auth/login", json=payload)
    assert response.status_code == 401
    assert "Credenciales incorrectas" in response.json()["detail"]


def test_get_my_profile_success(client, db_session, mock_supabase):
    # Guardar perfil en la BD SQLite
    perfil = PerfilUsuario(
        id="supabase-uid-123",
        email="usuario@ecosmartbin.com",
        nombres="Josué",
        apellidos="Pérez",
        cedula="1723456789",
        facultad="Sistemas",
        role="user",
        puntos_ecologicos=150
    )
    db_session.add(perfil)
    db_session.commit()

    # Mockear respuesta get_user
    mock_user = MagicMock()
    mock_user.id = "supabase-uid-123"
    mock_user.email = "usuario@ecosmartbin.com"
    mock_user.user_metadata = {"role": "user"}
    
    mock_response = MagicMock()
    mock_response.user = mock_user
    mock_supabase.get_user.return_value = mock_response

    # Llamar con token
    headers = {"Authorization": "Bearer fake-token-123"}
    response = client.get("/auth/me", headers=headers)

    assert response.status_code == 200
    res_data = response.json()
    assert res_data["user_id"] == "supabase-uid-123"
    assert res_data["email"] == "usuario@ecosmartbin.com"
    assert res_data["puntos_ecologicos"] == 150
    assert res_data["nombres"] == "Josué"


def test_get_my_profile_unauthorized(client, mock_supabase):
    mock_supabase.get_user.side_effect = Exception("Token expired or invalid")

    headers = {"Authorization": "Bearer invalid-token"}
    response = client.get("/auth/me", headers=headers)

    assert response.status_code == 401
    assert "Token inválido" in response.json()["detail"]


def test_get_my_profile_not_found_in_db(client, mock_supabase):
    # Mockear Supabase para que devuelva un usuario válido
    mock_user = MagicMock()
    mock_user.id = "non-existent-in-pg-id"
    mock_user.email = "usuario@ecosmartbin.com"
    mock_user.user_metadata = {"role": "user"}
    
    mock_response = MagicMock()
    mock_response.user = mock_user
    mock_supabase.get_user.return_value = mock_response

    headers = {"Authorization": "Bearer token-valido"}
    response = client.get("/auth/me", headers=headers)

    # Como no existe en la base de datos relacional
    assert response.status_code == 404
    assert "Perfil no encontrado" in response.json()["detail"]


def test_email_reset_password_success(client, mock_supabase):
    mock_supabase.reset_password_for_email.return_value = {}

    payload = {
        "email": "recuperar@ecosmartbin.com"
    }

    response = client.post("/auth/email-reset-password", json=payload)
    assert response.status_code == 200
    assert response.json()["message"] == "Correo de recuperación enviado exitosamente."
    mock_supabase.reset_password_for_email.assert_called_once_with(
        "recuperar@ecosmartbin.com", options={}
    )


def test_email_reset_password_fails(client, mock_supabase):
    mock_supabase.reset_password_for_email.side_effect = Exception("Error in API")

    payload = {
        "email": "recuperar@ecosmartbin.com"
    }

    response = client.post("/auth/email-reset-password", json=payload)
    assert response.status_code == 400
    assert "Error al enviar correo de recuperación" in response.json()["detail"]


def test_change_password_success(client, mock_supabase):
    mock_user = MagicMock()
    mock_user.email = "usuario@ecosmartbin.com"
    mock_user.id = "supabase-uid-123"
    
    mock_response = MagicMock()
    mock_response.user = mock_user
    mock_supabase.update_user.return_value = mock_response

    payload = {
        "access_token": "acc-token-123",
        "refresh_token": "ref-token-123",
        "new_password": "newsupersecurepassword1"
    }

    response = client.post("/auth/change-password", json=payload)
    assert response.status_code == 200
    assert response.json()["message"] == "Contraseña restablecida exitosamente."


def test_change_password_fails(client, mock_supabase):
    mock_supabase.update_user.side_effect = Exception("Invalid session token")

    payload = {
        "access_token": "acc-token-invalid",
        "refresh_token": "ref-token-invalid",
        "new_password": "newsupersecurepassword1"
    }

    response = client.post("/auth/change-password", json=payload)
    assert response.status_code == 400
    assert "Error al restablecer la contraseña" in response.json()["detail"]
