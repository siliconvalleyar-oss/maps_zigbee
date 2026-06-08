#!/bin/bash

# 1. Definir nombre del proyecto y directorio
PROYECTO="monitoreo-nodos-zigbee"
echo "Creando proyecto $PROYECTO ..."

mkdir -p $PROYECTO
cd $PROYECTO

# 2. Crear estructura de directorios
mkdir -p src/main/java/com/ejemplo/demo
mkdir -p src/main/resources/templates
mkdir -p src/main/resources/static

# 3. Generar pom.xml
cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>

    <groupId>com.ejemplo</groupId>
    <artifactId>monitoreo-nodos-zigbee</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>monitoreo-nodos-zigbee</name>
    <description>Demo de monitoreo de nodos ZigBee sobre Google Maps</description>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-thymeleaf</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>
EOF

# 4. Generar la clase principal de Spring Boot
cat > src/main/java/com/ejemplo/demo/DemoApplication.java << 'EOF'
package com.ejemplo.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

}
EOF

# 5. Generar el modelo Nodo
cat > src/main/java/com/ejemplo/demo/Nodo.java << 'EOF'
package com.ejemplo.demo;

public class Nodo {
    private int id;
    private String nombre;
    private double latitud;
    private double longitud;
    private String estado; // online, warning, offline

    public Nodo() {}

    public Nodo(int id, String nombre, double latitud, double longitud, String estado) {
        this.id = id;
        this.nombre = nombre;
        this.latitud = latitud;
        this.longitud = longitud;
        this.estado = estado;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public double getLatitud() { return latitud; }
    public void setLatitud(double latitud) { this.latitud = latitud; }

    public double getLongitud() { return longitud; }
    public void setLongitud(double longitud) { this.longitud = longitud; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
}
EOF

# 6. Generar el controlador REST
cat > src/main/java/com/ejemplo/demo/NodoController.java << 'EOF'
package com.ejemplo.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.ArrayList;
import java.util.List;

@RestController
public class NodoController {

    @GetMapping("/api/nodos")
    public List<Nodo> obtenerNodos() {
        List<Nodo> nodos = new ArrayList<>();
        nodos.add(new Nodo(1, "Nodo Plaza de Mayo", -34.6083, -58.3712, "online"));
        nodos.add(new Nodo(2, "Nodo Plaza Italia", -34.5812, -58.4215, "warning"));
        nodos.add(new Nodo(3, "Nodo Parque Rivadavia", -34.6194, -58.4431, "offline"));
        nodos.add(new Nodo(4, "Nodo Caminito", -34.6345, -58.3621, "online"));
        return nodos;
    }
}
EOF

# 7. Generar la plantilla HTML con el mapa de Google
cat > src/main/resources/templates/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Monitoreo de Nodos Zigbee en CABA</title>
    <style>
        #map { height: 100%; }
        html, body { height: 100%; margin: 0; padding: 0; }
    </style>
</head>
<body>
    <div id="map"></div>

    <script>
        function initMap() {
            const map = new google.maps.Map(document.getElementById('map'), {
                center: { lat: -34.6118, lng: -58.4173 },
                zoom: 13
            });

            fetch('/api/nodos')
                .then(response => response.json())
                .then(nodos => {
                    nodos.forEach(nodo => {
                        let icono;
                        switch(nodo.estado) {
                            case 'online':
                                icono = 'http://maps.google.com/mapfiles/ms/icons/green-dot.png';
                                break;
                            case 'warning':
                                icono = 'http://maps.google.com/mapfiles/ms/icons/yellow-dot.png';
                                break;
                            case 'offline':
                                icono = 'http://maps.google.com/mapfiles/ms/icons/red-dot.png';
                                break;
                            default:
                                icono = null;
                        }

                        const marker = new google.maps.Marker({
                            position: { lat: nodo.latitud, lng: nodo.longitud },
                            map: map,
                            title: nodo.nombre,
                            icon: icono
                        });

                        const infowindow = new google.maps.InfoWindow({
                            content: `<b>${nodo.nombre}</b><br>ID: ${nodo.id}<br>Estado: ${nodo.estado}`
                        });

                        marker.addListener('click', () => {
                            infowindow.open(map, marker);
                        });
                    });
                })
                .catch(error => console.error('Error al obtener nodos:', error));
        }
    </script>
    <!-- ⚠️ Reemplaza 'TU_API_KEY' con tu propia clave de Google Maps -->
    <script async defer src="https://maps.googleapis.com/maps/api/js?key=TU_API_KEY&callback=initMap"></script>
</body>
</html>
EOF

echo ""
echo "✅ Proyecto '$PROYECTO' generado correctamente."
echo ""
echo "📁 Estructura creada:"
echo "   ├── pom.xml"
echo "   └── src"
echo "       └── main"
echo "           ├── java/com/ejemplo/demo"
echo "           │   ├── DemoApplication.java"
echo "           │   ├── Nodo.java"
echo "           │   └── NodoController.java"
echo "           └── resources"
echo "               └── templates"
echo "                   └── index.html"
echo ""
echo "⚙️  Para ejecutar:"
echo "   1. Edita src/main/resources/templates/index.html y reemplaza 'TU_API_KEY' por tu clave de Google Maps."
echo "   2. Ejecuta: cd $PROYECTO && mvn spring-boot:run"
echo "   3. Abre en el navegador: http://localhost:8080"
echo ""
