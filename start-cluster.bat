@echo off
REM ═══════════════════════════════════════════════════════════════
REM  start-cluster.bat — Arranca los 3 nodos Bully + Gateway
REM  EcoSmartBin — Algoritmo de Eleccion Bully
REM ═══════════════════════════════════════════════════════════════

SET JAR_PUNTOS=servicio_puntos\target\servicio-puntos-0.1.0.jar
SET JAR_GATEWAY=servicio_gateway\target\servicio-gateway-0.1.0.jar
SET NODE_URLS=http://localhost:8081,http://localhost:8082,http://localhost:8083

echo.
echo ============================================================
echo   EcoSmartBin - Cluster Bully
echo ============================================================
echo.

REM Compilar servicio_puntos si no existe el JAR
IF NOT EXIST %JAR_PUNTOS% (
    echo [BUILD] Compilando servicio_puntos...
    cd servicio_puntos
    call mvnw.cmd package -DskipTests -q
    cd ..
    IF NOT EXIST %JAR_PUNTOS% (
        echo [ERROR] No se pudo compilar servicio_puntos
        pause
        exit /b 1
    )
    echo [BUILD] servicio_puntos OK
)

REM Compilar servicio_gateway si no existe el JAR
IF NOT EXIST %JAR_GATEWAY% (
    echo [BUILD] Compilando servicio_gateway...
    cd servicio_gateway
    call mvnw.cmd package -DskipTests -q
    cd ..
    IF NOT EXIST %JAR_GATEWAY% (
        echo [ERROR] No se pudo compilar servicio_gateway
        pause
        exit /b 1
    )
    echo [BUILD] servicio_gateway OK
)

echo.
echo [START] Iniciando Nodo 1 (ID=1, Puerto=8081)...
start "Nodo-1 :8081" cmd /k "java -DNODE_ID=1 -DNODE_PORT=8081 -DNODE_URLS=%NODE_URLS% -jar %JAR_PUNTOS%"

timeout /t 2 /nobreak >nul

echo [START] Iniciando Nodo 2 (ID=2, Puerto=8082)...
start "Nodo-2 :8082" cmd /k "java -DNODE_ID=2 -DNODE_PORT=8082 -DNODE_URLS=%NODE_URLS% -jar %JAR_PUNTOS%"

timeout /t 2 /nobreak >nul

echo [START] Iniciando Nodo 3 (ID=3, Puerto=8083)...
start "Nodo-3 :8083" cmd /k "java -DNODE_ID=3 -DNODE_PORT=8083 -DNODE_URLS=%NODE_URLS% -jar %JAR_PUNTOS%"

timeout /t 6 /nobreak >nul

echo [START] Iniciando Gateway (Puerto=8080)...
start "Gateway :8080" cmd /k "java -jar %JAR_GATEWAY%"

echo.
echo ============================================================
echo   Cluster iniciado!
echo   - Nodo 1:  http://localhost:8081/api/bully/status
echo   - Nodo 2:  http://localhost:8082/api/bully/status
echo   - Nodo 3:  http://localhost:8083/api/bully/status
echo   - Gateway: http://localhost:8080/gateway/status
echo.
echo   El nodo con mayor ID (Nodo 3) sera elegido lider.
echo   Cierra la ventana de un nodo para simular una caida.
echo ============================================================
echo.
pause
