FROM kong:3.4

# Cambiar a usuario root para copiar archivos y ajustar permisos
USER root

# Crear el directorio por si no existe
RUN mkdir -p /usr/local/kong/declarative/

# Copiar el archivo de configuración declarativa al contenedor
COPY kong.yml /usr/local/kong/declarative/kong.yml

# Asegurar que el usuario kong sea dueño del archivo de configuración
RUN chown -R kong:kong /usr/local/kong/declarative/

# Configurar variables de entorno requeridas por Kong para modo DB-less
ENV KONG_DATABASE=off
ENV KONG_DECLARATIVE_CONFIG=/usr/local/kong/declarative/kong.yml

# Redirigir logs a la consola de Google Cloud
ENV KONG_PROXY_ACCESS_LOG=/dev/stdout
ENV KONG_ADMIN_ACCESS_LOG=/dev/stdout
ENV KONG_PROXY_ERROR_LOG=/dev/stderr
ENV KONG_ADMIN_ERROR_LOG=/dev/stderr

# Forzamos a Kong a escuchar en el puerto 8080 (Cloud Run)
ENV KONG_PROXY_LISTEN="0.0.0.0:8080 reuseport"

# Volvemos al usuario kong por seguridad
USER kong

# Comando de entrada
CMD ["kong", "docker-start"]