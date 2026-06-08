#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}Generador para NUEVAS Google Maps APIs${NC}"
echo -e "${GREEN}=============================================${NC}\n"

read -p "Ingresa tu API Key (con facturación activa): " API_KEY
if [ -z "$API_KEY" ]; then
    echo -e "${RED}Error: API Key obligatoria${NC}"
    exit 1
fi

# Crear estructura
mkdir -p google-maps-routes-nuevas/{python/src,java/src,web,scripts,docs}
cd google-maps-routes-nuevas

# ============================================
# PYTHON (con Routes API nueva)
# ============================================
echo -e "${GREEN}Generando Python con Routes API...${NC}"

cat > python/requirements.txt << 'EOF'
requests==2.31.0
google-auth==2.29.0
EOF

cat > python/src/route_finder.py << EOF
#!/usr/bin/env python3
import requests
import json
import time

API_KEY = "$API_KEY"
ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes"

def find_route(origin, destination, mode="DRIVE"):
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY,
        "X-Goog-FieldMask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps"
    }

    body = {
        "origin": {"address": origin},
        "destination": {"address": destination},
        "travelMode": mode,
        "routingPreference": "TRAFFIC_AWARE",
        "computeAlternativeRoutes": False,
        "languageCode": "es-ES",
        "units": "METRIC"
    }

    print(f"🔄 Calculando ruta usando Routes API...")
    response = requests.post(ROUTES_URL, headers=headers, json=body)

    if response.status_code == 200:
        data = response.json()
        if "routes" in data and data["routes"]:
            route = data["routes"][0]
            duration = int(route["duration"].replace("s", ""))
            hours = duration // 3600
            minutes = (duration % 3600) // 60
            duracion_str = f"{hours}h {minutes}m" if hours > 0 else f"{minutes}m"

            print(f"\n✅ Ruta encontrada!\n")
            print(f"📏 Distancia: {route['distanceMeters'] / 1000:.1f} km")
            print(f"⏱️ Duración: {duracion_str}")
            print(f"📝 Instrucciones (simplificadas):")

            for i, leg in enumerate(route.get("legs", [])):
                for j, step in enumerate(leg.get("steps", []), 1):
                    print(f"  {j}. {step.get('navigationInstruction', {}).get('instructions', 'Sigue recto')}")
        else:
            print("❌ No se encontraron rutas")
    else:
        print(f"❌ Error API: {response.status_code} - {response.text}")

if __name__ == "__main__":
    print("=== Routes API Finder (Python) ===")
    orig = input("Origen: ")
    dest = input("Destino: ")
    print("\nModos: 1=DRIVE, 2=WALK, 3=BIKE")
    mode_choice = input("Elige: ")
    mode = {"1": "DRIVE", "2": "WALK", "3": "BICYCLE"}.get(mode_choice, "DRIVE")
    find_route(orig, dest, mode)
EOF

chmod +x python/src/route_finder.py

# ============================================
# JAVA (con Routes API usando OkHttp)
# ============================================
echo -e "${GREEN}Generando Java con Routes API...${NC}"

mkdir -p java/src/main/java/com/routes

cat > java/pom.xml << 'EOF'
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.routes</groupId>
  <artifactId>route-finder</artifactId>
  <version>1.0</version>
  <properties>
    <maven.compiler.source>11</maven.compiler.source>
    <maven.compiler.target>11</maven.compiler.target>
  </properties>
  <dependencies>
    <dependency>
      <groupId>com.squareup.okhttp3</groupId>
      <artifactId>okhttp</artifactId>
      <version>4.12.0</version>
    </dependency>
    <dependency>
      <groupId>com.google.code.gson</groupId>
      <artifactId>gson</artifactId>
      <version>2.10.1</version>
    </dependency>
  </dependencies>
</project>
EOF

cat > java/src/main/java/com/routes/RouteFinder.java << EOF
package com.routes;

import okhttp3.*;
import com.google.gson.*;
import java.io.IOException;
import java.util.Scanner;

public class RouteFinder {
    private static final String API_KEY = "$API_KEY";
    private static final String ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes";
    private static final OkHttpClient client = new OkHttpClient();
    private static final Gson gson = new Gson();

    public static void main(String[] args) throws IOException {
        Scanner scanner = new Scanner(System.in);
        System.out.println("=== Routes API Finder (Java) ===");
        System.out.print("Origen: ");
        String origin = scanner.nextLine();
        System.out.print("Destino: ");
        String destination = scanner.nextLine();
        System.out.print("Modo (DRIVE/WALK/BICYCLE): ");
        String mode = scanner.nextLine().toUpperCase();

        findRoute(origin, destination, mode);
    }

