#include <iostream>
#include <string>
#include <curl/curl.h>
#include <json/json.h>
#include <sstream>

#define API_KEY "AIzaSyCGbLfwvbxGV_bWvbtkHQrV8hHM7flIwMo"
// Callback para escribir la respuesta de CURL
size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* userp) {
    size_t totalSize = size * nmemb;
    userp->append((char*)contents, totalSize);
    return totalSize;
}

class GoogleMapsClient {
private:
    std::string apiKey =API_KEY;
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
    std::string apiKey = API_KEY;
    
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
