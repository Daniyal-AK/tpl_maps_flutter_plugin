import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Direct replacement for `TplMapsViewController.createRoute`.
///
/// Two separate bugs made the plugin's own `createRoute` unusable:
///
/// 1. Its `destinationLatLng` parameter has no declared type and gets
///    interpolated straight into the request URL
///    (`tplmapsflutterplugin/lib/TplMapsView.dart`). Called the way the
///    plugin's own widget code calls it — with a `List<String>` — Dart's
///    `List.toString()` puts literal `[` `]` into the query string, and
///    neither that method nor this one set an HTTP timeout, so the backend
///    just hangs on the unparseable request instead of erroring. That's
///    what made "Create route" spin forever.
/// 2. Even fixing #1, the plugin's own delimiter choice is wrong: it joins
///    every coordinate with `;` — `lat;lng;lat;lng` — but the backend
///    (confirmed by calling `GET /route` directly with curl) expects
///    `lat,lng;lat,lng`: a comma *within* a point, semicolon *between*
///    points. The `;`-only form returns HTTP 200 with `{"error":"No Routes
///    Found."}` for literally any input, including points `/route/optimal`
///    (used by "Create optimal route", built the request differently and
///    correctly) resolves a real route for. That's what made "Create
///    route" fail outright even after fix #1 stopped it from hanging.
///
/// This builds the query string the way the backend actually expects and
/// adds a timeout so genuine failures (e.g. truly unroutable points) surface
/// as a message instead of hanging.
class RouteResult {
  const RouteResult({required this.distance, required this.time, required this.points});

  final String distance;
  final String time;
  final List<(double lat, double lng)> points;
}

class TplMapsRoutingException implements Exception {
  const TplMapsRoutingException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TplMapsRouting {
  TplMapsRouting._();

  static Future<RouteResult> fetchRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    required String apiKey,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final Uri url = Uri.parse(
      'https://api1.tplmaps.com:8888/route'
      '?points=$originLat,$originLng;$destinationLat,$destinationLng'
      '&heading=90&profile=car&pointsencoded=false&reroute=false&apikey=$apiKey',
    );

    http.Response response;
    try {
      response = await http
          .get(url, headers: const <String, String>{'Content-Type': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw const TplMapsRoutingException('Route request timed out.');
    }

    if (response.statusCode != 200) {
      throw TplMapsRoutingException('Route request failed: HTTP ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['error'] != null) {
      throw TplMapsRoutingException(decoded['error'].toString());
    }

    final dynamic p = decoded is Map ? decoded['p'] : null;
    if (p is! List || p.isEmpty || p.first is! Map) {
      throw const TplMapsRoutingException('Route response had no route data.');
    }

    final Map<dynamic, dynamic> first = p.first as Map<dynamic, dynamic>;
    final String distance = first['d']?.toString() ?? '';
    final String time = first['t']?.toString() ?? '';

    final List<(double, double)> points = <(double, double)>[];
    final dynamic innerRoute = first['p'];
    if (innerRoute is List) {
      for (final dynamic coord in innerRoute) {
        if (coord is List && coord.length == 2 && coord[0] is num && coord[1] is num) {
          // The backend returns [lng, lat] per the plugin's own parser.
          points.add(((coord[1] as num).toDouble(), (coord[0] as num).toDouble()));
        }
      }
    }

    if (points.isEmpty) {
      throw const TplMapsRoutingException('Route response had no coordinates.');
    }

    return RouteResult(distance: distance, time: time, points: points);
  }
}
