import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';

import '../config/app_config.dart';
import '../utils/camera_fit.dart';
import '../utils/pin_marker_icon.dart';
import '../utils/platform_utils.dart';
import '../utils/tplmaps_coords.dart';
import '../utils/tplmaps_routing.dart';
import '../widgets/draggable_map_sheet.dart';

class RoutingScreen extends StatefulWidget {
  const RoutingScreen({super.key});

  @override
  State<RoutingScreen> createState() => _RoutingScreenState();
}

// TPL-green: a deep forest green that reads clearly against the map's
// yellow roads and pink building fills.
const Color _kRouteGreen = Color(0xFF0E8A3E);
const Color _kDestinationOrange = Color(0xFFF57C00);

class _RoutingScreenState extends State<RoutingScreen> {
  TplMapsViewController? _controller;

  final TextEditingController _originController =
      TextEditingController(text: '24.820984,67.103971');
  final TextEditingController _destinationController =
      TextEditingController(text: '24.820609,67.125562');

  bool _loading = false;
  String? _distance;
  String? _time;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onCreated(TplMapsViewController controller) {
    _controller = controller;
    controller.setCameraPositionAnimated(24.8300, 67.1100, 12.0);
  }

  List<double>? _parseLatLng(String text) {
    final List<String> parts = text.split(',');
    if (parts.length != 2) return null;
    final double? lat = double.tryParse(parts[0].trim());
    final double? lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return <double>[lat, lng];
  }

