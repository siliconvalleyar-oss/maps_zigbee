package com.routes;

import okhttp3.*;
import com.google.gson.*;
import java.io.IOException;
import java.util.Scanner;

public class RouteFinder {
    private static final String API_KEY = "AIzaSyCGbLfwvbxGV_bWvbtkHQrV8hHM7flIwMo";
    private static final String ROUTES_URL = "https://routes.googleapis.com/directions/v2:computeRoutes";
    private static final OkHttpClient client = new OkHttpClient();
    private static final Gson gson = new Gson();

    public static void main(String[] args) throws IOException {
        Scanner scanner = new Scanner(System.in);
        System.out.println("=== Routes API Finder (Java) ===");
        System.out.print("Origen: ");
        String origin = scanner.nextLine();
        System.out.print("Destino: ");
        String destination = scanner.nextLine();
        System.out.print("Modo (DRIVE/WALK/BICYCLE): ");
        String mode = scanner.nextLine().toUpperCase();

        findRoute(origin, destination, mode);
    }

    private static void findRoute(String origin, String destination, String mode) throws IOException {
        JsonObject body = new JsonObject();
        body.add("origin", createAddress(origin));
        body.add("destination", createAddress(destination));
        body.addProperty("travelMode", mode);
        body.addProperty("routingPreference", "TRAFFIC_AWARE");
        body.addProperty("languageCode", "es-ES");
        body.addProperty("units", "METRIC");

        Request request = new Request.Builder()
            .url(ROUTES_URL)
            .post(RequestBody.create(MediaType.parse("application/json"), gson.toJson(body)))
            .addHeader("Content-Type", "application/json")
            .addHeader("X-Goog-Api-Key", API_KEY)
            .addHeader("X-Goog-FieldMask", "routes.distanceMeters,routes.duration,routes.legs.steps")
            .build();

        try (Response response = client.newCall(request).execute()) {
            if (response.isSuccessful()) {
                JsonObject json = gson.fromJson(response.body().string(), JsonObject.class);
                JsonObject route = json.getAsJsonArray("routes").get(0).getAsJsonObject();
                double km = route.get("distanceMeters").getAsDouble() / 1000;
                int seconds = route.get("duration").getAsString().replace("s", "").isEmpty() ? 0 :
                              Integer.parseInt(route.get("duration").getAsString().replace("s", ""));
                System.out.printf("\n✅ Ruta encontrada!\n📏 %.1f km\n⏱️ %d min\n", km, seconds/60);
            } else {
                System.err.println("Error: " + response.body().string());
            }
        }
    }

    private static JsonObject createAddress(String address) {
        JsonObject obj = new JsonObject();
        obj.addProperty("address", address);
        return obj;
    }
}
