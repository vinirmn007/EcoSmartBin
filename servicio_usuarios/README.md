# EcoSmartBin - Servicio de Usuarios 👤🔒

Este microservicio es el núcleo de gestión de usuarios, perfiles y autenticación para el ecosistema **EcoSmartBin**. Está construido sobre **FastAPI**, utilizando una arquitectura híbrida que combina **Supabase Auth** (para la gestión segura de credenciales y generación de JWTs) y una base de datos relacional **PostgreSQL** a través de **SQLAlchemy** (para almacenar los perfiles de usuario y puntajes ecológicos).
hola

---

## 🛠️ Arquitectura y Funcionamiento

El servicio maneja la autenticación y los perfiles de usuario utilizando un patrón sincronizado:

```mermaid
sequenceDiagram
    participant Cliente as App (Flutter/Web)
    participant API as Microservicio FastAPI
    participant Auth as Supabase Auth (GoTrue)
    participant DB as PostgreSQL (SQLAlchemy)

    Note over Cliente, API: Flujo de Registro (/auth/register)
    Cliente->>API: Datos de Registro (Email, Cédula, Nombres, etc.)
    API->>DB: Validar que Cédula/Email no existan previamente
    DB-->>API: Validación Exitosa (No existen)
    API->>Auth: Crear cuenta de usuario con Email y Contraseña
    Auth-->>API: Cuenta creada (Retorna UUID de Supabase)
    API->>DB: Insertar Perfil en Tabla "perfiles" (Misma UUID)
    DB-->>API: Confirmación de registro
    API-->>Cliente: Registro Exitoso (201 Created)
```

### Conceptos Clave:
1. **Validación Preventiva (Sin Huérfanos):** Antes de registrar a un usuario en la nube de Supabase Auth, el microservicio realiza consultas en la base de datos relacional PostgreSQL para verificar que ni el correo electrónico ni la cédula de identidad estén duplicados. Esto evita la creación de "usuarios huérfanos" (usuarios que existen en la autenticación pero carecen de perfil de base de datos).
2. **Validación Local de Tokens (JWT):** Para proteger rutas como `/auth/me`, el microservicio valida y decodifica localmente el JWT enviado por la aplicación mediante el **JWT Secret** de Supabase (Firma Simétrica HS256). Esto maximiza el rendimiento al eliminar la necesidad de consultar a la API de Supabase en cada petición HTTP protegida.

---

## 📂 Estructura del Proyecto

```text
servicio_usuarios/
├── database.py             # Configuración de SQLAlchemy y dependencias de sesión (get_db)
├── main.py                 # Punto de entrada de FastAPI y configuración de CORS
├── requirements.txt        # Dependencias empaquetadas del proyecto
├── settings.py             # Carga y validación de variables de entorno mediante Pydantic
├── models/
│   └── usuario_model.py    # Modelo ORM de SQLAlchemy para la tabla "perfiles"
├── routes/
│   └── usuario_routes.py   # Endpoints de login, registro y perfil (/auth)
└── schemas/
    └── usuario_schemas.py  # Modelos de datos Pydantic para validación de entrada
```

---

## 🔑 Configuración del Entorno (`.env`)

El microservicio requiere un archivo `.env` en la raíz de `servicio_usuarios/` con las siguientes variables:

```env
# URL del API REST de Supabase (Utilizado por el cliente Supabase)
SUPABASE_URL=https://your-project-id.supabase.co

# API Key pública/anon de Supabase
SUPABASE_KEY=your-supabase-anon-key

# Secreto de JWT de Supabase (Utilizado para decodificación y validación local de tokens)
SUPABASE_JWT_SECRET=your-jwt-secret

# Conexión directa a PostgreSQL en Supabase (Utilizado por SQLAlchemy)
DATABASE_URL=postgresql://postgres.your-project-id:your-db-password@your-db-host:5432/postgres

# Configuración opcional
ENV=dev
ALLOWED_ORIGINS_PROD=https://ecosmartbin.web.app
```

---

## 🚀 Instalación y Ejecución Local

Sigue estos pasos para levantar el microservicio de manera local en tu entorno de desarrollo:

