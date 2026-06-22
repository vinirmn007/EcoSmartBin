FROM kong:3.4-alpine

# Cambiar a usuario root para copiar archivos
USER root

# Copiar el archivo de configuración declarativa al contenedor
COPY kong.yml /usr/local/kong/declarative/kong.yml

# Configurar variables de entorno requeridas por Kong para modo DB-less
ENV KONG_DATABASE=off
ENV KONG_DECLARATIVE_CONFIG=/usr/local/kong/declarative/kong.yml

# Redirigir logs a la consola de Google Cloud
ENV KONG_PROXY_ACCESS_LOG=/dev/stdout
ENV KONG_ADMIN_ACCESS_LOG=/dev/stdout
ENV KONG_PROXY_ERROR_LOG=/dev/stderr
ENV KONG_ADMIN_ERROR_LOG=/dev/stderr

# Forzamos a Kong de manera global a escuchar en el puerto 8080 (el que Cloud Run exige)
ENV KONG_PROXY_LISTEN="0.0.0.0:8080 reuseport"

# Volvemos al usuario kong por seguridad antes de ejecutar
USER kong

# Usamos el comando de entrada por defecto de la imagen oficial sin envoltorios extra
CMD ["kong", "docker-start"]
