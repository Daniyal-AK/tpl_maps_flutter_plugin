/// Parses the raw string callbacks emitted by the native TPL Maps plugin
/// (marker tap, long-click, polygon/circle click, camera changed), which
/// arrive as a stringified HashMap rather than a typed payload.
class NativeLatLng {
  const NativeLatLng(this.latitude, this.longitude);

  final double? latitude;
  final double? longitude;

  bool get isValid => latitude != null && longitude != null;

  @override
  String toString() => '($latitude, $longitude)';
}

class NativeCallbackParser {
  NativeCallbackParser._();

  /// Extracts a `LatLng:` pair out of a raw native callback string such as
  /// `{...LatLng: 33.70, 73.06}`. Returns null (never throws) if the string
  /// doesn't contain a parseable pair.
  static NativeLatLng? extractLatLng(String raw) {
    final int idx = raw.indexOf('LatLng:');
    if (idx == -1) return null;

    final String sub = raw.substring(idx + 'LatLng:'.length).trim();
    final List<String> parts = sub.split(',');
    if (parts.length < 2) return null;

    final double? lat = double.tryParse(parts[0].trim());
    final String lngRaw = parts[1].split('}').first.trim();
    final double? lng = double.tryParse(lngRaw);

    if (lat == null || lng == null) return null;
    return NativeLatLng(lat, lng);
  }

  /// The plugin packs a marker's id into its title as "id:title" internally.
  /// This splits that back apart for display. A title containing ':' will
  /// still mis-split on the first colon — a plugin-side quirk, not fixed here.
  static (String id, String title) splitMarkerIdAndTitle(String packed) {
    final int i = packed.indexOf(':');
    if (i == -1) return ('', packed);
    return (packed.substring(0, i), packed.substring(i + 1));
  }
}
