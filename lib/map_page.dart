import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';
import 'package:http/http.dart' as http;
import 'Utils.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

late TplMapsViewController _controller;
double zoomLevel = 8;

class _MyAppState extends State<MapPage > {
  String textValue = "";
  Timer timeHandle = Timer(Duration(seconds: 3), () {});
  int markerCount = 0;
  String myKey = "\$2a\$10\$S0hDhKNNZgcC9JR6nPXDBDrUAqj8f5gDLP2a0lLGqCTfNKq5GpvY6";


  void textChanged(String val) {
    textValue = val;
    if (timeHandle != null) {
      timeHandle.cancel();
    }
    timeHandle = Timer(Duration(seconds: 3), () {
      if (textValue != "") {
        print("Calling API Here: $textValue");
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    timeHandle.cancel();
  }

  String address = ''; // Initial text value

  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'map';
    // Pass parameters to the platform side.
    const Map<String, dynamic> creationParams = <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: Text("Mapview Demo",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Container(
            child: TplMapsView(
              isShowBuildings: true,
              isZoomEnabled: true,
              showZoomControls: true,
              isTrafficEnabled: true,
              longClickMarkerEnable: true,
              mapMode: MapMode.NIGHT,
              enablePOIs: true,
              setMyLocationEnabled: false,
              myLocationButtonEnabled: true,
              showsCompass: true,
              allGesturesEnabled: true,
              tplMapsViewCreatedCallback: _onTPLMapsViewCreatedCallback,
              tPlMapsViewMarkerCallBack: _markerCallback,
              tPlMapsViewPolyLineCallBack: _polyLineCallback,
              tPlMapsViewPOIClickCallBack: _POIClickCallback,
              tPlMapsViewPolygonCallBack: _polygonClickCallback,
              tPlMapsViewLongClickCallBack: _mapViewLongClickCallback,
              tPlMapsViewCircleClickCallBack: _mapViewCircleClickCallback,
              tPlMapsViewCameraChangedCallBack: _mapViewCameraChangedCallback,
            ),
          ),
          GestureDetector(
            onTap: () {
              zoomLevel += 1;
              _controller.setZoomFixedCenter(zoomLevel);
            },
            child: Center(
              child: Container(
                child: Image.asset(
                  'assets/droppin.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 5,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Address: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(

                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: TextField(
                  onSubmitted: (String value) {
                    getSearchItemsbyName(value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              // Bottom right aligned icons
            ],
          ),
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: Padding(
          //     padding: const EdgeInsets.all(1.0),
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.end,
          //       crossAxisAlignment: CrossAxisAlignment.end,
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         GestureDetector(
          //           onTap: () {
          //               addPolyline();
          //           },
          //           child: Image.asset(
          //             'assets/mylocation.png',
          //             width: 70,
          //             height: 70,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  void _markerCallback(String callback) {
    print(callback);
    Utils.showMessageToast("Marker CLICK Callback");
    // Find the index of "LatLng:"
    int latLngIndex = callback.indexOf("LatLng:");

    if (latLngIndex != -1) {
      // Extract substring after "LatLng:"
      String latLngSubstring =
          callback.substring(latLngIndex + "LatLng:".length).trim();

      // Split the substring to get the values
      List<String> values = latLngSubstring.split(',');

      // Assuming the first value is latitude and the second value is longitude
      if (values.length >= 2) {
        String latitude = values[0].trim();
        String longitude = values[1].trim();

        print("Latitude: $latitude, Longitude: $longitude");

        postData(latitude + ";" + longitude.split("}")[0]);
      }
    }
  }

  void _polyLineCallback(String callback) {
    print(callback);
    Utils.showMessageToast("PolyLine CLICK Callback");
  }

  void _polygonClickCallback(String callback) {
    print(callback);
    Utils.showMessageToast("Polygon CLICK Callback");
  }

  void _POIClickCallback(String callback) {
    print(callback);
    Utils.showMessageToast("POI CLICK Callback");
  }

  void _mapViewCircleClickCallback(String callback) {
    print(callback);
    Utils.showMessageToast("Circle CLICK Callback");
  }

  void _mapViewLongClickCallback(String callback) {
    print(callback);

    int latLngIndex = callback.indexOf("LatLng:");

    if (latLngIndex != -1) {
      // Extract substring after "LatLng:"
      String latLngSubstring =
      callback.substring(latLngIndex + "LatLng:".length).trim();

      // Split the substring to get the values
      List<String> values = latLngSubstring.split(',');

      // Assuming the first value is latitude and the second value is longitude
      if (values.length >= 2) {

        String latitude = values[0].trim();
        String longitude = values[1].trim();

        Utils.showMessageToast("Long Click");

      }
    }
  }

  void _mapViewCameraChangedCallback(String callback) {
    print(callback);
   //Utils.showMessageToast("Camera Changed Callback");
    int latLngIndex = callback.indexOf("LatLng:");
    if (latLngIndex != -1) {
      // Extract substring after "LatLng:"
      String latLngSubstring =
      callback.substring(latLngIndex + "LatLng:".length).trim();

      // Split the substring to get the values
      List<String> values = latLngSubstring.split(',');

      // Assuming the first value is latitude and the second value is longitude
      if (values.length >= 2) {
        String latitude = values[0].trim();
        String longitude = values[1].trim();

        print("Latitude: $latitude, Longitude: $longitude");

        postData(latitude + ";" + longitude.split("}")[0]);
      }
    }
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
    bool isBuildingsEnabled = controller.isBuildingEnabled;
    print("isBuildingsEnabled: $isBuildingsEnabled");
    bool isTrafficEnabled = controller.isTrafficEnabled;
    print("isTrafficEnabled: $isTrafficEnabled");
    bool isPOIsEnabled = controller.isPOIsEnabled;
    print("isPOIsEnabled: $isPOIsEnabled");

    var cameraPositionLat = 33.71210524028265;
    var cameraPositionLang = 73.05779999610466;

    controller.setCameraPositionAnimated(
        cameraPositionLat, cameraPositionLang, 16.0);

     controller.addMarker(33.698047971892045, 73.06930062598059);

    controller.addMarkerCustomMarker(
        33.72028915308924, 73.06209004396614, 60, 60);

    ////////////Add CustomMarker

    var image = "data:image/png;base64,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";
    var markerLat = 33.71210524028265;
    var markerLang = 73.05779999610466;
    var markerWidth = 70;
    var markerHeight = 70;
    var markerID = "1011";
    var markerTitle = "Custom marker";
    var markerDescription = "this is a custom Marker";

    // controller.addCustomMarkerBase64WithInfoWindow(markerLat, markerLang, image,
    //     markerWidth, markerHeight, markerTitle, markerDescription);
    controller.addCustomMarkerBase64WithInfoWindow(markerID,markerLat, markerLang, image,
        markerWidth, markerHeight, markerTitle, markerDescription);

    ///////////Add Circle

    var circleLat = 33.723149149167504;
    var circleLang = 73.06167650992974;
    var circleRadius = 600.0;
    var isClickable = true;
    var color = "#FF0000";

    addCircle(circleLat, circleLang,circleRadius,color,isClickable);

    /////////////////Add PolyLine

    var polyLineStartLat = 33.71210524028265;
    var polyLineStartLang = 73.05779999610466;
    var polyLineEndLat = 33.68816353784396;
    var polyLineEndLang = 72.98338785144722;
    var polyLineColor = "#FFF000";
    var polyLineWidth = 15;

    addPolyline(polyLineStartLat, polyLineStartLang, polyLineEndLat, polyLineEndLang, polyLineWidth, polyLineColor);

    ////////////////Add Polygons

    List<String> lngLats1 = [];
    lngLats1.add("${73.07824953648002};${33.735870643214774}");
    lngLats1.add("${73.07500992070422};${33.736504540028584}");
    lngLats1.add("${73.07424773695865};${33.73390100779751}");
    lngLats1.add("${73.08020704883475};${33.73236925579299}");
    lngLats1.add("${73.07457476129804};${33.73022716672756}");
    lngLats1.add("${73.08081375969778};${33.72709474879913}");
    lngLats1.add("${73.08962864042788};${33.73553948921669}");

    var polygonColor = "#000000";
    var polygonOuterLineWidth = 10;
    var clickable = true;

    addPolygons(lngLats1,polygonColor,polygonOuterLineWidth,clickable);

    /////////////////Create Route

    createRoute(polyLineStartLat, polyLineStartLang, polyLineEndLat, polyLineEndLang);

    // controller.addMarkerCustomMarker(33.698047972345, 73.0693006876459, 50 , 50);
    // controller.addMarkerCustomMarker(33.6980479712357878, 73.06930098543452, 50 , 50);
    // controller.addMarkerCustomMarker(33.698047971652341, 73.069300687988, 50 , 50);
    // controller.addMarkerCustomMarker(33.69804797667524235, 73.06930062855673, 50 , 50);
    // controller.addMarkerCustomMarker(0, 0, 50 , 50);
    // controller.addMarkerCustomMarker(24.826295, 67.1236449, 50 , 50);

   // controller.addMarker( 31.87241678580601, 70.89785992467577);

    // controller.allGesturesEnabled(false);

    //mapMode: MapMode.DEFAULT,

    // _controller.removeAllMarker();

   // _controller.animateToZoom(14.0);

  //  addPolyline();

    //fetchData();
   _controller.startNavigation(33.713121373794046, 73.05870351996428 , 33.72888654769727, 73.07330194621892);
  }

  void addPolyline(double startLat , double startLng , double endLat , double endLng , int width, String color) {

    _controller.addPolyLine(startLat , startLng , endLat , endLng, width, color);

 //  _controller.setCameraPositionAnimated(31.421756109160672, 74.25121370139648, 14.0); for Zoom level

  }


  void createRoute(double startLat , double startLng , double endLat , double endLng) {

    var currentLatLng = "$startLat;$startLng"; // your current location

    List<String> destinationLatLng = [
      '$endLat;$endLng', // you can pass single destination
    ];

    _controller.createRoute(currentLatLng, destinationLatLng , "#0000FF", 2 ,  myKey);

    //  _controller.setCameraPositionAnimated(31.421756109160672, 74.25121370139648, 14.0); for Zoom level

  }

  void addCircle(double lat , double lng , double radius, String color, bool isClickable) {
    _controller.addCircle(lat, lng, radius, color, isClickable);
  }

  void removePolyLine() {
    _controller.removePolyline();
  }

  void removeCircles() {
    _controller.removeAllCircles();
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
            address = responseData;
            _controller.setCameraPositionAnimated(
                double.parse(decodedResponse[0]['lat']),  double.parse(decodedResponse[0]['lng']), 14.0);
          });

          Utils.showMessageToast("ADDRESS FOUND: $responseData");
       // });

      },
    );

    tPlSearchViewController.getSearchItems();
  }

  Future<void> postData(String latlng) async {
    final apiUrl = 'https://api1.tplmaps.com:8888/search/rgeocodebulk?addressCount=1&apikey=${myKey}';
    List<Map<String, dynamic>> dataArray = [
      {
        'point': latlng
      },
    ];
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(dataArray),
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        List<dynamic> decodedResponse = json.decode(response.body);

        // Access the first element of the array and then the "responseData" key
        var responseData = decodedResponse[0]['responseData'];

        // Access the "compound_address_parents" key from "responseData"
        String compoundAddressParents = responseData['1']['compound_address_parents'];

        setState(() {
          address = compoundAddressParents;
        });
      } else {
        // Request failed
        print('Failed to post data: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (error) {
      // Error in making the request
      print('Error: $error');
    }
  }

  void addPolygons(List<String> lngLats, String polygonColor, int polygonOuterLineWidth, bool isClickable) {

    _controller.addPolygons(lngLats,polygonColor,polygonOuterLineWidth,isClickable);

      //  _controller.setCameraPositionAnimated(31.421756109160672, 74.25121370139648, 14.0); for Zoom level

  }



}
