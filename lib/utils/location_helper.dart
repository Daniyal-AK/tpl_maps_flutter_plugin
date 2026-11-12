import 'package:geolocator/geolocator.dart';

/// Reads the device's own GPS position via `geolocator`.
///
/// The TPL Maps plugin has no Dart API that returns the user's current
/// coordinates — `setMyLocationEnabled`/`myLocationButtonEnabled` only
/// toggle the native blue-dot/FAB (and the FAB crashes on this plugin
/// version, see MapSettingsScreen), there's no "locationChanged" callback.
/// So "my location" features in this demo (locate-me FAB, directions from
/// current position) resolve the position independently and feed it into
/// the map via `setCameraPositionAnimated`/`createRoute`.
class LocationHelper {
  LocationHelper._();

  static Future<Position> getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationHelperException('Location services are turned off.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationHelperException('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationHelperException(
        'Location permission permanently denied — enable it from app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}

class LocationHelperException implements Exception {
  const LocationHelperException(this.message);
  final String message;

  @override
  String toString() => message;
}
