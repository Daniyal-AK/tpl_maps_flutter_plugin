import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';

import '../config/app_config.dart';
import '../utils/marker_image_loader.dart';
import '../utils/native_callback_parser.dart';
import '../utils/platform_utils.dart';
import '../widgets/draggable_map_sheet.dart';

class MarkersScreen extends StatefulWidget {
  const MarkersScreen({super.key});

  @override
  State<MarkersScreen> createState() => _MarkersScreenState();
}

class _MarkersScreenState extends State<MarkersScreen> {
  TplMapsViewController? _controller;
  bool _draggable = false;
  int _markerCount = 0;

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

  void _onMarkerTap(String raw) {
    final NativeLatLng? latLng = NativeCallbackParser.extractLatLng(raw);
    _showMessage(latLng != null && latLng.isValid
        ? 'Marker tapped at $latLng'
        : 'Marker tapped: $raw');
  }

  // Spreads successive demo markers a little so repeated taps don't stack
  // identical pins exactly on top of each other.
  (double, double) _nextDemoLatLng() {
    final double offset = (_markerCount % 5) * 0.01;
    _markerCount++;
    return (AppConfig.defaultCameraLat + offset, AppConfig.defaultCameraLng + offset);
  }

  // Not awaited anywhere below: the plugin's native handler for every one
  // of these mutator methods (addMarker, addCircle, addPolyLines, ...)
  // never calls the method channel's result.success/error on either
  // platform (confirmed by grepping the 2.0.7 native sources — zero
  // result.success calls in Android's TPLMapView.onMethodCall, and iOS
  // only resolves the unmatched-method fallback). Awaiting one of these
  // when something needs to run afterward — like the zoom call that's
  // supposed to follow each add-marker button here — hangs forever and the
  // zoom never happens. Firing without awaiting is the only option; the
  // platform channel still dispatches calls to native in the order Dart
  // sends them, so the marker still visually lands before the camera moves.
  void _zoomTo(double lat, double lng) {
    unawaited(_controller?.setCameraPositionAnimated(lat, lng, 17.0));
  }

  Future<void> _addPlainMarker() async {
    final (lat, lng) = _nextDemoLatLng();
    unawaited(_controller?.addMarker(lat, lng));
    _zoomTo(lat, lng);
  }

  Future<void> _addResizedMarker() async {
    final (lat, lng) = _nextDemoLatLng();
    unawaited(_controller?.addMarkerCustomMarker(lat, lng, 80, 80));
    _zoomTo(lat, lng);
  }

  Future<void> _addCustomImageMarker() async {
    if (!isTplMapsAndroid) {
      _showMessage('addCustomMarkerBase64 is Android-only.');
      return;
    }
    try {
      final String base64Image = await loadBase64MarkerFromAsset('assets/droppin.jpg');
      final (lat, lng) = _nextDemoLatLng();
      unawaited(_controller?.addCustomMarkerBase64(
        'marker-$_markerCount',
        lat,
        lng,
        base64Image,
        70,
        70,
        'Custom marker',
        'Loaded from assets/droppin.jpg',
      ));
      _zoomTo(lat, lng);
    } catch (e) {
      _showMessage('addCustomMarkerBase64 failed: $e');
    }
  }

  Future<void> _addCustomImageMarkerWithInfoWindow() async {
    try {
      final String base64Image = await loadBase64MarkerFromAsset('assets/droppin.jpg');
      final (lat, lng) = _nextDemoLatLng();
      unawaited(_controller?.addCustomMarkerBase64WithInfoWindow(
        'marker-$_markerCount',
        lat,
        lng,
        base64Image,
        70,
        70,
        'Custom marker + info window',
        'Tap to see this info window.',
      ));
      _zoomTo(lat, lng);
    } catch (e) {
      _showMessage('addCustomMarkerBase64WithInfoWindow failed: $e');
    }
  }

  Future<void> _removeAllMarkers() async {
    unawaited(_controller?.removeAllMarker());
    setState(() => _markerCount = 0);
    unawaited(_controller?.setCameraPositionAnimated(
      AppConfig.defaultCameraLat,
      AppConfig.defaultCameraLng,
      AppConfig.defaultZoom,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Markers')),
      body: DraggableMapSheet(
        map: TplMapsView(
          isShowBuildings: true,
          isZoomEnabled: true,
          showZoomControls: true,
          longClickMarkerEnable: true,
          myLocationButtonEnabled: false,
          setMyLocationEnabled: false,
          tplMapsViewCreatedCallback: _onCreated,
          tPlMapsViewMarkerCallBack: _onMarkerTap,
        ),
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _addPlainMarker,
                child: const Text('Plain marker'),
              ),
              ElevatedButton(
                onPressed: _addResizedMarker,
                child: const Text('Default pin, custom size'),
              ),
              ElevatedButton(
                onPressed: _addCustomImageMarker,
                child: const Text('Custom image marker'),
              ),
              ElevatedButton(
                onPressed: _addCustomImageMarkerWithInfoWindow,
                child: const Text('Custom image + info window'),
              ),
              ElevatedButton(
                onPressed: _removeAllMarkers,
                child: const Text('Remove all'),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Draggable markers'),
            value: _draggable,
            onChanged: (v) {
              setState(() => _draggable = v);
              _controller?.draggable(v);
            },
          ),
        ],
      ),
    );
  }
}
