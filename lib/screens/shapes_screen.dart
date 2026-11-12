import 'package:flutter/material.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';

import '../config/app_config.dart';
import '../widgets/draggable_map_sheet.dart';

class ShapesScreen extends StatefulWidget {
  const ShapesScreen({super.key});

  @override
  State<ShapesScreen> createState() => _ShapesScreenState();
}

class _ShapesScreenState extends State<ShapesScreen> {
  TplMapsViewController? _controller;

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

  Future<void> _addCircle() async {
    await _controller?.addCircle(24.8650, 67.0450, 500.0, '#2196F3', true);
  }

  Future<void> _removeAllCircles() async {
    await _controller?.removeAllCircles();
  }

  Future<void> _addPolygon() async {
    // The plugin expects polygon points as "lng;lat" — swapped relative to
    // every other coordinate pair in this API (addMarker, addCircle, etc.
    // all take plain lat/lng doubles). Getting this backwards is the most
    // common cause of a polygon rendering far from where you expect.
    final List<String> lngLatPoints = <String>[
      '67.0150;24.8750',
      '67.0300;24.8800',
      '67.0400;24.8700',
      '67.0350;24.8550',
      '67.0200;24.8550',
    ];
    await _controller?.addPolygons(lngLatPoints, '#000000', 6, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shapes')),
      body: DraggableMapSheet(
        map: TplMapsView(
          isShowBuildings: true,
          isZoomEnabled: true,
          showZoomControls: true,
          enablePOIs: true,
          // See MapSettingsScreen: my-location crashes native onMapReady.
          myLocationButtonEnabled: false,
          setMyLocationEnabled: false,
          tplMapsViewCreatedCallback: _onCreated,
          tPlMapsViewPOIClickCallBack: (raw) => _showMessage('POI tapped: $raw'),
          tPlMapsViewCircleClickCallBack: (raw) => _showMessage('Circle tapped: $raw'),
          tPlMapsViewPolygonCallBack: (raw) => _showMessage('Polygon tapped: $raw'),
        ),
        children: [
          const Text(
            'Note: polygon points use lng;lat order — swapped versus every '
            'other coordinate pair in this plugin.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.0),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(onPressed: _addCircle, child: const Text('Add circle')),
              ElevatedButton(onPressed: _removeAllCircles, child: const Text('Remove all circles')),
              ElevatedButton(onPressed: _addPolygon, child: const Text('Add polygon')),
            ],
          ),
        ],
      ),
    );
  }
}
