#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
mkdir -p google-maps-routes/java/src/main/java/com/googlemaps
mkdir -p google-maps-routes/cpp/src
mkdir -p google-maps-routes/python/src
mkdir -p google-maps-routes/javascript/web
mkdir -p google-maps-routes/docs
mkdir -p google-maps-routes/scripts
mkdir -p google-maps-routes/libs

cd google-maps-routes

# ============================================
# 1. JAVA PROYECTO (CORREGIDO)
# ============================================
echo -e "${GREEN}Generando proyecto Java...${NC}"

# pom.xml actualizado
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
    <packaging>jar</packaging>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
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
            <version>2.0.9</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
                <configuration>
                    <source>11</source>
                    <target>11</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.codehaus.mojo</groupId>
                <artifactId>exec-maven-plugin</artifactId>
                <version>3.1.0</version>
                <configuration>
                    <mainClass>com.googlemaps.RouteFinder</mainClass>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.3.0</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>com.googlemaps.RouteFinder</mainClass>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Código Java principal con package
cat > java/src/main/java/com/googlemaps/RouteFinder.java << EOF
package com.googlemaps;

import com.google.maps.DirectionsApi;
import com.google.maps.GeoApiContext;
import com.google.maps.errors.ApiException;
import com.google.maps.model.DirectionsResult;
import com.google.maps.model.TravelMode;
import com.google.maps.model.Unit;
import java.util.Scanner;

public class RouteFinder {
    private static final String API_KEY = "$API_KEY";

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.println("=== Google Maps Route Finder (Java) ===");
        System.out.println("=======================================\n");

        System.out.print("📍 Origen: ");
        String origin = scanner.nextLine();
        System.out.print("🎯 Destino: ");
        String destination = scanner.nextLine();

