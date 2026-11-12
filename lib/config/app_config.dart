class AppConfig {
  AppConfig._();

  // Replace with your own TPL Maps API key before running the app — must
  // match the key set in android/app/src/main/AndroidManifest.xml under
  // com.tplmaps.android.sdk.API_KEY.
  static const String apiKey = "YOUR_TPL_MAPS_API_KEY";

  static const double defaultBiasLat = 24.8607;
  static const double defaultBiasLng = 67.0011;

  // The plugin's native map (at least on this account/key) settles on a
  // Karachi/Landhi-area view regardless of setCameraPositionAnimated calls
  // made right after creation — confirmed by testing (camera briefly flies
  // to a requested position, then reverts). Demo content below is anchored
  // near this region so it's visible without depending on that call.
  static const double defaultCameraLat = defaultBiasLat;
  static const double defaultCameraLng = defaultBiasLng;
  static const double defaultZoom = 14.0;

  static const String reverseGeocodeUrl =
      "https://api1.tplmaps.com:8888/search/rgeocodebulk";
}
