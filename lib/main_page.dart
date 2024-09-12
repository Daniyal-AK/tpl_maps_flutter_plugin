import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tplmaps_flutter_demo/polyline_page.dart';
import 'package:tplmaps_flutter_demo/routing_page.dart';
import 'package:tplmaps_flutter_demo/search_page.dart';
import 'package:tplmaps_flutter_demo/shapes_page.dart';
import 'gestures_page.dart';
import 'infowindow_page.dart';
import 'mapview_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Flutter Plugins demo",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MapViewPage()),
                        );
                      },
                      child: const Text('MapView',
                        style: TextStyle(
                            fontSize: 20, color: Colors.blueAccent),
                      )
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SearchPage()),
                      );
                    },
                    child: const Text('Search',
                      style: TextStyle(fontSize: 20, color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RoutingPage()),
                      );
                    },
                    child: const Text('Routing',
                      style: TextStyle(fontSize: 20, color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ShapesPage()),
                      );
                    },
                    child: const Text('Shapes',
                      style: TextStyle(fontSize: 20, color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PolyLinePage()),
                      );
                    },
                    child: const Text('PolyLine',
                      style: TextStyle(fontSize: 20, color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GesturesPage()),
                      );
                    },
                    child: const Text('Map Gestures',
                      style: TextStyle(fontSize: 20, color: Colors.blueAccent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      // Location permission granted, do something with location
      print('Location permission granted');
    } else if (status.isDenied) {
      // Location permission denied, show a message or handle accordingly
      print('Location permission denied');
    } else if (status.isPermanentlyDenied) {
      // Permission is permanently denied, you can open app settings
      openAppSettings();
    }

    @override
    void dispose() {
      super.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    requestLocationPermission(); // Request permission on app startup
  }
}
