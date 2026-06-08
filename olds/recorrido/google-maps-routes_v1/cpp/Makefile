CXX = g++
CXXFLAGS = -std=c++11 -Wall
LDFLAGS = -lcurl -ljsoncpp

# Intentar diferentes rutas de include
ifeq ($(shell test -d /usr/include/jsoncpp && echo yes), yes)
    CXXFLAGS += -I/usr/include/jsoncpp
endif

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
