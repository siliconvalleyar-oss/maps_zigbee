#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Generador de Proyecto Google Maps Routes${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Solicitar API Key
read -p "Ingresa tu Google Maps API Key: " API_KEY
if [ -z "$API_KEY" ]; then
    echo -e "${RED}Error: La API Key es obligatoria${NC}"
    exit 1
fi

# Crear estructura de directorios
echo -e "${YELLOW}Creando estructura de directorios...${NC}"

# Crear todos los directorios necesarios
mkdir -p google-maps-routes/java/src
mkdir -p google-maps-routes/cpp/src
mkdir -p google-maps-routes/python/src
mkdir -p google-maps-routes/javascript/web
mkdir -p google-maps-routes/docs
mkdir -p google-maps-routes/scripts

cd google-maps-routes

# ============================================
# 1. JAVA PROYECTO (con Maven)
# ============================================
echo -e "${GREEN}Generando proyecto Java...${NC}"

# pom.xml
cat > java/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.googlemaps</groupId>
    <artifactId>route-finder</artifactId>
    <version>1.0</version>
    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
    </properties>
    <dependencies>
        <dependency>
            <groupId>com.google.maps</groupId>
            <artifactId>google-maps-services</artifactId>
            <version>2.2.0</version>
        </dependency>
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-simple</artifactId>
            <version>1.7.36</version>
        </dependency>
    </dependencies>
</project>
EOF

# Código Java principal
cat > java/src/RouteFinder.java << EOF
import com.google.maps.DirectionsApi;
import com.google.maps.GeoApiContext;
import com.google.maps.model.DirectionsResult;
import com.google.maps.model.TravelMode;
import java.util.Scanner;

public class RouteFinder {
    private static final String API_KEY = "$API_KEY";

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.println("=== Google Maps Route Finder ===");
        System.out.print("Origen: ");
        String origin = scanner.nextLine();
        System.out.print("Destino: ");
        String destination = scanner.nextLine();

        // Menú de modo de viaje
        System.out.println("\nModos de viaje:");
        System.out.println("1. Coche");
        System.out.println("2. A pie");
        System.out.println("3. Bicicleta");
        System.out.println("4. Transporte público");
        System.out.print("Elige una opción (1-4): ");
        int modeChoice = scanner.nextInt();

        TravelMode mode;
        switch(modeChoice) {
            case 1: mode = TravelMode.DRIVING; break;
            case 2: mode = TravelMode.WALKING; break;
            case 3: mode = TravelMode.BICYCLING; break;
            case 4: mode = TravelMode.TRANSIT; break;
            default: mode = TravelMode.DRIVING;
        }

        findRoute(origin, destination, mode);
    }

    private static void findRoute(String origin, String destination, TravelMode mode) {
        try {
            GeoApiContext context = new GeoApiContext.Builder()
                .apiKey(API_KEY)
                .build();

            DirectionsResult result = DirectionsApi.newRequest(context)
                .origin(origin)
                .destination(destination)
                .mode(mode)
                .await();

            if (result.routes.length > 0) {
                var route = result.routes[0];
                var leg = route.legs[0];

                System.out.println("\n✅ Ruta encontrada!\n");
                System.out.println("📍 Origen: " + leg.startAddress);
                System.out.println("🎯 Destino: " + leg.endAddress);
                System.out.println("📏 Distancia: " + leg.distance.humanReadable);
                System.out.println("⏱️  Duración: " + leg.duration.humanReadable);
                System.out.println("\n📝 Instrucciones:");

                int stepNum = 1;
                for (var step : leg.steps) {
                    String instruction = step.htmlInstructions.replaceAll("<[^>]*>", "");
                    System.out.println(stepNum++ + ". " + instruction);
                    System.out.println("   " + step.distance.humanReadable + " (" + step.duration.humanReadable + ")\n");
                }
            } else {
                System.out.println("❌ No se encontraron rutas");
            }

            context.shutdown();
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
        }
    }
}
EOF

# ============================================
# 2. C++ PROYECTO
# ============================================
echo -e "${GREEN}Generando proyecto C++...${NC}"

