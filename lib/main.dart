import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:tplmapsflutter/second.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);



  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late TplMapsViewController _controller;

  // Initial Selected Value
  String dropdownvalue = 'Item 1';

  // List of items in our dropdown menu
  var items = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("App Bar 1"),
      ),
      body: Stack(
        children: [
          Container(
            child: TplMapsView(
              isShowBuildings: true,
              isZoomEnabled: true,
              showZoomControls: true,
              isTrafficEnabled: true,
              mapMode: MapMode.NIGHT,
              enablePOIs: true,
              setMyLocationEnabled: false,
              myLocationButtonEnabled: false,
              showsCompass: true,
              allGesturesEnabled: true,
              tplMapsViewCreatedCallback: _callback,
              tPlMapsViewMarkerCallBack: _markerCallback,
            ),

          ),
          Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(10, 10, 10, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton(

                    // Initial Value
                    value: dropdownvalue,

                    // Down Arrow Icon
                    icon: const Icon(Icons.keyboard_arrow_down),

                    // Array list of items
                    items: items.map((String items) {
                      return DropdownMenuItem(
                        value: items,
                        child: Text(items),
                      );
                    }).toList(),
                    // After selecting the desired option,it will
                    // change button value to selected value
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownvalue = newValue!;
                      });
                    },
                  ),
                ],

              )
          ),
          Container(
            margin: EdgeInsets.fromLTRB(10, 50, 10, 0),
            width: double.infinity,
            height: 50,
            color: Colors.red,
            child: Text("Text on the Map", style: TextStyle(color: Colors.white , fontSize: 20),  textAlign: TextAlign.center,),
          )
        ],

      ),


    );

  }

  void _markerCallback(String callback){
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const SecondRoute()),
    // );

    Navigator.push(context, PageTransition(type: PageTransitionType.leftToRight, child: SecondRoute()));

  }

  void _callback(TplMapsViewController controller) {
    controller.showBuildings(false);
    controller.showZoomControls(false);
    controller.setTrafficEnabled(false);
    controller.enablePOIs(true);
    // controller.setMyLocationEnabled(true);
    // controller.myLocationButtonEnabled(true);
    controller.showsCompass(false);
    controller.setCameraPositionAnimated(33.698047971892045, 73.06930062598059,14.0);
    controller.addMarker(33.705349, 73.069788);
    controller.addMarker(33.698047971892045, 73.06930062598059);
    controller.setMapMode(MapMode.DEFAULT);
    bool isBuildingsEnabled = controller.isBuildingEnabled;
    print("isBuildingsEnabled: $isBuildingsEnabled");
    bool isTrafficEnabled = controller.isTrafficEnabled;
    print("isTrafficEnabled: $isTrafficEnabled");
    bool isPOIsEnabled = controller.isPOIsEnabled;
    print("isPOIsEnabled: $isPOIsEnabled");

    _controller  = controller;
  }


  void addMarker(){
    _controller.addMarker(33.705349, 73.069788);
    }

  void addPolyLine(){
    _controller.addPolyLine(33.705349, 73.069788, 33.705349, 73.069788);
    }

  void addCircle(){
    _controller.addCircle(33.705349, 73.069788 , 25.0);
    }

  void removeMarkers(){
    _controller.removeAllMarker();
    }

  void removePolyline(){
    _controller.removePolyline();
    }

  void removeAllCircles(){
    _controller.removeAllCircles();
    }


    // Other methods
    void otherMethods(){

    // ....
    //   _controller.setZoomEnabled(true);
    //   _controller.showBuildings(false);
    //   _controller.showBuildings(false);
    //   _controller.showZoomControls(false);
    //   _controller.setTrafficEnabled(false);
    //   _controller.enablePOIs(true);
    //   _controller.setMyLocationEnabled(true);
    //   _controller.myLocationButtonEnabled(true);
    //   _controller.showsCompass(false);
    //   _controller.setCameraPositionAnimated(33.69804797189, 73.0693006259, 14.0);
    //   _controller.setMapMode(MapMode.DEFAULT);
    //   _controller.isBuildingEnabled;
    //   _controller.isTrafficEnabled;
    //   _controller.isPOIsEnabled;

    }


    // Search
void getSearchItemsbyName (){

  TPlSearchViewController tPlSearchViewController =
  TPlSearchViewController("Atrium Mall" , 24.8607 , 67.0011 , (retrieveItemsCallback) {

    // You will be get json list response
    log(retrieveItemsCallback);
  },);

  tPlSearchViewController.getReverseGeocoding();

}


// Create Route between two points
void getRouting(){
  TPLRoutingViewController tplRoutingViewController =
  TPLRoutingViewController(24.820159, 67.123933, 24.830831, 67.080857 , (tplRoutingCallBack) {
    log(tplRoutingCallBack);
    _controller.setUpPolyLine();
  },);

  tplRoutingViewController.getSearchItems();

}

}