### 1. Preparar el Entorno Virtual
Crea y activa el entorno de Python 3.12:
```bash
# Crear entorno virtual
python3 -m venv venv

# Activar en Linux/macOS
source venv/bin/activate

# Activar en Windows
venv\Scripts\activate
```

### 2. Instalar Dependencias
Instala todas las librerías necesarias especificadas en el archivo `requirements.txt`:
```bash
pip install -r requirements.txt
```

### 3. Ejecutar el Servidor
Inicia la API localmente mediante Uvicorn:
```bash
python main.py
```
El servidor arrancará en `http://localhost:8000`.

### 4. Acceder a la Documentación Interactiva
FastAPI autogenera la documentación OpenAPI de forma interactiva. Una vez levantado el servidor, accede en tu navegador a:
* **Interactive Swagger UI:** `http://localhost:8000/docs`
* **Redoc UI:** `http://localhost:8000/redoc`

---

## 📡 Referencia de API (Endpoints)

### 1. Registro de Usuario (`POST /auth/register`)
Registra las credenciales en Supabase Auth y guarda los detalles adicionales del estudiante o docente en Postgres.
* **Cuerpo de la Petición:**
  ```json
  {
    "email": "estudiante@ejemplo.edu",
    "password": "mi_password_seguro",
    "nombres": "Juan Carlos",
    "apellidos": "Pérez Gómez",
    "cedula": "1726549210",
    "tipo_usuario": "estudiante",
    "facultad": "Ingeniería de Sistemas"
  }
  ```
* **Respuestas:**
  * `201 Created`: Usuario y perfil guardados con éxito.
  * `400 Bad Request`: Si el correo o la cédula ya se encuentran registrados.

### 2. Inicio de Sesión (`POST /auth/login`)
Autentica al usuario en Supabase y devuelve los tokens JWT de sesión.
* **Cuerpo de la Petición:**
  ```json
  {
    "email": "estudiante@ejemplo.edu",
    "password": "mi_password_seguro"
  }
  ```
* **Respuesta (`200 OK`):**
  ```json
  {
    "access_token": "eyJhbGciOiJIUzI1Ni...",
    "token_type": "bearer",
    "refresh_token": "refresh_token_uuid",
    "user": {
      "id": "supabase-user-uuid",
      "email": "estudiante@ejemplo.edu",
      "role": "user"
    }
  }
  ```

### 3. Obtener Perfil del Usuario Autenticado (`GET /auth/me`)
Obtiene la información detallada del perfil correspondiente al JWT enviado en la cabecera.
* **Cabeceras:** `Authorization: Bearer <access_token>`
* **Respuesta (`200 OK`):**
  ```json
  {
    "user_id": "supabase-user-uuid",
    "email": "estudiante@ejemplo.edu",
    "nombres": "Juan Carlos",
    "apellidos": "Pérez Gómez",
    "cedula": "1726549210",
    "tipo_usuario": "estudiante",
    "facultad": "Ingeniería de Sistemas",
    "role": "user",
    "puntos_ecologicos": 0,
    "is_active": true,
    "created_at": "2026-05-30T17:15:00.000Z"
  }
  ```

---

## 📝 Resumen de Mejoras y Ajustes Realizados

Para el conocimiento del equipo de desarrollo, se realizaron los siguientes arreglos y optimizaciones estructurales sobre la versión inicial:
* **Carga de Configuraciones:** Implementación del archivo `settings.py` mediante `pydantic-settings` para la correcta carga automática de credenciales del archivo `.env`, resolviendo crashes por falta de atributos.
* **Corrección de Imports:** Se estandarizó la importación de `settings` en `main.py`, corrigiendo llamadas inválidas al módulo inexistente `config`.
* **Corrección del Modelo ORM:** Se repararon errores de sintaxis y duplicados de código en `usuario_model.py`.
* **Seguridad en Registro:** Se reordenaron las operaciones del endpoint `/register` para ejecutar primero los chequeos de base de datos relacional y luego proceder a la llamada de API de Supabase, evitando problemas de inconsistencia (usuarios registrados sin perfil).
* **Manejo de Drivers de Base de Datos:** Se incorporaron `SQLAlchemy` y `psycopg2-binary` a `requirements.txt` para garantizar la conexión local exitosa al Postgres de Supabase.
