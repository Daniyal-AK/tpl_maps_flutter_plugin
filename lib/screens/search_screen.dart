import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tplmapsflutterplugin/TplMapsView.dart';

import '../config/app_config.dart';
import '../utils/camera_fit.dart';
import '../utils/location_helper.dart';
import '../utils/native_callback_parser.dart';
import '../utils/platform_utils.dart';
import '../utils/tplmaps_coords.dart';
import '../utils/tplmaps_routing.dart';
import '../widgets/draggable_map_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TplMapsViewController? _controller;
  Timer? _debounce;
  Timer? _searchTimeout;

  // The plugin's search channel ('plugins/search') is a single global
  // MethodChannel shared by every TPlSearchViewController instance, with no
  // per-request id — whichever instance last called setMethodCallHandler
  // "owns" the channel. Firing a second native search while one is still
  // in flight silently reassigns that ownership, so the first request's
  // result (if it ever arrives) is delivered to the wrong handler and the
  // original caller's `_loading` never clears. Queuing instead of firing
  // concurrent requests, plus a timeout as a backstop, is what actually
  // fixes the "stuck on loading" symptom — a shorter debounce alone doesn't.
  String? _pendingQuery;

  String _address = '';
  List<dynamic> _results = <dynamic>[];
  bool _loading = false;
  String? _error;
  String? _nativeReverseGeocodeResult;

  // The place the user tapped from the suggestion list, drives the
  // "Directions" bottom card. Cleared when a new search starts.
  String? _selectedPlaceName;
  double? _selectedLat;
  double? _selectedLng;
  bool _routing = false;
  String? _routeDistance;
  String? _routeTime;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchTimeout?.cancel();
    super.dispose();
  }

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

  void _onSearchChanged(String value) {
    // Every keystroke cancels and restarts this timer, so the search only
    // fires 3s after the user stops typing — typing again within that
    // window resets the 3s wait rather than queuing an earlier fire.
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), () {
      final String text = value.trim();
      if (text.isEmpty) {
        setState(() => _results = <dynamic>[]);
        return;
      }
      _queueSearch(text);
    });
  }

  void _queueSearch(String text) {
    if (_loading) {
      _pendingQuery = text;
      return;
    }
    _search(text);
  }

  void _runPendingSearch() {
    final String? pending = _pendingQuery;
    _pendingQuery = null;
    if (pending != null) _search(pending);
  }

  Future<void> _search(String text) async {
    _searchTimeout?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });

    final TPlSearchViewController searchController = TPlSearchViewController(
      text,
      AppConfig.defaultBiasLat,
      AppConfig.defaultBiasLng,
      (String raw) {
        _searchTimeout?.cancel();
        if (!mounted) return;
        try {
          final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
          setState(() {
            _results = decoded;
            _loading = false;
          });
        } catch (e) {
          setState(() {
            _error = 'Could not parse search results: $e';
            _loading = false;
          });
        }
        _runPendingSearch();
      },
    );

    try {
      await searchController.getSearchItems();
    } catch (e) {
      _searchTimeout?.cancel();
      setState(() {
        _error = 'Search failed: $e';
        _loading = false;
      });
      _runPendingSearch();
      return;
    }

    // Backstop: if the native side never calls back (see the field comment
    // on _pendingQuery), don't leave the UI spinning forever.
    _searchTimeout = Timer(const Duration(seconds: 8), () {
      if (!mounted || !_loading) return;
      setState(() {
        _loading = false;
        _error = 'Search timed out — try again.';
      });
      _runPendingSearch();
    });
  }

  Future<void> _selectResult(dynamic item) async {
    try {
      final double lat = double.parse(item['lat'].toString());
      final double lng = double.parse(item['lng'].toString());
      final String name = item['compound_address_parents']?.toString() ?? 'Selected place';
      // Not awaited: the plugin's native handler for addMarker (and every
      // other mutator method) never resolves the method channel's result
      // callback on either platform, so awaiting it here would hang this
      // function forever and the zoom call right after would never run —
      // that was the real cause of "tapping a result adds a marker but
      // never zooms". See routing_screen.dart's _createRoute for the full
      // explanation (confirmed by reading the plugin's native sources).
      unawaited(_controller?.addMarker(lat, lng));
      unawaited(_controller?.setCameraPositionAnimated(lat, lng, 16.0));
      setState(() {
        _address = name;
        _results = <dynamic>[];
        _selectedPlaceName = name;
        _selectedLat = lat;
        _selectedLng = lng;
        _routeDistance = null;
        _routeTime = null;
      });
    } catch (e) {
      _showMessage('Could not use this result: $e');
    }
  }

  Future<void> _getDirectionsToSelectedPlace() async {
    final double? lat = _selectedLat;
    final double? lng = _selectedLng;
    if (lat == null || lng == null) return;

    setState(() {
      _routing = true;
      _routeDistance = null;
      _routeTime = null;
    });
    try {
      final position = await LocationHelper.getCurrentPosition();
      final RouteResult route = await TplMapsRouting.fetchRoute(
        originLat: position.latitude,
        originLng: position.longitude,
        destinationLat: lat,
        destinationLng: lng,
        apiKey: AppConfig.apiKey,
      );
      unawaited(_controller?.removePolyline());
      // addPolyLines needs points pre-swapped to "lng;lat" — see
      // TplMapsCoords for why (a confirmed lat/lng swap bug in the
      // plugin's native addPolyLines handler itself).
      unawaited(_controller?.addPolyLines(
        route.points.map((p) => TplMapsCoords.polylinePoint(p.$1, p.$2)).toList(),
        5,
        '#0000FF',
      ));
      final (double fitLat, double fitLng, double zoom) = CameraFit.fit(route.points);
      unawaited(_controller?.setCameraPositionAnimated(fitLat, fitLng, zoom));
      setState(() {
        _routeDistance = route.distance;
        _routeTime = route.time;
      });
    } catch (e) {
      _showMessage('Could not get directions: $e');
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  void _clearSelectedPlace() {
    setState(() {
      _selectedPlaceName = null;
      _selectedLat = null;
      _selectedLng = null;
      _routeDistance = null;
      _routeTime = null;
    });
    _controller?.removePolyline();
  }

  void _onMarkerTap(String raw) {
    final NativeLatLng? latLng = NativeCallbackParser.extractLatLng(raw);
    if (latLng != null && latLng.isValid) {
      _reverseGeocodeViaRest('${latLng.latitude};${latLng.longitude}');
    }
  }

  Future<void> _reverseGeocodeViaRest(String latLng) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final Uri uri = Uri.parse(
      '${AppConfig.reverseGeocodeUrl}?addressCount=1&apikey=${AppConfig.apiKey}',
    );
    try {
      final http.Response response = await http.post(
        uri,
        headers: const <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{'point': latLng},
        ]),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body) as List<dynamic>;
        final dynamic responseData = decoded[0]['responseData'];
        final String compoundAddressParents =
            responseData['1']['compound_address_parents'].toString();
        setState(() => _address = compoundAddressParents);
      } else {
        setState(() => _error = 'Reverse geocode failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Reverse geocode failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reverseGeocodeDemoPoint() async {
    final TPlSearchViewController searchController = TPlSearchViewController(
      null,
      AppConfig.defaultCameraLat,
      AppConfig.defaultCameraLng,
      (String raw) {
        if (!mounted) return;
        setState(() => _nativeReverseGeocodeResult = raw);
      },
    );
    try {
      await searchController.getReverseGeocoding();
    } catch (e) {
      _showMessage('getReverseGeocoding failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isTplMapsAndroid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Search & Reverse-Geocode')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Place search and reverse-geocoding have no native handler on '
              'this platform in the current plugin version — Android only.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Search & Reverse-Geocode')),
      body: DraggableMapSheet(
        map: TplMapsView(
          isShowBuildings: true,
          isZoomEnabled: true,
          // See MapSettingsScreen: my-location crashes native onMapReady.
          myLocationButtonEnabled: false,
          setMyLocationEnabled: false,
          tplMapsViewCreatedCallback: _onCreated,
          tPlMapsViewMarkerCallBack: _onMarkerTap,
        ),
        children: [
          TextField(
            onChanged: _onSearchChanged,
            onSubmitted: (value) => _queueSearch(value.trim()),
            decoration: const InputDecoration(
              labelText: 'Search for a place',
              hintText: 'Suggestions appear as you type',
              border: OutlineInputBorder(),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ..._results.map(
            (dynamic item) => ListTile(
              title: Text(item['compound_address_parents']?.toString() ?? 'Result'),
              onTap: () => _selectResult(item),
            ),
          ),
          const SizedBox(height: 8.0),
          if (_selectedPlaceName != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedPlaceName!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _clearSelectedPlace,
                        ),
                      ],
                    ),
                    if (_routeDistance != null || _routeTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                        child: Text('Distance: ${_routeDistance ?? '-'}   Time: ${_routeTime ?? '-'}'),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _routing ? null : _getDirectionsToSelectedPlace,
                        icon: _routing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.directions),
                        label: const Text('Directions'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Address: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(_address)),
                  ],
                ),
              ),
            ),
          if (_nativeReverseGeocodeResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Native reverse geocode result: $_nativeReverseGeocodeResult',
                style: const TextStyle(fontSize: 12.0),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ElevatedButton(
              onPressed: _reverseGeocodeDemoPoint,
              child: const Text('Native reverse geocode (demo location)'),
            ),
          ),
        ],
      ),
    );
  }
}
