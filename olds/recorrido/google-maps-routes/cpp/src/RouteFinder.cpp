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
