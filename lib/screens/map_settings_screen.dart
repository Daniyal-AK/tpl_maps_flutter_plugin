import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';

import '../config/app_config.dart';
import '../utils/location_helper.dart';
import '../utils/native_callback_parser.dart';
import '../utils/platform_utils.dart';
import '../widgets/draggable_map_sheet.dart';

class MapSettingsScreen extends StatefulWidget {
  const MapSettingsScreen({super.key});

  @override
  State<MapSettingsScreen> createState() => _MapSettingsScreenState();
}

class _MapSettingsScreenState extends State<MapSettingsScreen> {
  TplMapsViewController? _controller;
  double _zoomLevel = AppConfig.defaultZoom;

  bool _zoomControls = true;
  bool _pois = true;
  bool _compass = true;
  bool _allGestures = true;
  bool _zoomEnabled = true;
  bool _night = true;

  String _statusText = 'Tap "Refresh status" to read controller getters.';
  bool _locating = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onCreated(TplMapsViewController controller) {
    _controller = controller;
    controller.setCameraPositionAnimated(
      AppConfig.defaultCameraLat,
      AppConfig.defaultCameraLng,
      _zoomLevel,
    );
  }

  void _onLongClick(String raw) {
    final NativeLatLng? latLng = NativeCallbackParser.extractLatLng(raw);
    if (latLng != null && latLng.isValid) {
      _showMessage('Long-press at $latLng');
    } else {
      _showMessage('Long-press callback: $raw');
    }
  }

  Future<void> _refreshStatus() async {
    final TplMapsViewController? controller = _controller;
    if (controller == null) return;
    setState(() {
      _statusText = 'buildings=${controller.isBuildingEnabled}  '
          'traffic=${controller.isTrafficEnabled}  '
          'pois=${controller.isPOIsEnabled}';
    });
  }

  // Every one of these controller calls below is unawaited on purpose: the
  // plugin's native handler for its mutator methods (cancelMapRequest,
  // setCameraPositionAnimated, addMarker, ...) never calls the method
  // channel's result.success/error on either platform (confirmed by
  // grepping the 2.0.7 native sources — zero result.success calls in
  // Android's TPLMapView.onMethodCall, and iOS only resolves the
  // unmatched-method fallback). Awaiting one when code needs to run
  // afterward hangs that code forever — see routing_screen.dart's
  // _createRoute for the full writeup. There is no way to know from Dart
  // whether any of these actually succeeded; the calls below just fire and
  // the UI assumes success.
  void _cancelMapRequest() {
    unawaited(_controller?.cancelMapRequest());
    _showMessage('Map request cancelled.');
  }

  void _pauseMapRequest() {
    unawaited(_controller?.pauseMapRequest());
    _showMessage('Map request paused.');
  }

  // Stands in for the native "my location" button, which crashes on this
  // plugin version (see the TplMapsView comment below) — resolves the
  // device's GPS position directly via geolocator instead and recenters
  // the map the user just panned/zoomed away from.
  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      final position = await LocationHelper.getCurrentPosition();
      unawaited(_controller?.setCameraPositionAnimated(
        position.latitude,
        position.longitude,
        16.0,
      ));
      unawaited(_controller?.removeAllMarker());
      unawaited(_controller?.addMarker(position.latitude, position.longitude));
    } catch (e) {
      _showMessage('Could not locate you: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Settings & Gestures')),
      body: DraggableMapSheet(
        map: TplMapsView(
          isShowBuildings: true,
          isZoomEnabled: _zoomEnabled,
          showZoomControls: _zoomControls,
          isTrafficEnabled: true,
          enablePOIs: _pois,
          showsCompass: _compass,
          // My-location button/indicator is left disabled on every
          // screen: enabling it crashes native onMapReady with a
          // ClassCastException in UIViewHelper.getViewMyLocation
          // (android.widget.ImageView cannot be cast to
          // FloatingActionButton), which silently prevents
          // tplMapsViewCreatedCallback from ever firing. Confirmed
          // against plugin 2.0.7 on this toolchain.
          myLocationButtonEnabled: false,
          setMyLocationEnabled: false,
          allGesturesEnabled: _allGestures,
          mapMode: _night ? MapMode.NIGHT : MapMode.DEFAULT,
          tplMapsViewCreatedCallback: _onCreated,
          tPlMapsViewLongClickCallBack: _onLongClick,
        ),
        overlayChildren: [
          Center(
            child: GestureDetector(
              onTap: () {
                if (!isTplMapsAndroid) {
                  _showMessage('setZoomFixedCenter is Android-only.');
                  return;
                }
                setState(() => _zoomLevel += 1);
                _controller?.setZoomFixedCenter(_zoomLevel);
              },
              child: Image.asset('assets/droppin.jpg', width: 32, height: 32),
            ),
          ),
          // Anchored to the top, not bottom-right, so the draggable sheet
          // below can never cover it regardless of how far it's dragged up.
          Positioned(
            right: 12.0,
            top: 12.0,
            child: FloatingActionButton.small(
              heroTag: 'locate-me-fab',
              onPressed: _locating ? null : _locateMe,
              child: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
        ],
        children: [
          SwitchListTile(
                  title: const Text('Zoom controls'),
                  value: _zoomControls,
                  onChanged: (v) {
                    setState(() => _zoomControls = v);
                    _controller?.showZoomControls(v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Points of interest'),
                  value: _pois,
                  onChanged: (v) {
                    setState(() => _pois = v);
                    _controller?.enablePOIs(v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Compass'),
                  value: _compass,
                  onChanged: (v) {
                    setState(() => _compass = v);
                    _controller?.showsCompass(v);
                  },
                ),
                SwitchListTile(
                  title: const Text('All gestures'),
                  value: _allGestures,
                  onChanged: (v) {
                    setState(() => _allGestures = v);
                    _controller?.allGesturesEnabled(v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Zoom enabled'),
                  value: _zoomEnabled,
                  onChanged: (v) {
                    setState(() => _zoomEnabled = v);
                    _controller?.setZoomEnabled(v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Night mode'),
                  value: _night,
                  onChanged: (v) {
                    setState(() => _night = v);
                    _controller?.setMapMode(v ? MapMode.NIGHT : MapMode.DEFAULT);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _zoomLevel -= 1);
                            _controller?.setZoomLevel(_zoomLevel);
                          },
                          child: const Text('Zoom out'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _zoomLevel += 1);
                            _controller?.setZoomLevel(_zoomLevel);
                          },
                          child: const Text('Zoom in'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _controller?.animateToZoom(16.0),
                          child: const Text('Animate to 16'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTplMapsAndroid)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancelMapRequest,
                            child: const Text('Cancel map request'),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pauseMapRequest,
                            child: const Text('Pause map request'),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: Text(_statusText)),
                      TextButton(
                        onPressed: _refreshStatus,
                        child: const Text('Refresh status'),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
