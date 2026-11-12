import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';

import '../config/app_config.dart';
import '../utils/tplmaps_coords.dart';
import '../widgets/draggable_map_sheet.dart';

class PolylinesScreen extends StatefulWidget {
  const PolylinesScreen({super.key});

  @override
  State<PolylinesScreen> createState() => _PolylinesScreenState();
}

class _PolylinesScreenState extends State<PolylinesScreen> {
  TplMapsViewController? _controller;

  final TextEditingController _originController =
      TextEditingController(text: '24.8600,67.0000');
  final TextEditingController _destinationController =
      TextEditingController(text: '24.8400,67.0300');

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onCreated(TplMapsViewController controller) {
    _controller = controller;
    controller.setCameraPositionAnimated(
      AppConfig.defaultCameraLat,
      AppConfig.defaultCameraLng,
      AppConfig.defaultZoom,
    );
  }

  List<double>? _parseLatLng(String text) {
    final List<String> parts = text.split(',');
    if (parts.length != 2) return null;
    final double? lat = double.tryParse(parts[0].trim());
    final double? lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return <double>[lat, lng];
  }

  // Every controller call below is unawaited on purpose: the plugin's
  // native handler for its mutator methods never calls the method
  // channel's result.success/error on either platform (confirmed by
  // grepping the 2.0.7 native sources), so awaiting one when a camera move
  // needs to follow it hangs that camera move forever. See
  // routing_screen.dart's _createRoute for the full writeup.
  void _addStraightPolyline() {
    final List<double>? origin = _parseLatLng(_originController.text);
    final List<double>? destination = _parseLatLng(_destinationController.text);
    if (origin == null || destination == null) {
      _showMessage('Enter both points as "lat,lng".');
      return;
    }
    unawaited(_controller?.addPolyLine(
      origin[0],
      origin[1],
      destination[0],
      destination[1],
      5,
      '#FF0000',
    ));
    unawaited(_controller?.setCameraPositionAnimated(origin[0], origin[1], 11.0));
  }

  void _addMultiPointPolyline() {
    // addPolyLines needs points as "lng;lat" — see TplMapsCoords for why
    // (a confirmed lat/lng swap bug in the plugin's native addPolyLines
    // handler itself, same root cause as addPolygons needing lng;lat).
    final List<(double, double)> waypoints = <(double, double)>[
      (24.8500, 67.0100),
      (24.8550, 67.0150),
      (24.8500, 67.0200),
      (24.8550, 67.0250),
      (24.8500, 67.0300),
    ];
    unawaited(_controller?.addPolyLines(
      waypoints.map((p) => TplMapsCoords.polylinePoint(p.$1, p.$2)).toList(),
      5,
      '#2196F3',
    ));
    unawaited(_controller?.setCameraPositionAnimated(24.8525, 67.0200, 12.0));
  }

  void _removePolyline() {
    unawaited(_controller?.removePolyline());
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
      appBar: AppBar(title: const Text('Polylines')),
      body: DraggableMapSheet(
        map: TplMapsView(
          isShowBuildings: true,
          isZoomEnabled: true,
          showZoomControls: true,
          // See MapSettingsScreen: my-location crashes native onMapReady.
          myLocationButtonEnabled: false,
          setMyLocationEnabled: false,
          tplMapsViewCreatedCallback: _onCreated,
          tPlMapsViewPolyLineCallBack: (raw) => _showMessage('Polyline tapped: $raw'),
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _originController,
                  decoration: const InputDecoration(labelText: 'Origin (lat,lng)'),
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
                onPressed: _addStraightPolyline,
                child: const Text('Add straight polyline'),
              ),
              ElevatedButton(
                onPressed: _addMultiPointPolyline,
                child: const Text('Add multi-point polyline'),
              ),
              ElevatedButton(
                onPressed: _removePolyline,
                child: const Text('Remove polyline'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
