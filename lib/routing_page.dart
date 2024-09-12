import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';

import 'Utils.dart';

class RoutingPage extends StatefulWidget {
  @override
  _RoutingPageState createState() => _RoutingPageState();
}

late TplMapsViewController _controller;
String myKey = "YOUR_API_KEY";

class _RoutingPageState extends State<RoutingPage> {
  String _origins_latLng = "33.71210524028265,73.05779999610466";
  String _destination_latLng = "33.68816353784396,72.98338785144722";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Routing Demo',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          backgroundColor: Colors.blue,
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
              child: Column(
               // mainAxisAlignment: MainAxisAlignment.end,
                children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                          child: TextField(
                            onChanged: (value) {
                              _origins_latLng = value;
                            },
                            decoration: InputDecoration(
                             hintText: '33.71210524028265,73.05779999610466',
                              hintStyle: TextStyle(color: Colors.grey),
                             labelStyle: TextStyle(color: Colors.black),
                             // labelText: '33.71210524028265,73.05779999610466',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: TextField(
                            onChanged: (value) {
                              _destination_latLng = value;
                            },
                            decoration: InputDecoration(
                              hintText: '33.68816353784396,72.98338785144722',
                              hintStyle: TextStyle(color: Colors.grey),
                              labelStyle: TextStyle(color: Colors.black),
                              //labelText: '33.68816353784396,72.98338785144722',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                  GestureDetector(
                    onTap: () {
                      if(_origins_latLng.contains(",") && _destination_latLng.contains(",")){
                        try {
                          // Split the string by commas
                          List<String> _origins_latLngList = _origins_latLng.split(',');
                          List<String> _destination_latLngList = _destination_latLng.split(',');

                          // Convert each substring to a double
                          // List<double> _destination_latLngListDouble = _origins_latLngList.map((str) => double.parse(str.trim())).toList();
                          // List<double> _destination_latLngListDouble = _destination_latLngList.map((str) => double.parse(str.trim())).toList();
                          print("polyLine values: $_origins_latLngList , $_destination_latLngList");
                          var polyLineStartLat = _origins_latLngList[0];
                          var polyLineStartLang = _origins_latLngList[1];
                          var polyLineEndLat = _destination_latLngList[0];
                          var polyLineEndLang = _destination_latLngList[1];
                          var polyLineColor = "#FFF000";
                          var polyLineWidth = 5;

                          createRoute(polyLineStartLat, polyLineStartLang, polyLineEndLat, polyLineEndLang, polyLineWidth, polyLineColor);

                        } catch (e) {
                          print("Error: $e");
                        }
                      }else{
                        Utils.showMessageToast("Lat Lang should be , separated");
                      }
                    },
                    child: Container(
                      width: double.maxFinite,
                      height: 45.0,
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(left: 20.0,right: 20.0,top: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Create Route",
                        style: TextStyle(color: Colors.white,fontSize: 16.0),
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
      _controller = controller;

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

  void createRoute(String startLat , String startLng , String endLat , String endLng, int width , String color) {

    var currentLatLng = "$startLat;$startLng"; // your current location

    List<String> destinationLatLng = [
      '$endLat;$endLng', // you can pass single destination
    ];

    _controller.createRoute(currentLatLng, destinationLatLng , color, width,  myKey);

    _controller.setCameraPositionAnimated(double.parse(startLat), double.parse(startLng), 14.0);

  }

}
