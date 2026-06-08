package com.googlemaps;

import com.google.maps.DirectionsApi;
import com.google.maps.GeoApiContext;
import com.google.maps.errors.ApiException;
import com.google.maps.model.DirectionsResult;
import com.google.maps.model.TravelMode;
import com.google.maps.model.Unit;
import java.util.Scanner;

public class RouteFinder {
    private static final String API_KEY = "AIzaSyCGbLfwvbxGV_bWvbtkHQrV8hHM7flIwMo";

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.println("=== Google Maps Route Finder (Java) ===");
        System.out.println("=======================================\n");

        System.out.print("📍 Origen: ");
        String origin = scanner.nextLine();
        System.out.print("🎯 Destino: ");
        String destination = scanner.nextLine();

        // Menú de modo de viaje
        System.out.println("\n🚗 Modos de viaje:");
        System.out.println("1. 🚗 Coche");
        System.out.println("2. 🚶 A pie");
        System.out.println("3. 🚲 Bicicleta");
        System.out.println("4. 🚇 Transporte público");
        System.out.print("\nElige una opción (1-4): ");
        int modeChoice = scanner.nextInt();

        TravelMode mode;
        switch(modeChoice) {
            case 1: mode = TravelMode.DRIVING; break;
            case 2: mode = TravelMode.WALKING; break;
            case 3: mode = TravelMode.BICYCLING; break;
            case 4: mode = TravelMode.TRANSIT; break;
            default: mode = TravelMode.DRIVING;
        }

        findRoute(origin, destination, mode);
        scanner.close();
    }

    private static void findRoute(String origin, String destination, TravelMode mode) {
        System.out.println("\n🔄 Calculando ruta...\n");

        try {
            GeoApiContext context = new GeoApiContext.Builder()
                .apiKey(API_KEY)
                .build();

            DirectionsResult result = DirectionsApi.newRequest(context)
                .origin(origin)
                .destination(destination)
                .mode(mode)
                .units(Unit.METRIC)
                .await();

            if (result.routes != null && result.routes.length > 0) {
                var route = result.routes[0];
                var leg = route.legs[0];

                System.out.println("✅ ¡Ruta encontrada!\n");
                System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                System.out.println("📍 ORIGEN: " + leg.startAddress);
                System.out.println("🎯 DESTINO: " + leg.endAddress);
                System.out.println("📏 DISTANCIA: " + leg.distance.humanReadable);
                System.out.println("⏱️  DURACIÓN: " + leg.duration.humanReadable);
                System.out.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

                System.out.println("\n📝 INSTRUCCIONES PASO A PASO:\n");
                int stepNum = 1;
                for (var step : leg.steps) {
                    // Limpiar HTML de las instrucciones
                    String instruction = step.htmlInstructions
                        .replaceAll("<[^>]*>", "")
                        .replaceAll("&nbsp;", " ")
                        .replaceAll("&amp;", "&")
                        .trim();

                    System.out.println(stepNum++ + ". " + instruction);
                    System.out.println("   📏 " + step.distance.humanReadable + " | ⏱️ " + step.duration.humanReadable);
                    System.out.println();
                }
            } else {
                System.out.println("❌ No se encontraron rutas posibles");
                System.out.println("Verifica las direcciones o intenta con otro modo de transporte");
            }

            context.shutdown();
        } catch (ApiException e) {
            System.err.println("\n❌ Error de API: " + e.getMessage());
            System.err.println("Posibles causas:");
            System.err.println("  • API Key inválida o sin permisos");
            System.err.println("  • API de Directions no habilitada");
            System.err.println("  • Cuenta sin facturación activa");
        } catch (Exception e) {
            System.err.println("\n❌ Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
