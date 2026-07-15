# ===========================
# Stage 1: Compilación con Maven
# ===========================
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copiar archivos de dependencias primero (para aprovechar el cache de Docker)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copiar código fuente y compilar
COPY src ./src
RUN mvn clean package -DskipTests -B

# ===========================
# Stage 2: Imagen ligera de ejecución
# ===========================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copiar el JAR compilado
COPY --from=build /app/target/*.jar app.jar

# Exponer el puerto (Cloud Run usa PORT env variable)
EXPOSE 8081

# Ejecutar la aplicación usando la variable PORT de Cloud Run (si existe)
ENTRYPOINT ["sh", "-c", "java -jar app.jar --server.port=${PORT:-8081}"]
