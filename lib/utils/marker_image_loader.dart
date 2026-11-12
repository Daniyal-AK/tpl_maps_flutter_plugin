import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

/// Loads an image asset and encodes it as a base64 data URI, for use with
/// the plugin's addCustomMarkerBase64 / addCustomMarkerBase64WithInfoWindow
/// methods, instead of hardcoding a base64 blob in source.
Future<String> loadBase64MarkerFromAsset(String assetPath) async {
  final ByteData data = await rootBundle.load(assetPath);
  final String base64Image = base64Encode(data.buffer.asUint8List());
  final String mimeType = assetPath.endsWith('.png') ? 'image/png' : 'image/jpeg';
  return 'data:$mimeType;base64,$base64Image';
}
