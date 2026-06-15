package com.ecosmartbin.puntos.exception;

/**
 * Excepción lanzada cuando un recurso solicitado no existe.
 */
public class RecursoNoEncontradoException extends RuntimeException {

    public RecursoNoEncontradoException(String recurso, Object id) {
        super(String.format("No se encontró el recurso '%s' con identificador: %s", recurso, id));
    }

    public RecursoNoEncontradoException(String message) {
        super(message);
    }
}
