# Guía de Configuración AWS para EcoSmartBin CI/CD

Esta guía detalla los pasos necesarios para configurar los recursos en tu cuenta estudiantil de AWS y configurar los Secrets en GitHub para que el pipeline funcione correctamente.

---

## 1. Configuración del Frontend en Amazon S3

El frontend de Flutter se compila para Web y se aloja en un bucket de S3 configurado como sitio web estático.

1. **Crear el Bucket de S3:**
   - Ve a la consola de AWS S3 y haz clic en **Create bucket**.
   - Nombre del bucket: Elige un nombre único (ej. `ecosmartbin-frontend-xyz`).
   - Región: Elige tu región de AWS Academy (usualmente `us-east-1`).
   - Desmarca la opción **Block *all* public access** (para permitir que sea visible públicamente como sitio web) y acepta la advertencia.

2. **Habilitar Static Website Hosting:**
   - Entra al bucket creado, ve a la pestaña **Properties** (Propiedades).
   - Ve hasta abajo a la sección **Static website hosting** y haz clic en **Edit**.
   - Habilítalo (**Enable**).
   - En **Index document**, escribe `index.html`.
   - En **Error document**, escribe `index.html` (necesario para el enrutamiento de Flutter Web).
   - Guarda los cambios y copia el enlace del **Bucket website endpoint** (URL pública del frontend).

3. **Configurar la Política de Acceso Público (Bucket Policy):**
   - Ve a la pestaña **Permissions** (Permisos) del bucket.
   - En **Bucket policy**, haz clic en **Edit** y pega la siguiente política (reemplaza `TU-NOMBRE-DE-BUCKET` por el nombre real de tu bucket):
     ```json
     {
         "Version": "2012-10-17",
         "Statement": [
             {
                 "Sid": "PublicReadGetObject",
                 "Effect": "Allow",
                 "Principal": "*",
                 "Action": "s3:GetObject",
                 "Resource": "arn:aws:s3:::TU-NOMBRE-DE-BUCKET/*"
             }
         ]
     }
     ```
   - Guarda los cambios.

---

## 2. Configuración del Backend en AWS EC2 & ECR

El backend de Spring Boot se ejecuta dentro de un contenedor Docker en una instancia EC2.

### A. Crear el Repositorio de Amazon ECR (Elastic Container Registry)
1. Ve a la consola de **Elastic Container Registry (ECR)**.
2. Haz clic en **Create repository**.
3. Configuración:
   - Visibilidad: **Private**.
   - Nombre: `ecosmartbin-backend` (debe coincidir con la variable en GitHub Actions).
4. Guarda el repositorio y copia la URL del registro (ej. `123456789012.dkr.ecr.us-east-1.amazonaws.com`).

### B. Crear y Configurar la Instancia EC2
1. Ve a la consola de **EC2** y haz clic en **Launch Instance**.
2. **Nombre:** `ecosmartbin-backend-server`.
3. **AMI (Sistema Operativo):** Selecciona **Ubuntu** (22.04 LTS o 24.04 LTS) o **Amazon Linux 2023**. (Esta guía usa comandos para Ubuntu).
4. **Instance Type:** `t2.micro` o `t3.micro` (dentro de la capa gratuita).
5. **Key Pair (SSH):** Crea un nuevo par de llaves `.pem` (guárdalo bien, ya que lo usaremos en GitHub Secrets).
6. **Network Settings (Security Group):**
   - Permite tráfico SSH (puerto 22) desde cualquier lugar (`0.0.0.0/0`) o preferiblemente solo tu IP.
   - Agrega una regla personalizada de entrada (Inbound rule) para el puerto **8081** (HTTP) desde cualquier lugar (`0.0.0.0/0`), que es el puerto de nuestra API de puntos.
7. Lanza la instancia.

### C. Instalar Docker en la Instancia EC2
Conéctate por SSH a tu instancia EC2 usando la terminal y ejecuta los siguientes comandos para instalar Docker:

```bash
# Actualizar el sistema
sudo apt-get update -y
sudo apt-get upgrade -y

# Instalar Docker
sudo apt-get install docker.io -y

# Iniciar y habilitar el servicio de Docker
sudo systemctl start docker
sudo systemctl enable docker

# Añadir el usuario ubuntu al grupo docker para ejecutar comandos sin 'sudo'
sudo usermod -aG docker ubuntu

# Instalar AWS CLI en la máquina EC2 (necesario para autenticar con ECR)
sudo apt-get install awscli -y
```
*Nota: Cierra sesión SSH (`exit`) y vuelve a ingresar para aplicar los permisos de grupo de Docker.*

---

## 3. Configurar Secrets en el Repositorio de GitHub

Ve a tu repositorio de GitHub, ve a **Settings** (Configuración) > **Secrets and variables** > **Actions** > **New repository secret** y agrega las siguientes variables:

### Credenciales Temporales de AWS (Desde tu AWS Academy console)
> [!IMPORTANT]
> Estas tres credenciales cambian cada vez que reinicias tu sesión de AWS Academy / Learner Lab. Recuerda actualizarlas en GitHub si expiran.
- `AWS_ACCESS_KEY_ID`: Tu access key de AWS Academy.
- `AWS_SECRET_ACCESS_KEY`: Tu secret access key de AWS Academy.
- `AWS_SESSION_TOKEN`: Tu session token temporal.
- `AWS_REGION`: La región de tu cuenta (ej. `us-east-1`).

### Configuración de ECR y EC2 (Fijos)
- `ECR_REGISTRY`: URL base de tu registro ECR (ej. `123456789012.dkr.ecr.us-east-1.amazonaws.com`).
- `ECR_REPOSITORY`: Nombre de tu repositorio ECR (ej. `ecosmartbin-backend`).
- `EC2_HOST`: La IP pública de tu instancia EC2.
- `EC2_USER`: El usuario del servidor EC2 (usualmente `ubuntu`).
- `EC2_SSH_KEY`: Pega el contenido completo del archivo `.pem` (clave privada SSH) que descargaste al crear la instancia EC2.
- `S3_BUCKET_NAME`: El nombre del bucket S3 que creaste para el frontend (ej. `ecosmartbin-frontend-xyz`).

### Configuración del Backend (Supabase & Base de Datos)
- `SPRING_DATASOURCE_URL`: URL JDBC de Supabase (ej. `jdbc:postgresql://aws-1-us-east-1.pooler.supabase.com:5432/postgres`).
- `SPRING_DATASOURCE_USERNAME`: Usuario de Supabase DB.
- `SPRING_DATASOURCE_PASSWORD`: Contraseña de Supabase DB.
- `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI`: URL JWKS de Supabase Auth (ej. `https://vqxblugxfhsiecyhvlgx.supabase.co/auth/v1/.well-known/jwks.json`).
- `SUPABASE_URL`: Tu API URL de Supabase.
- `SUPABASE_KEY`: Tu Supabase Anon Key.
