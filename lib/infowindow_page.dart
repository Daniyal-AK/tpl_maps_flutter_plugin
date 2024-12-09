import 'package:flutter/material.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';

import 'Utils.dart';

class InfowindowPage extends StatefulWidget {

  @override
  _InfowindowPageState createState() => _InfowindowPageState();
}

class _InfowindowPageState extends State<InfowindowPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('PolyLine Demo'),
        ),
        body: Stack(
          children: [
            Container(
              child: TplMapsView(
                  isShowBuildings: false,
                  isZoomEnabled: false,
                  showZoomControls: true,
                  isTrafficEnabled: false,
                  longClickMarkerEnable: false,
                  mapMode: MapMode.NIGHT,
                  enablePOIs: false,
                  setMyLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  showsCompass: false,
                  allGesturesEnabled: true,
                  tplMapsViewCreatedCallback: _onTPLMapsViewCreatedCallback),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter search text',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true, // Add this line
                          fillColor: Colors.white, // And this line
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Call the API for search
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  void _onTPLMapsViewCreatedCallback(TplMapsViewController controller) {
    //   _controller = controller;

    // controller.setZoomEnabled(false);
    // controller.showBuildings(false);
    // controller.showBuildings(false);
    // controller.setTrafficEnabled(false);
    // controller.enablePOIs(false);
    // controller.setMyLocationEnabled(true);
    // controller.myLocationButtonEnabled(true);
    // controller.showsCompass(false);

    controller.setMapMode(MapMode.DEFAULT);
    controller.animateToZoom(10);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
