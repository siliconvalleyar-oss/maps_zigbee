import com.google.maps.DirectionsApi;
import com.google.maps.GeoApiContext;
import com.google.maps.model.DirectionsResult;
import com.google.maps.model.TravelMode;
import java.util.Scanner;

public class RouteFinder {
    private static final String API_KEY = "AIzaSyCGbLfwvbxGV_bWvbtkHQrV8hHM7flIwMo";

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.println("=== Google Maps Route Finder ===");
        System.out.print("Origen: ");
        String origin = scanner.nextLine();
        System.out.print("Destino: ");
        String destination = scanner.nextLine();

        // Menú de modo de viaje
        System.out.println("\nModos de viaje:");
        System.out.println("1. Coche");
        System.out.println("2. A pie");
        System.out.println("3. Bicicleta");
        System.out.println("4. Transporte público");
        System.out.print("Elige una opción (1-4): ");
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
    }

    private static void findRoute(String origin, String destination, TravelMode mode) {
        try {
            GeoApiContext context = new GeoApiContext.Builder()
                .apiKey(API_KEY)
                .build();

            DirectionsResult result = DirectionsApi.newRequest(context)
                .origin(origin)
                .destination(destination)
                .mode(mode)
                .await();

            if (result.routes.length > 0) {
                var route = result.routes[0];
                var leg = route.legs[0];

                System.out.println("\n✅ Ruta encontrada!\n");
                System.out.println("📍 Origen: " + leg.startAddress);
                System.out.println("🎯 Destino: " + leg.endAddress);
                System.out.println("📏 Distancia: " + leg.distance.humanReadable);
                System.out.println("⏱️  Duración: " + leg.duration.humanReadable);
                System.out.println("\n📝 Instrucciones:");

                int stepNum = 1;
                for (var step : leg.steps) {
                    String instruction = step.htmlInstructions.replaceAll("<[^>]*>", "");
                    System.out.println(stepNum++ + ". " + instruction);
                    System.out.println("   " + step.distance.humanReadable + " (" + step.duration.humanReadable + ")\n");
                }
            } else {
                System.out.println("❌ No se encontraron rutas");
            }

            context.shutdown();
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
        }
    }
}
