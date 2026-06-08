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