  Future<void> _createRoute() async {
    final List<double>? origin = _parseLatLng(_originController.text);
    final List<double>? destination = _parseLatLng(_destinationController.text);
    if (origin == null || destination == null) {
      _showMessage('Enter both points as "lat,lng".');
      return;
    }

    setState(() {
      _loading = true;
      _distance = null;
      _time = null;
    });
    try {
      // Not using TplMapsViewController.createRoute here: its untyped
      // destinationLatLng param gets interpolated straight into the request
      // URL, so passing it the List<String> the plugin's own widget code
      // uses puts literal "[" "]" into the query string and the backend
      // request then just hangs (no timeout either side) — this is why
      // "Create route" used to spin forever. See TplMapsRouting for detail.
      final RouteResult route = await TplMapsRouting.fetchRoute(
        originLat: origin[0],
        originLng: origin[1],
        destinationLat: destination[0],
        destinationLng: destination[1],
        apiKey: AppConfig.apiKey,
      );
      // Not awaited: the plugin's native handler for every one of these
      // mutator methods (addPolyLines, setCameraPositionAnimated, ...)
      // never calls the method channel's result.success/error on either
      // platform (confirmed by grepping the 2.0.7 native sources — zero
      // result.success calls in Android's TPLMapView.onMethodCall, and iOS
      // only resolves the unmatched-method fallback). So the Dart Future
      // these return NEVER completes; awaiting one when something needs to
      // happen afterward hangs that code forever. That's what made "Create
      // route" spin forever even after the HTTP call itself started
      // succeeding. Fire-and-forget is the only option — the platform
      // channel still dispatches these to native in call order, so visually
      // the polyline is drawn and the camera moves right after, just
      // without a way to await either from Dart.
      unawaited(_controller?.removePolyline());
      // addPolyLines needs points pre-swapped to "lng;lat" — see
      // TplMapsCoords for why (a confirmed lat/lng swap bug in the
      // plugin's native addPolyLines handler itself).
      unawaited(_controller?.addPolyLines(
        route.points.map((p) => TplMapsCoords.polylinePoint(p.$1, p.$2)).toList(),
        3,
        '#0E8A3E',
      ));

      unawaited(_controller?.removeAllMarker());
      if (isTplMapsAndroid) {
        // addCustomMarkerBase64 has no native handler on iOS (see
        // platform_utils.dart) — colored pins are Android-only; fall back
        // to the plain default marker below on other platforms.
        //
        // Generating the pin bitmaps is local canvas work, not a native
        // call — safe to await. Placing them is not (see the comment above
        // this try block).
        final String originIcon = await generatePinMarkerDataUri(color: _kRouteGreen);
        final String destinationIcon = await generatePinMarkerDataUri(color: _kDestinationOrange);
        unawaited(_controller?.addCustomMarkerBase64(
          'route-origin',
          origin[0],
          origin[1],
          originIcon,
          64,
          64,
          'Start',
          '',
        ));
        unawaited(_controller?.addCustomMarkerBase64(
          'route-destination',
          destination[0],
          destination[1],
          destinationIcon,
          64,
          64,
          'Destination',
          '',
        ));
      } else {
        unawaited(_controller?.addMarker(origin[0], origin[1]));
        unawaited(_controller?.addMarker(destination[0], destination[1]));
      }

      final (double lat, double lng, double zoom) = CameraFit.fit(route.points);
      unawaited(_controller?.setCameraPositionAnimated(lat, lng, zoom));
      setState(() {
        _distance = route.distance;
        _time = route.time;
      });
    } catch (e) {
      _showMessage('Create route failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createOptimalRoute() async {
    const String currentLatLng = '24.820984;67.103971';
    const List<String> destinations = <String>[
      '24.820609;67.125562',
      '24.838784;67.119716',
      '24.834305;67.098644',
    ];
    setState(() => _loading = true);
    try {
      // createRouteOptimal is typed correctly (unlike createRoute above) but
      // still has no timeout of its own — add one defensively.
      // createRouteOptimal itself resolves fine — its own HTTP call does
      // the drawing by firing addPolyLines without awaiting it internally,
      // so it never touches the method channel's broken result callback.
      // The camera move below is a separate invokeMethod call though, so
      // it gets the same unawaited treatment as in _createRoute above.
      await _controller
          ?.createRouteOptimal(currentLatLng, destinations, '#9C27B0', 5, AppConfig.apiKey)
          .timeout(const Duration(seconds: 20));
      unawaited(_controller?.setCameraPositionAnimated(24.8300, 67.1100, 12.0));
      _showMessage('Optimal route drawn.');
    } catch (e) {
      _showMessage('createRouteOptimal failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startNavigation() async {
    // Checked the plugin's native sources (2.0.7): on Android,
    // TPLMapView.startNavigation() is an empty stub (the actual
    // Intent/NavigationActivity launch is commented out) — it returns
    // successfully but draws nothing. On iOS it does call the real SDK,
    // map.drawRoute(...), with navigation waypoints. So this is the
    // opposite of Android-only: it only does anything on iOS.
    if (isTplMapsAndroid) {
      _showMessage(
        "startNavigation is a no-op on Android in plugin 2.0.7 — the "
        'native implementation is commented out. Use "Create route" instead.',
      );
      return;
    }
    final List<double>? origin = _parseLatLng(_originController.text);
    final List<double>? destination = _parseLatLng(_destinationController.text);
    if (origin == null || destination == null) {
      _showMessage('Enter both points as "lat,lng".');
      return;
    }
    unawaited(_controller?.startNavigation(origin[0], origin[1], destination[0], destination[1]));
    _showMessage('startNavigation called (fire-and-forget — the plugin never confirms completion).');
  }

  Future<void> _clearRoute() async {
    unawaited(_controller?.removePolyline());
    unawaited(_controller?.removeAllMarker());
    setState(() {
      _distance = null;
      _time = null;
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routing')),
      body: DraggableMapSheet(
        map: TplMapsView(
          isShowBuildings: true,
          isZoomEnabled: true,
          showZoomControls: true,
          // See MapSettingsScreen: my-location crashes native onMapReady.
          myLocationButtonEnabled: false,
          setMyLocationEnabled: false,
          tplMapsViewCreatedCallback: _onCreated,
        ),
        children: [
          if (_distance != null || _time != null)
            Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('Distance: ${_distance ?? '-'}   Time: ${_time ?? '-'}'),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _originController,
                  decoration: const InputDecoration(labelText: 'Current (lat,lng)'),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  decoration: const InputDecoration(labelText: 'Destination (lat,lng)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _loading ? null : _createRoute,
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create route'),
              ),
              ElevatedButton(
                onPressed: _loading ? null : _createOptimalRoute,
                child: const Text('Create optimal route (3 stops)'),
              ),
              OutlinedButton(
                onPressed: _startNavigation,
                child: const Text('Start navigation (experimental)'),
              ),
              ElevatedButton(
                onPressed: _clearRoute,
                child: const Text('Clear route'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
