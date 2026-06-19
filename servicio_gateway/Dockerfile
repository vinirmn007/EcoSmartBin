# ===========================
# Stage 1: Compilación con Maven
# ===========================
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn clean package -DskipTests -B

# ===========================
# Stage 2: Imagen ligera de ejecución
# ===========================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

# NODE_URLS se configura desde el docker-compose con las IPs reales del switch
ENTRYPOINT ["sh", "-c", "java \
  -DGATEWAY_NODE_URLS=${NODE_URLS:-http://localhost:8081,http://localhost:8082,http://localhost:8083} \
  -jar app.jar"]
