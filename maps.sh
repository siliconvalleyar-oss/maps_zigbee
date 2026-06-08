# Prueba si la API ya está activa
API_KEY="AIzaSyCGbLfwvbxGV_bWvbtkHQrV8hHM7flIwMo"  # Reemplaza con tu clave

curl -X POST -d '{
  "origin": {"address": "Gualeguaychú, Entre Ríos"},
  "destination": {"address": "Landa 688, Gualeguaychú"},
  "travelMode": "DRIVE"
}' \
-H 'Content-Type: application/json' \
-H "X-Goog-Api-Key: $API_KEY" \
-H 'X-Goog-FieldMask: routes.duration,routes.distanceMeters' \
'https://routes.googleapis.com/directions/v2:computeRoutes'

