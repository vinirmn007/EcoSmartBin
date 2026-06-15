# Imagen base de Python
FROM python:3.12-slim

# Directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema necesarias
# onnxruntime requiere libgomp.so.1 que viene en libgomp1
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copiar requerimientos e instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código del backend
COPY . .

# Exponer el puerto por defecto (8080)
EXPOSE 8080

# Ejecutar el servidor Uvicorn (usando la variable PORT provista por Cloud Run o por defecto 8080)
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}"]
