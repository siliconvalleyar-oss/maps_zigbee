package com.ejemplo.demo;

import org.springframework.web.bind.annotation.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

@RestController
public class NodoController {

    // Lista en memoria que simula la base de datos
    private final List<Nodo> nodos = new ArrayList<>();
    private final Random random = new Random();

    public NodoController() {
        // Inicializar con los 4 nodos de prueba
        nodos.add(new Nodo(1, "Nodo Plaza de Mayo", -34.6083, -58.3712, "online"));
        nodos.add(new Nodo(2, "Nodo Plaza Italia", -34.5812, -58.4215, "online"));
        nodos.add(new Nodo(3, "Nodo Parque Rivadavia", -34.6194, -58.4431, "online"));
        nodos.add(new Nodo(4, "Nodo Caminito", -34.6345, -58.3621, "online"));
    }

    // Obtener todos los nodos
    @GetMapping("/api/nodos")
    public List<Nodo> obtenerNodos() {
        return nodos;
    }

    // Cambiar estado de un nodo específico
    @PutMapping("/api/nodos/{id}/estado")
    public Nodo cambiarEstado(@PathVariable int id, @RequestBody EstadoRequest request) {
        for (Nodo nodo : nodos) {
            if (nodo.getId() == id) {
                nodo.setEstado(request.getEstado());
                return nodo;
            }
        }
        throw new RuntimeException("Nodo no encontrado: " + id);
    }

    // Clase interna para recibir el JSON del cuerpo de la petición
    static class EstadoRequest {
        private String estado;

        public String getEstado() {
            return estado;
        }

        public void setEstado(String estado) {
            this.estado = estado;
        }
    }
}