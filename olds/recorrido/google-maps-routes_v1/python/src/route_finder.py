#!/usr/bin/env python3
import googlemaps
import sys
from datetime import datetime

class GoogleMapsRouteFinder:
    def __init__(self, api_key):
        self.gmaps = googlemaps.Client(key=api_key)

    def find_route(self, origin, destination, mode="driving"):
        try:
            # Obtener direcciones
            directions = self.gmaps.directions(
                origin,
                destination,
                mode=mode,
                departure_time=datetime.now()
            )

            if not directions:
                print("❌ No se encontraron rutas")
                return

            route = directions[0]
            leg = route['legs'][0]

            print("\n✅ Ruta encontrada!\n")
            print(f"📍 Origen: {leg['start_address']}")
            print(f"🎯 Destino: {leg['end_address']}")
            print(f"📏 Distancia: {leg['distance']['text']}")
            print(f"⏱️  Duración: {leg['duration']['text']}")

            print("\n📝 Instrucciones:")
            for i, step in enumerate(leg['steps'], 1):
                instruction = step['html_instructions'].replace('<b>', '').replace('</b>', '')
                print(f"{i}. {instruction}")
                print(f"   {step['distance']['text']} ({step['duration']['text']})\n")

        except Exception as e:
            print(f"❌ Error: {e}")

    def get_route_polyline(self, origin, destination, mode="driving"):
        """Obtiene el polyline de la ruta para dibujar"""
        directions = self.gmaps.directions(origin, destination, mode=mode)
        if directions:
            return directions[0]['overview_polyline']['points']
        return None

def main():
    API_KEY = "AIzaSyCGbLfwvbxGV_bWvbtkHQrV8hHM7flIwMo"

    print("=== Google Maps Route Finder (Python) ===")
    origin = input("Origen: ")
    destination = input("Destino: ")

    print("\nModos de viaje:")
    print("1. Coche")
    print("2. A pie")
    print("3. Bicicleta")
    print("4. Transporte público")
    choice = input("Elige una opción (1-4): ")

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
