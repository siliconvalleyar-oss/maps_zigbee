#!/usr/bin/env python3
import requests
import json
import time

API_KEY = "AIzaSyCGbLfwvbxGV_bWvbtkHQrV8hHM7flIwMo"
ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes"

def find_route(origin, destination, mode="DRIVE"):
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": API_KEY,
        "X-Goog-FieldMask": "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs.steps"
    }

    body = {
        "origin": {"address": origin},
        "destination": {"address": destination},
        "travelMode": mode,
        "routingPreference": "TRAFFIC_AWARE",
        "computeAlternativeRoutes": False,
        "languageCode": "es-ES",
        "units": "METRIC"
    }

    print(f"🔄 Calculando ruta usando Routes API...")
    response = requests.post(ROUTES_URL, headers=headers, json=body)

    if response.status_code == 200:
        data = response.json()
        if "routes" in data and data["routes"]:
            route = data["routes"][0]
            duration = int(route["duration"].replace("s", ""))
            hours = duration // 3600
            minutes = (duration % 3600) // 60
            duracion_str = f"{hours}h {minutes}m" if hours > 0 else f"{minutes}m"

            print(f"\n✅ Ruta encontrada!\n")
            print(f"📏 Distancia: {route['distanceMeters'] / 1000:.1f} km")
            print(f"⏱️ Duración: {duracion_str}")
            print(f"📝 Instrucciones (simplificadas):")

            for i, leg in enumerate(route.get("legs", [])):
                for j, step in enumerate(leg.get("steps", []), 1):
                    print(f"  {j}. {step.get('navigationInstruction', {}).get('instructions', 'Sigue recto')}")
        else:
            print("❌ No se encontraron rutas")
    else:
        print(f"❌ Error API: {response.status_code} - {response.text}")

if __name__ == "__main__":
    print("=== Routes API Finder (Python) ===")
    orig = input("Origen: ")
    dest = input("Destino: ")
    print("\nModos: 1=DRIVE, 2=WALK, 3=BIKE")
    mode_choice = input("Elige: ")
    mode = {"1": "DRIVE", "2": "WALK", "3": "BICYCLE"}.get(mode_choice, "DRIVE")
    find_route(orig, dest, mode)