        // Menú de modo de viaje
        System.out.println("\n🚗 Modos de viaje:");
        System.out.println("1. 🚗 Coche");
        System.out.println("2. 🚶 A pie");
        System.out.println("3. 🚲 Bicicleta");
        System.out.println("4. 🚇 Transporte público");
        System.out.print("\nElige una opción (1-4): ");
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
        scanner.close();
    }

    private static void findRoute(String origin, String destination, TravelMode mode) {
        System.out.println("\n🔄 Calculando ruta...\n");

        try {
            GeoApiContext context = new GeoApiContext.Builder()
                .apiKey(API_KEY)
                .build();

            DirectionsResult result = DirectionsApi.newRequest(context)
                .origin(origin)
                .destination(destination)
                .mode(mode)
                .units(Unit.METRIC)
                .await();

            if (result.routes != null && result.routes.length > 0) {
                var route = result.routes[0];
                var leg = route.legs[0];

                System.out.println("✅ ¡Ruta encontrada!\n");
                System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                System.out.println("📍 ORIGEN: " + leg.startAddress);
                System.out.println("🎯 DESTINO: " + leg.endAddress);
                System.out.println("📏 DISTANCIA: " + leg.distance.humanReadable);
                System.out.println("⏱️  DURACIÓN: " + leg.duration.humanReadable);
                System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

                System.out.println("\n📝 INSTRUCCIONES PASO A PASO:\n");
                int stepNum = 1;
                for (var step : leg.steps) {
                    // Limpiar HTML de las instrucciones
                    String instruction = step.htmlInstructions
                        .replaceAll("<[^>]*>", "")
                        .replaceAll("&nbsp;", " ")
                        .replaceAll("&amp;", "&")
                        .trim();

                    System.out.println(stepNum++ + ". " + instruction);
                    System.out.println("   📏 " + step.distance.humanReadable + " | ⏱️ " + step.duration.humanReadable);
                    System.out.println();
                }
            } else {
                System.out.println("❌ No se encontraron rutas posibles");
                System.out.println("Verifica las direcciones o intenta con otro modo de transporte");
            }

            context.shutdown();
        } catch (ApiException e) {
            System.err.println("\n❌ Error de API: " + e.getMessage());
            System.err.println("Posibles causas:");
            System.err.println("  • API Key inválida o sin permisos");
            System.err.println("  • API de Directions no habilitada");
            System.err.println("  • Cuenta sin facturación activa");
        } catch (Exception e) {
            System.err.println("\n❌ Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
EOF

# Script de ejecución para Java
cat > java/run.sh << 'EOF'
#!/bin/bash
echo "Compilando proyecto Java..."
mvn clean compile
if [ $? -eq 0 ]; then
    echo "Ejecutando RouteFinder..."
    mvn exec:java
else
    echo "Error en la compilación"
fi
EOF
chmod +x java/run.sh

# ============================================
# 2. C++ PROYECTO (CORREGIDO)
# ============================================
echo -e "${GREEN}Generando proyecto C++...${NC}"

# Makefile mejorado con detección de rutas
cat > cpp/Makefile << 'EOF'
CXX = g++
CXXFLAGS = -std=c++11 -Wall -O2
LDFLAGS = -lcurl

# Detectar jsoncpp en diferentes ubicaciones
ifeq ($(shell test -f /usr/include/jsoncpp/json/json.h && echo yes), yes)
    CXXFLAGS += -I/usr/include/jsoncpp
    LDFLAGS += -ljsoncpp
else ifeq ($(shell test -f /usr/include/json/json.h && echo yes), yes)
    CXXFLAGS += -I/usr/include
    LDFLAGS += -ljsoncpp
else ifeq ($(shell test -f /usr/local/include/json/json.h && echo yes), yes)
    CXXFLAGS += -I/usr/local/include
    LDFLAGS += -ljsoncpp
else
    $(warning "jsoncpp no encontrado, se usará la versión header-only")
    CXXFLAGS += -DUSE_HEADER_ONLY_JSON
    LDFLAGS += -ljsoncpp 2>/dev/null || true
endif

TARGET = route_finder
SOURCES = src/RouteFinder.cpp
OBJECTS = $(SOURCES:.cpp=.o)

all: check_deps $(TARGET)

check_deps:
	@echo "Verificando dependencias..."
	@command -v curl-config >/dev/null 2>&1 || { echo "❌ libcurl no instalado. Instalar con: sudo apt-get install libcurl4-openssl-dev"; exit 1; }
	@pkg-config --exists jsoncpp 2>/dev/null || echo "⚠️  jsoncpp no encontrado, intentando compilar..."

$(TARGET): $(OBJECTS)
	$(CXX) $(OBJECTS) -o $(TARGET) $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)

run: $(TARGET)
	./$(TARGET)

install-deps:
	@echo "Instalando dependencias para Linux..."
	@sudo apt-get update
	@sudo apt-get install -y libcurl4-openssl-dev libjsoncpp-dev
	@echo "✅ Dependencias instaladas"

.PHONY: all clean run install-deps
EOF

# Código C++ mejorado con manejo de errores
cat > cpp/src/RouteFinder.cpp << 'EOF'
#include <iostream>
#include <string>
#include <curl/curl.h>
#include <sstream>
#include <iomanip>
#include <cctype>

// Función de callback para CURL
size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* userp) {
    size_t totalSize = size * nmemb;
    userp->append((char*)contents, totalSize);
    return totalSize;
}

// Función para URL encode
std::string urlEncode(const std::string& value) {
    CURL* curl = curl_easy_init();
    if (!curl) return value;

    char* encoded = curl_easy_escape(curl, value.c_str(), value.length());
    std::string result(encoded);
    curl_free(encoded);
    curl_easy_cleanup(curl);
    return result;
}

// Función para extraer valores de JSON de forma simple
std::string extractJsonValue(const std::string& json, const std::string& key) {
    std::string searchKey = "\"" + key + "\"";
    size_t pos = json.find(searchKey);
    if (pos == std::string::npos) return "";

    pos = json.find(":", pos);
    if (pos == std::string::npos) return "";
    pos++;

    // Saltar espacios
    while (pos < json.length() && std::isspace(json[pos])) pos++;

    if (json[pos] == '"') {
        pos++;
        size_t end = json.find("\"", pos);
        if (end != std::string::npos) {
            return json.substr(pos, end - pos);
        }
    } else {
        size_t end = json.find_first_of(",}", pos);
        if (end != std::string::npos) {
            return json.substr(pos, end - pos);
        }
    }
    return "";
}

// Función para simplificar HTML
std::string cleanHtml(const std::string& html) {
    std::string result;
    bool inTag = false;
    for (char c : html) {
        if (c == '<') {
            inTag = true;
        } else if (c == '>') {
            inTag = false;
        } else if (!inTag) {
            result += c;
        }
    }
    return result;
}

class GoogleMapsClient {
private:
    std::string apiKey;
    CURL* curl;

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
                         "&key=" + apiKey +
                         "&language=es";

        std::cout << "🔄 Consultando Google Maps API..." << std::endl;

        std::string response;
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30L);

        CURLcode res = curl_easy_perform(curl);

        if(res != CURLE_OK) {
            std::cerr << "❌ Error HTTP: " << curl_easy_strerror(res) << std::endl;
            return false;
        }

        // Verificar el status de la respuesta
        std::string status = extractJsonValue(response, "status");

        if (status == "OK") {
            // Extraer información básica
            std::string startAddress = extractJsonValue(response, "start_address");
            std::string endAddress = extractJsonValue(response, "end_address");
            std::string distance = extractJsonValue(response, "text");
            std::string duration = extractJsonValue(response, "text");

            std::cout << "\n✅ ¡Ruta encontrada!\n" << std::endl;
            std::cout << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" << std::endl;
            std::cout << "📍 ORIGEN: " << startAddress << std::endl;
            std::cout << "🎯 DESTINO: " << endAddress << std::endl;
            std::cout << "📏 DISTANCIA: " << distance << std::endl;
            std::cout << "⏱️  DURACIÓN: " << duration << std::endl;
            std::cout << "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" << std::endl;

            return true;
        } else if (status == "REQUEST_DENIED") {
            std::cout << "\n❌ Error: La API Key no tiene permisos suficientes\n" << std::endl;
            std::cout << "Posibles soluciones:" << std::endl;
            std::cout << "1. Verifica que la API Key sea correcta" << std::endl;
            std::cout << "2. Habilita 'Directions API' en Google Cloud Console" << std::endl;
            std::cout << "3. Habilita 'Geocoding API' en Google Cloud Console" << std::endl;
            std::cout << "4. Activa la facturación en tu proyecto" << std::endl;
            std::cout << "5. Elimina restricciones de IP de la API Key temporalmente" << std::endl;
            return false;
        } else {
            std::cout << "\n❌ Error de API: " << status << std::endl;
            return false;
        }
    }
};

