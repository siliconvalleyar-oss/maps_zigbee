#!/bin/bash
echo "Compilando proyecto Java..."
mvn clean compile
if [ $? -eq 0 ]; then
    echo "Ejecutando RouteFinder..."
    mvn exec:java
else
    echo "Error en la compilación"
fi