# Makefile para C++
cat > cpp/Makefile << 'EOF'
CXX = g++
CXXFLAGS = -std=c++11 -Wall
LDFLAGS = -lcurl -ljsoncpp

TARGET = route_finder
SOURCES = src/RouteFinder.cpp
OBJECTS = $(SOURCES:.cpp=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $(OBJECTS) -o $(TARGET) $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean run
EOF

# Código C++
cat > cpp/src/RouteFinder.cpp << 'EOF'
#include <iostream>
#include <string>
#include <curl/curl.h>
#include <json/json.h>
#include <sstream>

// Callback para escribir la respuesta de CURL
size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* userp) {
    size_t totalSize = size * nmemb;
    userp->append((char*)contents, totalSize);
    return totalSize;
}

class GoogleMapsClient {
private:
    std::string apiKey;
    CURL* curl;

    std::string urlEncode(const std::string& value) {
        CURL* curl = curl_easy_init();
        char* encoded = curl_easy_escape(curl, value.c_str(), value.length());
        std::string result(encoded);
        curl_free(encoded);
        curl_easy_cleanup(curl);
        return result;
    }

public:
    GoogleMapsClient(const std::string& key) : apiKey(key) {
        curl_global_init(CURL_GLOBAL_DEFAULT);
        curl = curl_easy_init();
    }

    ~GoogleMapsClient() {
        if(curl) curl_easy_cleanup(curl);
        curl_global_cleanup();
    }

    bool getDirections(const std::string& origin, const std::string& destination,
                       const std::string& mode) {
        std::string url = "https://maps.googleapis.com/maps/api/directions/json?"
                         "origin=" + urlEncode(origin) +
                         "&destination=" + urlEncode(destination) +
                         "&mode=" + mode +
                         "&key=" + apiKey;

        std::string response;
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

        CURLcode res = curl_easy_perform(curl);

        if(res != CURLE_OK) {
            std::cerr << "Error HTTP: " << curl_easy_strerror(res) << std::endl;
            return false;
        }

        // Parsear JSON (simplificado)
        Json::Value root;
        Json::CharReaderBuilder reader;
        std::string errs;

        std::istringstream sstream(response);
        if(Json::parseFromStream(reader, sstream, &root, &errs)) {
            if(root["status"].asString() == "OK") {
                auto route = root["routes"][0];
                auto leg = route["legs"][0];

                std::cout << "\n✅ Ruta encontrada!\n" << std::endl;
                std::cout << "📍 Origen: " << leg["start_address"].asString() << std::endl;
                std::cout << "🎯 Destino: " << leg["end_address"].asString() << std::endl;
                std::cout << "📏 Distancia: " << leg["distance"]["text"].asString() << std::endl;
                std::cout << "⏱️  Duración: " << leg["duration"]["text"].asString() << std::endl;

                std::cout << "\n📝 Instrucciones:" << std::endl;
                int stepNum = 1;
                for(const auto& step : leg["steps"]) {
                    std::cout << stepNum++ << ". "
                              << step["html_instructions"].asString() << std::endl;
                    std::cout << "   " << step["distance"]["text"].asString()
                              << " (" << step["duration"]["text"].asString() << ")\n" << std::endl;
                }
                return true;
            } else {
                std::cout << "❌ Error: " << root["status"].asString() << std::endl;
                return false;
            }
        }
        return false;
    }
};

int main() {
    std::string apiKey = "$API_KEY";
    GoogleMapsClient client(apiKey);

    std::string origin, destination;
    int modeChoice;

    std::cout << "=== Google Maps Route Finder (C++) ===" << std::endl;
    std::cout << "Origen: ";
    std::getline(std::cin, origin);
    std::cout << "Destino: ";
    std::getline(std::cin, destination);

    std::cout << "\nModos de viaje:" << std::endl;
    std::cout << "1. Coche" << std::endl;
    std::cout << "2. A pie" << std::endl;
    std::cout << "3. Bicicleta" << std::endl;
    std::cout << "4. Transporte público" << std::endl;
    std::cout << "Elige una opción (1-4): ";
    std::cin >> modeChoice;
    std::cin.ignore();

    std::string mode;
    switch(modeChoice) {
        case 1: mode = "driving"; break;
        case 2: mode = "walking"; break;
        case 3: mode = "bicycling"; break;
        case 4: mode = "transit"; break;
        default: mode = "driving";
    }

    client.getDirections(origin, destination, mode);

    return 0;
}
EOF

