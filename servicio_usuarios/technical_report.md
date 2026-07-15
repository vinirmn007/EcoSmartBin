# Reporte Técnico de Pruebas y CI/CD: Servicio de Usuarios

Este reporte técnico describe la arquitectura de pruebas unitarias y de integración para el **Servicio de Usuarios (User-Service)** de EcoSmartBin, detalla los casos de prueba implementados para la capa de autenticación, y proporciona las guías para expandir la suite de pruebas.

---

## 1. Arquitectura de Pruebas de Usuarios

La seguridad, consistencia de datos y estabilidad del flujo de autenticación son fundamentales para EcoSmartBin. Para garantizar que los cambios de código no afecten los flujos críticos, implementamos la siguiente arquitectura de validación:

### Herramientas Seleccionadas
1. **Pytest (v9.1+):** Framework de testing para Python que facilita la escritura de pruebas modulares, legibles e independientes.
2. **Ruff (check/linter):** Formateador y linter extremadamente rápido que asegura el cumplimiento de buenas prácticas de código (PEP 8), detecta variables/módulos importados sin usar y evita vulnerabilidades potenciales tempranas.

### Importancia en Seguridad y Autenticación
* **Aislamiento en Memoria:** Se configuró una base de datos SQLite en memoria (`test.db`) para simular la persistencia relacional sin requerir conexiones activas a la base de datos PostgreSQL de producción en GCP/Supabase.
* **Mocks de Red:** Se intercepta el cliente de Supabase Auth utilizando `unittest.mock.MagicMock` para simular la verificación de tokens, inicios de sesión y registros de usuario. Esto asegura que las pruebas no dependan del estado externo del servicio Supabase ni de su cuota de red, garantizando velocidad y reproducibilidad en entornos de CI/CD.

---

## 2. Casos de Prueba de Autenticación

A continuación, se detallan los endpoints del microservicio de usuarios evaluados y validados:

| Endpoint | Método HTTP | Payload de Entrada (Ejemplo JSON) / Cabeceras | Código de Respuesta Esperado | Cuerpo de Respuesta Esperado (Estructura) | Mocks de Base de Datos y Supabase |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `/auth/register` | `POST` | `{"email": "nuevo@ecosmartbin.com", "password": "...", "nombres": "Josué", "apellidos": "Pérez", "cedula": "1723456789", "facultad": "Sistemas"}` | **201 Created** | `{"message": "...", "user_id": "supabase-uid-999", "nombres": "Josué", "email": "nuevo@ecosmartbin.com"}` | Se intercepta `supabase.auth.sign_up` para retornar un usuario simulado. Se verifica la persistencia del perfil en SQLite. |
| `/auth/register` | `POST` | Mismo payload (Cédula o Email duplicado) | **400 Bad Request** | `{"detail": "La cédula... ya se encuentra registrada."}` o correo duplicado. | Se inserta previamente un usuario en la BD SQLite con la misma cédula/correo para forzar la validación. |
| `/auth/login` | `POST` | `{"email": "usuario@ecosmartbin.com", "password": "correctpassword"}` | **200 OK** | `{"access_token": "...", "token_type": "bearer", "refresh_token": "...", "user": {"id": "...", "email": "...", "role": "..."}}` | Se mockea `supabase.auth.sign_in_with_password` para retornar tokens de sesión de prueba. |
| `/auth/login` | `POST` | `{"email": "usuario@ecosmartbin.com", "password": "wrongpassword"}` | **401 Unauthorized** | `{"detail": "Credenciales incorrectas o cuenta no verificada..."}` | Se fuerza a `sign_in_with_password` a lanzar una excepción. |
| `/auth/me` | `GET` | Cabecera: `Authorization: Bearer valid-token` | **200 OK** | `{"user_id": "...", "email": "...", "nombres": "...", "apellidos": "...", "cedula": "...", "role": "...", "puntos_ecologicos": 150, "is_active": true, ...}` | `supabase.auth.get_user` retorna usuario con ID `"supabase-uid-123"`. Se consulta la base de datos de pruebas SQLite que posee dicho perfil. |
| `/auth/me` | `GET` | Cabecera: `Authorization: Bearer invalid-token` | **401 Unauthorized** | `{"detail": "Token inválido, alterado o expirado."}` | `supabase.auth.get_user` lanza excepción de expiración de token. |
| `/auth/me` | `GET` | Cabecera: `Authorization: Bearer token-sin-perfil` | **404 Not Found** | `{"detail": "Perfil no encontrado en la base de datos."}` | `supabase.auth.get_user` es exitoso, pero la BD de pruebas no tiene el registro del perfil. |
| `/auth/email-reset-password` | `POST` | `{"email": "recuperar@ecosmartbin.com"}` | **200 OK** | `{"message": "Correo de recuperación enviado exitosamente."}` | Mockea `supabase.auth.reset_password_for_email`. |
| `/auth/change-password` | `POST` | `{"access_token": "...", "refresh_token": "...", "new_password": "..."}` | **200 OK** | `{"message": "Contraseña restablecida exitosamente."}` | Intercepta `create_client` y `supabase.auth.update_user` para validar la sesión de recuperación y actualizar la clave. |

---

## 3. Guía para Agregar Nuevas Funcionalidades de Usuario

Al agregar campos o endpoints (ej. Roles avanzados, recuperación de contraseñas mediante OTP, cambio de correo, etc.), sigue estos lineamientos:

### Paso 1: Actualizar Modelos y Esquemas
1. Si agregas campos a la base de datos (por ejemplo, `rol` o `avatar_url`), añádelos en [usuario_model.py](file:///home/josue/Documents/cloud/EcoSmartBin/servicio_usuarios/models/usuario_model.py).
2. Actualiza los esquemas de validación de Pydantic en [usuario_schemas.py](file:///home/josue/Documents/cloud/EcoSmartBin/servicio_usuarios/schemas/usuario_schemas.py) para que FastAPI valide los payloads automáticamente.

### Paso 2: Crear Casos de Prueba en Pytest
1. Escribe la prueba en `tests/test_auth.py` (o en un archivo nuevo `tests/test_roles.py`).
2. Sigue el patrón establecido:
   * Usa el fixture `client` para simular llamadas HTTP.
   * Si interactúas con bases de datos, inyecta `db_session`.
   * Si interactúas con Supabase Auth, inyecta `mock_supabase` y define el comportamiento esperado del método:
     ```python
     def test_nuevo_endpoint_admin_only(client, mock_supabase, db_session):
         # 1. Configurar Mock
         mock_user = MagicMock()
         mock_user.id = "admin-uid"
         mock_user.user_metadata = {"role": "admin"}
         mock_response = MagicMock(user=mock_user)
         mock_supabase.get_user.return_value = mock_response

         # 2. Llamada HTTP
         response = client.get("/auth/admin-dashboard", headers={"Authorization": "Bearer admin-token"})

         # 3. Asertos
         assert response.status_code == 200
     ```

### Paso 3: Validación Automática en CI/CD
El pipeline configurado en [cloudbuild.yaml](file:///home/josue/Documents/cloud/EcoSmartBin/servicio_usuarios/cloudbuild.yaml) ejecutará de forma automática en cada push:
1. `ruff check .` para validar el estilo de código del nuevo desarrollo.
2. `pytest tests/` para correr toda la suite de pruebas (incluyendo las nuevas).
Si cualquiera de los dos pasos falla, el build se detendrá y no se desplegará en Cloud Run, garantizando la seguridad en el entorno de producción.
