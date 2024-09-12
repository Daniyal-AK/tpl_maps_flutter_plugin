import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:tplmapsflutterplugin/TplMapsView.dart';
import 'package:http/http.dart' as http;
import 'Utils.dart';

class GesturesPage extends StatefulWidget {
  @override
  _GesturesState createState() => _GesturesState();
}

late TplMapsViewController _controller;
double zoomLevel = 8;

List<bool> _isChecked = List<bool>.filled(4, false);

final List<String> _names = [
  'All Gestures',
  'Show Zoom Control',
  'enable POI',
  'Night mode',
];

class _GesturesState extends State<GesturesPage> {
  @override
  void dispose() {
    super.dispose();
  }

  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'map';
    // Pass parameters to the platform side.
    const Map<String, dynamic> creationParams = <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Map Gestures Demo",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Container(
            child: TplMapsView(
                isShowBuildings: true,
                isZoomEnabled: true,
                showZoomControls: false,
                isTrafficEnabled: true,
                mapMode: MapMode.DEFAULT,
                enablePOIs: false,
                setMyLocationEnabled: true,
                myLocationButtonEnabled: true,
                showsCompass: true,
                allGesturesEnabled: true,
                tplMapsViewCreatedCallback: _onTPLMapsViewCreatedCallback),
          ),
          Column(
            children: <Widget>[
              Container(
                color: Colors.white,
                height: 150,
                width: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _isChecked.length,
                  itemBuilder: (context, index) {
                    return Container(
                      height: 30,
                      child: Row(
                        children: [
                          Checkbox(
                            value: _isChecked[index],
                            onChanged: (bool? value) {
                              updateGesture(index,value);
                              setState(() {
                                _isChecked[index] = value!;
                              });
                            },
                          ),
                          Text(_names[index]),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectAll() {
    setState(() {
      _isChecked = List<bool>.filled(_isChecked.length, true);
    });
    print(_isChecked);
  }

  void _deselectAll() {
    setState(() {
      _isChecked = List<bool>.filled(_isChecked.length, false);
    });
    print(_isChecked);
  }

  void _reverseSelection() {
    setState(() {
      _isChecked = _isChecked.map((bool value) => !value).toList();
    });
    print(_isChecked);
  }

  void _onTPLMapsViewCreatedCallback(TplMapsViewController controller) {
    _controller = controller;

    // controller.setCameraPositionAnimated(
    //     cameraPositionLat, cameraPositionLang, 16.0);
  }

  void updateGesture(int index, bool? value) {
    switch(index){
      case 0:
        {
          if (value != null)
            _controller.allGesturesEnabled(value);
          Utils.showMessageToast('${_names[index]}, $value');
          break;
        }
        case 1:
        {
          if (value != null)
            _controller.showZoomControls(value);
          Utils.showMessageToast('${_names[index]}, $value');
          break;
        }
        case 2:
        {
          if (value != null)
            _controller.enablePOIs(value);
          Utils.showMessageToast('${_names[index]}, $value');
          break;
        }
        case 4:
        {
          if (value != null)
            if(value)
            _controller.setMapMode(MapMode.NIGHT);
          else
              _controller.setMapMode(MapMode.DEFAULT);

          Utils.showMessageToast('${_names[index]}, $value');
          break;
        }
    }
  }
}