int main() {
    std::string apiKey = "$API_KEY";
    GoogleMapsClient client(apiKey);

    std::string origin, destination;
    int modeChoice;

    std::cout << "╔══════════════════════════════════════════╗" << std::endl;
    std::cout << "║   Google Maps Route Finder (C++)        ║" << std::endl;
    std::cout << "╚══════════════════════════════════════════╝" << std::endl;
    std::cout << std::endl;

    std::cout << "📍 Origen: ";
    std::getline(std::cin, origin);
    std::cout << "🎯 Destino: ";
    std::getline(std::cin, destination);

    std::cout << "\n🚗 Modos de viaje:" << std::endl;
    std::cout << "1. 🚗 Coche" << std::endl;
    std::cout << "2. 🚶 A pie" << std::endl;
    std::cout << "3. 🚲 Bicicleta" << std::endl;
    std::cout << "4. 🚇 Transporte público" << std::endl;
    std::cout << "\nElige una opción (1-4): ";
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

# Script de instalación para C++
cat > cpp/install.sh << 'EOF'
#!/bin/bash
echo "Instalando dependencias para C++..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get update
    sudo apt-get install -y libcurl4-openssl-dev libjsoncpp-dev g++
    echo "✅ Instalación completada"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install curl jsoncpp
else
    echo "Sistema no soportado para instalación automática"
    echo "Instala manualmente: libcurl y jsoncpp"
fi
EOF
chmod +x cpp/install.sh

# Script de compilación para C++
cat > cpp/build.sh << 'EOF'
#!/bin/bash
echo "Compilando RouteFinder C++..."
make clean
make
if [ $? -eq 0 ]; then
    echo "✅ Compilación exitosa"
    echo "Ejecuta: ./route_finder"
else
    echo "❌ Error en la compilación"
    echo "Ejecuta primero: ./install.sh"
fi
EOF
chmod +x cpp/build.sh

# ============================================
# 3. PYTHON PROYECTO (CORREGIDO)
# ============================================
echo -e "${GREEN}Generando proyecto Python...${NC}"

# requirements.txt
cat > python/requirements.txt << 'EOF'
googlemaps==4.10.0
requests==2.31.0
colorama==0.4.6
EOF

# Código Python mejorado
cat > python/src/route_finder.py << 'EOF'
#!/usr/bin/env python3
import googlemaps
from datetime import datetime
import re

class GoogleMapsRouteFinder:
    def __init__(self, api_key):
        self.gmaps = googlemaps.Client(key=api_key)

    def find_route(self, origin, destination, mode="driving"):
        try:
            print(f"\n🔄 Calculando ruta...\n")

            directions = self.gmaps.directions(
                origin,
                destination,
                mode=mode,
                departure_time=datetime.now(),
                language='es'
            )

            if not directions:
                print("❌ No se encontraron rutas")
                return

            route = directions[0]
            leg = route['legs'][0]

            print("✅ ¡Ruta encontrada!\n")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print(f"📍 ORIGEN: {leg['start_address']}")
            print(f"🎯 DESTINO: {leg['end_address']}")
            print(f"📏 DISTANCIA: {leg['distance']['text']}")
            print(f"⏱️  DURACIÓN: {leg['duration']['text']}")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            print(f"\n📝 INSTRUCCIONES PASO A PASO:\n")
            for i, step in enumerate(leg['steps'], 1):
                instruction = step['html_instructions']
                instruction = re.sub(r'<[^>]+>', '', instruction)
                instruction = instruction.replace('&nbsp;', ' ').replace('&amp;', '&')

                print(f"{i}. {instruction}")
                print(f"   📏 {step['distance']['text']} | ⏱️ {step['duration']['text']}\n")

        except Exception as e:
            print(f"❌ Error: {e}")

def main():
    API_KEY = "$API_KEY"

    print("╔══════════════════════════════════════════╗")
    print("║   Google Maps Route Finder (Python)     ║")
    print("╚══════════════════════════════════════════╝")
    print()

    origin = input("📍 Origen: ")
    destination = input("🎯 Destino: ")

    print("\n🚗 Modos de viaje:")
    print("1. 🚗 Coche")
    print("2. 🚶 A pie")
    print("3. 🚲 Bicicleta")
    print("4. 🚇 Transporte público")
    choice = input("\nElige una opción (1-4): ")

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

# Script de ejecución para Python
cat > python/run.sh << 'EOF'
#!/bin/bash
echo "Instalando dependencias Python..."
pip3 install -r requirements.txt
echo "Ejecutando RouteFinder..."
python3 src/route_finder.py
EOF
chmod +x python/run.sh

# ============================================
# 4. JAVASCRIPT WEB (CORREGIDO - SIN ERRORES)
# ============================================
echo -e "${GREEN}Generando proyecto JavaScript Web...${NC}"

# HTML actualizado - VERSIÓN CORREGIDA (línea 745 solucionada)
cat > javascript/web/index.html << 'EOF'
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
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            background: white;
            border-radius: 24px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            flex-direction: column;
            height: 90vh;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px 24px;
        }

        .header h1 {
            font-size: 28px;
            margin-bottom: 8px;
        }

        .header p {
            opacity: 0.9;
            font-size: 14px;
        }

        .controls {
            padding: 20px 24px;
            background: #f8f9fa;
            border-bottom: 1px solid #e0e0e0;
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }

        .controls input {
            flex: 2;
            min-width: 200px;
            padding: 12px 16px;
            border: 2px solid #e0e0e0;
            border-radius: 12px;
            font-size: 14px;
            transition: all 0.3s;
        }

        .controls input:focus {
            outline: none;
            border-color: #667eea;
        }

        .controls select {
            padding: 12px 16px;
            border: 2px solid #e0e0e0;
            border-radius: 12px;
            font-size: 14px;
            background: white;
            cursor: pointer;
        }

        .controls button {
            padding: 12px 28px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 12px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }

        .controls button:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }

        #map {
            flex: 1;
            min-height: 400px;
        }

        .info {
            background: white;
            padding: 20px 24px;
            border-top: 1px solid #e0e0e0;
            max-height: 300px;
            overflow-y: auto;
            font-size: 14px;
        }

        .info h3 {
            color: #667eea;
            margin-bottom: 12px;
            font-size: 18px;
        }

        .info .route-summary {
            background: #f0f4ff;
            padding: 12px 16px;
            border-radius: 12px;
            margin-bottom: 16px;
        }

        .info .route-summary p {
            margin: 6px 0;
        }

        .instructions {
            margin-top: 12px;
        }

        .instructions ol {
            padding-left: 20px;
        }

        .instructions li {
            margin: 8px 0;
            padding: 8px;
            background: #f8f9fa;
            border-radius: 8px;
        }

        .error {
            background: #fee;
            color: #c00;
            padding: 12px;
            border-radius: 8px;
            border-left: 4px solid #c00;
        }

        @media (max-width: 768px) {
            .controls {
                flex-direction: column;
            }

            .controls input, .controls select, .controls button {
                width: 100%;
            }

            .header h1 {
                font-size: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🗺️ Google Maps Route Finder</h1>
            <p>Encuentra la mejor ruta entre dos puntos del mapa</p>
        </div>

        <div class="controls">
            <input type="text" id="origin" placeholder="📍 Origen (ej: Plaza Mayor, Madrid)" value="Plaza Mayor, Madrid">
            <input type="text" id="destination" placeholder="🎯 Destino (ej: Puerta del Sol, Madrid)" value="Puerta del Sol, Madrid">
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
            <h3>ℹ️ Información</h3>
            <p>Ingresa un origen y destino para calcular la ruta</p>
        </div>
    </div>

    <script>
        let map;
        let directionsService;
        let directionsRenderer;

        function initMap() {
            const defaultCenter = { lat: 40.416775, lng: -3.703790 };

            map = new google.maps.Map(document.getElementById("map"), {
                zoom: 12,
                center: defaultCenter,
                styles: [
                    {
                        featureType: "poi",
                        elementType: "labels",
                        stylers: [{ visibility: "off" }]
                    }
                ]
            });

            directionsService = new google.maps.DirectionsService();
            directionsRenderer = new google.maps.DirectionsRenderer({
                map: map,
                polylineOptions: {
                    strokeColor: "#667eea",
                    strokeWeight: 5,
                    strokeOpacity: 0.8
                }
            });
        }

        function calculateRoute() {
            const origin = document.getElementById("origin").value;
            const destination = document.getElementById("destination").value;
            const travelMode = document.getElementById("travelMode").value;

            if (!origin || !destination) {
                document.getElementById("info").innerHTML = '<h3>❌ Error</h3><div class="error">Por favor, ingresa origen y destino</div>';
                return;
            }

            document.getElementById("info").innerHTML = '<h3>🔄 Calculando ruta...</h3><p>Consultando Google Maps API...</p>';

            const request = {
                origin: origin,
                destination: destination,
                travelMode: google.maps.TravelMode[travelMode],
                provideRouteAlternatives: true,
                unitSystem: google.maps.UnitSystem.METRIC
            };

            directionsService.route(request, (result, status) => {
                if (status === "OK") {
                    directionsRenderer.setDirections(result);
                    const route = result.routes[0];
                    const leg = route.legs[0];

                    let instructionsHtml = '<div class="instructions"><ol>';
                    leg.steps.forEach((step) => {
                        instructionsHtml += '<li>' + step.instructions + '</li>';
                    });
                    instructionsHtml += '</ol></div>';

                    document.getElementById("info").innerHTML = `
                        <h3>✅ Ruta encontrada</h3>
                        <div class="route-summary">
                            <p><strong>📍 Desde:</strong> ${leg.start_address}</p>
                            <p><strong>🎯 Hasta:</strong> ${leg.end_address}</p>
                            <p><strong>📏 Distancia:</strong> ${leg.distance.text}</p>
                            <p><strong>⏱️ Duración:</strong> ${leg.duration.text}</p>
                        </div>
                        <h3>📝 Instrucciones paso a paso (${leg.steps.length} pasos):</h3>
                        ${instructionsHtml}
                    `;
                } else if (status === "REQUEST_DENIED") {
                    document.getElementById("info").innerHTML = `
                        <h3>❌ Error: La API Key no tiene permisos suficientes</h3>
                        <div class="error">
                            Soluciones:
                            <ul>
                                <li>Verifica que la API Key sea correcta</li>
                                <li>Habilita Directions API en Google Cloud Console</li>
                                <li>Habilita Maps JavaScript API en Google Cloud Console</li>
                                <li>Activa la facturación en tu proyecto</li>
                            </ul>
                        </div>
                    `;
                } else {
                    document.getElementById("info").innerHTML = '<h3>❌ Error</h3><div class="error">Error al calcular la ruta: ' + status + '</div>';
                }
            });
        }

        window.initMap = initMap;

        function handleApiError() {
            document.getElementById("info").innerHTML = `
                <h3>❌ Error de carga</h3>
                <div class="error">
                    No se pudo cargar Google Maps API.<br>
                    Posibles causas:
                    <ul>
                        <li>API Key inválida o no configurada</li>
                        <li>Maps JavaScript API no habilitada</li>
                        <li>Sin conexión a internet</li>
                    </ul>
                </div>
            `;
        }
    </script>
    <script src="https://maps.googleapis.com/maps/api/js?key=$API_KEY&callback=initMap&libraries=places&v=weekly"
            async defer onerror="handleApiError()"></script>
</body>
</html>
EOF

# ============================================
# 5. SCRIPT PRINCIPAL Y DOCUMENTACIÓN
# ============================================
echo -e "${GREEN}Generando documentación y scripts...${NC}"

# README principal actualizado
cat > README.md << 'EOF'
# Google Maps Route Finder 🌍

Proyecto completo para trazar rutas usando Google Maps API.

## 🚀 Cómo usar

### Web (Recomendado)
```bash
cd javascript/web
python3 -m http.server 8000
# Abrir http://localhost:8000
