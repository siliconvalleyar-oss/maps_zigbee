#!/bin/bash
echo "Instalando dependencias Python..."
pip3 install -r requirements.txt
echo "Ejecutando RouteFinder..."
python3 src/route_finder.py