# ============================================
# 3. PYTHON PROYECTO
# ============================================
echo -e "${GREEN}Generando proyecto Python...${NC}"

# requirements.txt
cat > python/requirements.txt << 'EOF'
googlemaps==4.10.0
requests==2.31.0
EOF

# Código Python
cat > python/src/route_finder.py << EOF
#!/usr/bin/env python3
import googlemaps
import sys
from datetime import datetime

class GoogleMapsRouteFinder:
    def __init__(self, api_key):
        self.gmaps = googlemaps.Client(key=api_key)

    def find_route(self, origin, destination, mode="driving"):
        try:
            # Obtener direcciones
            directions = self.gmaps.directions(
                origin,
                destination,
                mode=mode,
                departure_time=datetime.now()
            )

            if not directions:
                print("❌ No se encontraron rutas")
                return

            route = directions[0]
            leg = route['legs'][0]

            print("\n✅ Ruta encontrada!\n")
            print(f"📍 Origen: {leg['start_address']}")
            print(f"🎯 Destino: {leg['end_address']}")
            print(f"📏 Distancia: {leg['distance']['text']}")
            print(f"⏱️  Duración: {leg['duration']['text']}")

            print("\n📝 Instrucciones:")
            for i, step in enumerate(leg['steps'], 1):
                instruction = step['html_instructions'].replace('<b>', '').replace('</b>', '')
                print(f"{i}. {instruction}")
                print(f"   {step['distance']['text']} ({step['duration']['text']})\n")

        except Exception as e:
            print(f"❌ Error: {e}")

    def get_route_polyline(self, origin, destination, mode="driving"):
        """Obtiene el polyline de la ruta para dibujar"""
        directions = self.gmaps.directions(origin, destination, mode=mode)
        if directions:
            return directions[0]['overview_polyline']['points']
        return None

def main():
    API_KEY = "$API_KEY"

    print("=== Google Maps Route Finder (Python) ===")
    origin = input("Origen: ")
    destination = input("Destino: ")

    print("\nModos de viaje:")
    print("1. Coche")
    print("2. A pie")
    print("3. Bicicleta")
    print("4. Transporte público")
    choice = input("Elige una opción (1-4): ")

    mode_map = {
        '1': 'driving',
        '2': 'walking',
        '3': 'bicycling',
        '4': 'transit'
    }
    mode = mode_map.get(choice, 'driving')

    finder = GoogleMapsRouteFinder(API_KEY)
    finder.find_route(origin, destination, mode)

if __name__ == "__main__":
    main()
EOF

# ============================================
# 4. JAVASCRIPT (Web)
# ============================================
echo -e "${GREEN}Generando proyecto JavaScript Web...${NC}"

