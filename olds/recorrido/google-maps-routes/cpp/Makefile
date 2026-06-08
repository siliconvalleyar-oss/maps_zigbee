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
