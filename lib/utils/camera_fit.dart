/// Computes a center + zoom for a set of points, since the plugin's
/// `setCameraPositionAnimated`/`CameraPosition` only take a single target
/// and zoom — there's no native "fit camera to these bounds" call to use
/// instead when zooming to one or more just-added markers, a drawn route,
/// shapes, etc.
class CameraFit {
  CameraFit._();

  // Degrees-of-span -> zoom. Tuned by eye (no viewport-size input is
  // available to derive it from, unlike Google Maps' bounds-fit).
  static const List<(double span, double zoom)> _steps = <(double, double)>[
    (0.0008, 18.0),
    (0.0015, 17.0),
    (0.003, 16.0),
    (0.006, 15.0),
    (0.012, 14.0),
    (0.025, 13.0),
    (0.05, 12.0),
    (0.1, 11.0),
    (0.2, 10.0),
    (0.4, 9.0),
    (0.8, 8.0),
    (1.6, 7.0),
    (3.2, 6.0),
  ];

  static (double lat, double lng, double zoom) fit(
    List<(double lat, double lng)> points, {
    double minZoom = 3.0,
    double maxZoom = 18.0,
  }) {
    assert(points.isNotEmpty, 'CameraFit.fit requires at least one point');

    double minLat = points.first.$1;
    double maxLat = points.first.$1;
    double minLng = points.first.$2;
    double maxLng = points.first.$2;
    for (final (lat, lng) in points) {
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    final double centerLat = (minLat + maxLat) / 2;
    final double centerLng = (minLng + maxLng) / 2;
    final double latSpan = maxLat - minLat;
    final double lngSpan = maxLng - minLng;
    final double span = latSpan > lngSpan ? latSpan : lngSpan;

    double zoom = minZoom;
    for (final (threshold, z) in _steps) {
      if (span <= threshold) {
        zoom = z;
        break;
      }
    }

    return (centerLat, centerLng, zoom.clamp(minZoom, maxZoom));
  }
}
