# Imagen base de Python
FROM python:3.12-slim

# Directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema necesarias
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar requerimientos e instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código del servicio
COPY . .

# Exponer el puerto por defecto de Cloud Run (8080)
EXPOSE 8080

# Ejecutar el servidor Uvicorn (usando la variable PORT provista por Cloud Run)
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}"]
