#!/bin/bash
echo "=== Menú Routes API Nueva ==="
echo "1) Python (Routes API v2)"
echo "2) Java (Routes API v2)"
echo "3) Web (Maps JS API)"
read -p "Opción: " opt

case $opt in
    1) cd python && python3 src/route_finder.py ;;
    2) cd java && mvn compile exec:java -Dexec.mainClass=com.routes.RouteFinder ;;
    3) cd web && python3 -m http.server 8000 ;;
    *) echo "Opción inválida" ;;
esac
