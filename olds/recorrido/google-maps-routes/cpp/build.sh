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