    private static void findRoute(String origin, String destination, String mode) throws IOException {
        JsonObject body = new JsonObject();
        body.add("origin", createAddress(origin));
        body.add("destination", createAddress(destination));
        body.addProperty("travelMode", mode);
        body.addProperty("routingPreference", "TRAFFIC_AWARE");
        body.addProperty("languageCode", "es-ES");
        body.addProperty("units", "METRIC");

        Request request = new Request.Builder()
            .url(ROUTES_URL)
            .post(RequestBody.create(MediaType.parse("application/json"), gson.toJson(body)))
            .addHeader("Content-Type", "application/json")
            .addHeader("X-Goog-Api-Key", API_KEY)
            .addHeader("X-Goog-FieldMask", "routes.distanceMeters,routes.duration,routes.legs.steps")
            .build();

        try (Response response = client.newCall(request).execute()) {
            if (response.isSuccessful()) {
                JsonObject json = gson.fromJson(response.body().string(), JsonObject.class);
                JsonObject route = json.getAsJsonArray("routes").get(0).getAsJsonObject();
                double km = route.get("distanceMeters").getAsDouble() / 1000;
                int seconds = route.get("duration").getAsString().replace("s", "").isEmpty() ? 0 :
                              Integer.parseInt(route.get("duration").getAsString().replace("s", ""));
                System.out.printf("\n✅ Ruta encontrada!\n📏 %.1f km\n⏱️ %d min\n", km, seconds/60);
            } else {
                System.err.println("Error: " + response.body().string());
            }
        }
    }

    private static JsonObject createAddress(String address) {
        JsonObject obj = new JsonObject();
        obj.addProperty("address", address);
        return obj;
    }
}
EOF

# ============================================
# WEB (con Maps JavaScript API, evitando legados)
# ============================================
echo -e "${GREEN}Generando Web con Maps JS API...${NC}"

cat > web/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Nuevas APIs - Route Finder</title>
    <style>#map { height: 500px; }</style>
</head>
<body>
    <h1>🗺️ Routes Finder (Nueva API)</h1>
    <input id="origin" placeholder="Origen" size="40">
    <input id="dest" placeholder="Destino" size="40">
    <button onclick="calcular()">Ruta</button>
    <div id="map"></div>
    <div id="info"></div>

    <script>
        let map, directionsService, directionsRenderer;

        function initMap() {
            map = new google.maps.Map(document.getElementById("map"), {
                center: {lat: -34.6037, lng: -58.3816},
                zoom: 12
            });
            directionsService = new google.maps.DirectionsService();
            directionsRenderer = new google.maps.DirectionsRenderer({map: map});
        }

        function calcular() {
            const request = {
                origin: document.getElementById("origin").value,
                destination: document.getElementById("dest").value,
                travelMode: google.maps.TravelMode.DRIVING,
                unitSystem: google.maps.UnitSystem.METRIC
            };
            directionsService.route(request, (result, status) => {
                if (status === "OK") {
                    directionsRenderer.setDirections(result);
                    const leg = result.routes[0].legs[0];
                    document.getElementById("info").innerHTML =
                        `<b>Distancia:</b> \${leg.distance.text}<br>
                         <b>Duración:</b> \${leg.duration.text}<br>
                         <b>Instrucciones:</b> \${leg.steps.length} pasos`;
                } else {
                    document.getElementById("info").innerHTML = "Error: " + status;
                }
            });
        }
    </script>
    <script src="https://maps.googleapis.com/maps/api/js?key=$API_KEY&callback=initMap&libraries=places" async defer></script>
</body>
</html>
EOF

# ============================================
# DOCUMENTACIÓN Y EJECUTOR
# ============================================
cat > run.sh << EOF
#!/bin/bash
echo "=== Menú Routes API Nueva ==="
echo "1) Python (Routes API v2)"
echo "2) Java (Routes API v2)"
echo "3) Web (Maps JS API)"
read -p "Opción: " opt

case \$opt in
    1) cd python && python3 src/route_finder.py ;;
    2) cd java && mvn compile exec:java -Dexec.mainClass=com.routes.RouteFinder ;;
    3) cd web && python3 -m http.server 8000 ;;
    *) echo "Opción inválida" ;;
esac
EOF

chmod +x run.sh

echo -e "${GREEN}✅ Proyecto generado para NUEVAS APIs (Routes API y Places API New)${NC}"
echo -e "${YELLOW}⚠️ IMPORTANTE:${NC}"
echo "   • Debes tener facturación activa en Google Cloud"
echo "   • Habilita 'Routes API' y 'Maps JavaScript API' en tu proyecto"
echo "   • NO necesitas habilitar Directions API (legacy)"
echo -e "\n${GREEN}Para probar: cd google-maps-routes-nuevas && ./run.sh${NC}"
