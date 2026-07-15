package com.ecosmartbin.puntos;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Pruebas unitarias básicas para el servicio de puntos.
 * No requieren contexto de Spring Boot ni conexión a base de datos.
 */
class EcoPuntosApplicationTests {

    @Test
    void applicationClassExists() {
        // Verificar que la clase principal de la aplicación existe y es instanciable
        EcoPuntosApplication app = new EcoPuntosApplication();
        assertNotNull(app, "La clase EcoPuntosApplication debe existir");
    }

    @Test
    void mainMethodExists() throws NoSuchMethodException {
        // Verificar que el método main existe con la firma correcta
        var mainMethod = EcoPuntosApplication.class.getMethod("main", String[].class);
        assertNotNull(mainMethod, "El método main debe existir");
        assertTrue(java.lang.reflect.Modifier.isStatic(mainMethod.getModifiers()), 
            "El método main debe ser estático");
    }
}
