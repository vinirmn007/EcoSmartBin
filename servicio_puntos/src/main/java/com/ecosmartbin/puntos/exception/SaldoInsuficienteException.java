package com.ecosmartbin.puntos.exception;

/**
 * Excepción lanzada cuando el usuario no tiene suficientes puntos para un canje.
 */
public class SaldoInsuficienteException extends RuntimeException {

    public SaldoInsuficienteException(String message) {
        super(message);
    }

    public SaldoInsuficienteException(int puntosDisponibles, int puntosRequeridos) {
        super(String.format(
                "Saldo insuficiente. Tienes %d puntos pero necesitas %d para este canje.",
                puntosDisponibles, puntosRequeridos
        ));
    }
}
