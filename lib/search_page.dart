import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';

import 'Utils.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}
late TplMapsViewController _controller;

class _SearchPageState extends State<SearchPage> {
  String _searchValue = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Searching Demo',
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
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextField(
                        onChanged: (value) {
                          _searchValue = value;
                        },
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
                      getSearchItemsbyName(_searchValue);
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

  void getSearchItemsbyName(String text) {
    TPlSearchViewController tPlSearchViewController = TPlSearchViewController(
      text,
      24.8607,
      67.0011,
          (retrieveItemsCallback) {
        print(retrieveItemsCallback);

        List<dynamic> decodedResponse = json.decode(retrieveItemsCallback);

        // Access the first element of the array and then the "responseData" key
        var responseData = decodedResponse[0]['compound_address_parents'];

        // Access the "compound_address_parents" key from "responseData"
        // String compoundAddressParents =
        // responseData['1']['compound_address_parents'];

        // Future.delayed(const Duration(milliseconds: 2500), () {
        setState(() {

          print(decodedResponse[0]['lat']);
          print(decodedResponse[0]['lng']);

          String latitude = decodedResponse[0]['lat'];
          String longitude = decodedResponse[0]['lng'];

          _controller.addMarker(double.parse(latitude), double.parse(longitude));

         String address = responseData;
          _controller.setCameraPositionAnimated(
              double.parse(decodedResponse[0]['lat']),  double.parse(decodedResponse[0]['lng']), 14.0);
        });

        Utils.showMessageToast("ADDRESS FOUND: $responseData");
        // });

      },
    );

    tPlSearchViewController.getSearchItems();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
