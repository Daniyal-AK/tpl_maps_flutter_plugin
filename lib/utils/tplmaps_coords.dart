/// Point-string formatting for `TplMapsViewController.addPolyLines`.
///
/// Decompiled the plugin's bundled TPL Maps SDK (`com.tplmaps3d.LngLat`,
/// `library-2.2.2-sources.jar`): its constructor is `LngLat(lng, lat)`.
/// The plugin's native `addPolyLines` handler (Android
/// `TPLMapView.kt:addPolyLines`) parses each `"a;b"` string as `lat = a`,
/// `lng = b`, then builds `LngLat(lat, lng)` — passing them in the wrong
/// order into a constructor that expects `(lng, lat)`. So every point ends
/// up plotted with latitude and longitude swapped, putting the whole
/// polyline far from the visible map (e.g. Karachi's ~24.8,67.1 becomes
/// ~67.1,24.8 — the Russia/Kazakhstan border) — it doesn't error, it's just
/// invisible wherever you're actually looking.
///
/// Sending points pre-swapped, as `"lng;lat"`, cancels the bug out: native
/// reads `lat = lng_value`, `lng = lat_value`, then
/// `LngLat(lng_value, lat_value)` — correct. This is also why
/// `addPolygons` (same parsing bug, confirmed in the same file) already
/// needed "lng;lat" input in this app (see ShapesScreen) — same root cause,
/// independently rediscovered there. `addMarker`, `addCircle`, and the
/// singular `addPolyLine` all build `LngLat` in the correct order already
/// and must NOT be swapped.
class TplMapsCoords {
  TplMapsCoords._();

  static String polylinePoint(double lat, double lng) => '$lng;$lat';
}