# HTML principal
cat > javascript/web/index.html << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Google Maps Route Finder</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
            width: 90%;
            max-width: 1200px;
            height: 90vh;
            display: flex;
            flex-direction: column;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            text-align: center;
        }

        .header h1 {
            font-size: 24px;
        }

        .controls {
            padding: 20px;
            background: #f8f9fa;
            border-bottom: 1px solid #e0e0e0;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }

        .controls input, .controls select, .controls button {
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
        }

        .controls input {
            flex: 2;
            min-width: 200px;
        }

        .controls select {
            flex: 1;
            min-width: 120px;
        }

        .controls button {
            background: #667eea;
            color: white;
            border: none;
            cursor: pointer;
            transition: background 0.3s;
            padding: 10px 20px;
        }

        .controls button:hover {
            background: #764ba2;
        }

        #map {
            flex: 1;
            width: 100%;
        }

        .info {
            background: white;
            padding: 15px;
            border-top: 1px solid #e0e0e0;
            max-height: 200px;
            overflow-y: auto;
            font-size: 14px;
        }

        .info h3 {
            margin-bottom: 10px;
            color: #667eea;
        }

        .info p {
            margin: 5px 0;
        }

        .instructions {
            margin-top: 10px;
            padding-left: 20px;
        }

        .instructions li {
            margin: 5px 0;
        }

        @media (max-width: 768px) {
            .controls {
                flex-direction: column;
            }

            .controls input, .controls select, .controls button {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🗺️ Google Maps Route Finder</h1>
            <p>Encuentra la mejor ruta entre dos puntos</p>
        </div>

        <div class="controls">
            <input type="text" id="origin" placeholder="Origen (ej: Plaza Mayor, Madrid)" value="Plaza Mayor, Madrid">
            <input type="text" id="destination" placeholder="Destino (ej: Puerta del Sol, Madrid)" value="Puerta del Sol, Madrid">
            <select id="travelMode">
                <option value="DRIVING">🚗 Coche</option>
                <option value="WALKING">🚶 A pie</option>
                <option value="BICYCLING">🚲 Bicicleta</option>
                <option value="TRANSIT">🚇 Transporte público</option>
            </select>
            <button onclick="calculateRoute()">Calcular Ruta</button>
        </div>

        <div id="map"></div>

        <div class="info" id="info">
            <h3>ℹ️ Información de la Ruta</h3>
            <p>Ingresa un origen y destino para calcular la ruta</p>
        </div>
    </div>

    <script>
        let map;
        let directionsService;
        let directionsRenderer;

        function initMap() {
            // Centro de Madrid por defecto
            const defaultCenter = { lat: 40.416775, lng: -3.703790 };

            map = new google.maps.Map(document.getElementById("map"), {
                zoom: 12,
                center: defaultCenter,
            });

            directionsService = new google.maps.DirectionsService();
            directionsRenderer = new google.maps.DirectionsRenderer();
            directionsRenderer.setMap(map);
        }

        function calculateRoute() {
            const origin = document.getElementById("origin").value;
            const destination = document.getElementById("destination").value;
            const travelMode = document.getElementById("travelMode").value;

            if (!origin || !destination) {
                alert("Por favor, ingresa origen y destino");
                return;
            }

            const request = {
                origin: origin,
                destination: destination,
                travelMode: google.maps.TravelMode[travelMode],
                provideRouteAlternatives: true
            };

            directionsService.route(request, (result, status) => {
                if (status === "OK") {
                    directionsRenderer.setDirections(result);
                    displayRouteInfo(result);
                } else {
                    console.error("Error al calcular ruta:", status);
                    document.getElementById("info").innerHTML = \`
                        <h3>❌ Error</h3>
                        <p>No se pudo encontrar una ruta. Verifica las direcciones.</p>
                        <p>Error: \${status}</p>
                    \`;
                }
            });
        }

        function displayRouteInfo(result) {
            const route = result.routes[0];
            const leg = route.legs[0];

            let instructionsHtml = '<div class="instructions"><ol>';
            leg.steps.forEach(step => {
                instructionsHtml += \`<li>\${step.instructions}</li>\`;
            });
            instructionsHtml += '</ol></div>';

            document.getElementById("info").innerHTML = \`
                <h3>✅ Ruta encontrada</h3>
                <p><strong>📍 Desde:</strong> \${leg.start_address}</p>
                <p><strong>🎯 Hasta:</strong> \${leg.end_address}</p>
                <p><strong>📏 Distancia:</strong> \${leg.distance.text}</p>
                <p><strong>⏱️ Duración:</strong> \${leg.duration.text}</p>
                <h3>📝 Instrucciones paso a paso:</h3>
                \${instructionsHtml}
            \`;
        }
    </script>
    <script src="https://maps.googleapis.com/maps/api/js?key=$API_KEY&callback=initMap&libraries=places" async defer></script>
</body>
</html>
EOF

# ============================================
# 5. DOCUMENTACIÓN
# ============================================
echo -e "${GREEN}Generando documentación...${NC}"

# README principal
cat > README.md << 'EOF'
# Google Maps Route Finder

Un proyecto completo para trazar rutas usando Google Maps API en múltiples lenguajes.

## 📁 Estructura del Proyecto
