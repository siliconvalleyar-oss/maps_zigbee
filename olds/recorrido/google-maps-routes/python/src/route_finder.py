#!/usr/bin/env python3
import googlemaps
from datetime import datetime
import re

class GoogleMapsRouteFinder:
    def __init__(self, api_key):
        self.gmaps = googlemaps.Client(key=api_key)

    def find_route(self, origin, destination, mode="driving"):
        try:
            print(f"\n🔄 Calculando ruta...\n")

            directions = self.gmaps.directions(
                origin,
                destination,
                mode=mode,
                departure_time=datetime.now(),
                language='es'
            )

            if not directions:
                print("❌ No se encontraron rutas")
                return

            route = directions[0]
            leg = route['legs'][0]

            print("✅ ¡Ruta encontrada!\n")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print(f"📍 ORIGEN: {leg['start_address']}")
            print(f"🎯 DESTINO: {leg['end_address']}")
            print(f"📏 DISTANCIA: {leg['distance']['text']}")
            print(f"⏱️  DURACIÓN: {leg['duration']['text']}")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            print(f"\n📝 INSTRUCCIONES PASO A PASO:\n")
            for i, step in enumerate(leg['steps'], 1):
                instruction = step['html_instructions']
                instruction = re.sub(r'<[^>]+>', '', instruction)
                instruction = instruction.replace('&nbsp;', ' ').replace('&amp;', '&')

                print(f"{i}. {instruction}")
                print(f"   📏 {step['distance']['text']} | ⏱️ {step['duration']['text']}\n")

        except Exception as e:
            print(f"❌ Error: {e}")

def main():
    API_KEY = "AIzaSyCGbLfwvbxGV_bWvbtkHQrV8hHM7flIwMo"

    print("╔══════════════════════════════════════════╗")
    print("║   Google Maps Route Finder (Python)     ║")
    print("╚══════════════════════════════════════════╝")
    print()

    origin = input("📍 Origen: ")
    destination = input("🎯 Destino: ")

    print("\n🚗 Modos de viaje:")
    print("1. 🚗 Coche")
    print("2. 🚶 A pie")
    print("3. 🚲 Bicicleta")
    print("4. 🚇 Transporte público")
    choice = input("\nElige una opción (1-4): ")

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
