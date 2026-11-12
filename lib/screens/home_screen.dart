import 'package:flutter/material.dart';

import 'map_settings_screen.dart';
import 'markers_screen.dart';
import 'polylines_screen.dart';
import 'routing_screen.dart';
import 'search_screen.dart';
import 'shapes_screen.dart';

class _DemoEntry {
  const _DemoEntry(this.title, this.subtitle, this.icon, this.builder);

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final List<_DemoEntry> _entries = <_DemoEntry>[
    _DemoEntry(
      'Map Settings & Gestures',
      'Day/night mode, zoom, gestures, locate-me',
      Icons.settings_suggest,
      (_) => const MapSettingsScreen(),
    ),
    _DemoEntry(
      'Markers',
      'Plain, resized, and custom image markers',
      Icons.location_on,
      (_) => const MarkersScreen(),
    ),
    _DemoEntry(
      'Shapes',
      'Circles and polygons',
      Icons.hexagon_outlined,
      (_) => const ShapesScreen(),
    ),
    _DemoEntry(
      'Polylines',
      'Straight and multi-point paths',
      Icons.timeline,
      (_) => const PolylinesScreen(),
    ),
    _DemoEntry(
      'Routing',
      'Turn-by-turn route with distance & time',
      Icons.alt_route,
      (_) => const RoutingScreen(),
    ),
    _DemoEntry(
      'Search & Reverse-Geocode',
      'Place search and address lookup (Android only)',
      Icons.search,
      (_) => const SearchScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TPL Maps Plugin Demo')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final _DemoEntry entry = _entries[index];
          return ListTile(
            leading: Icon(entry.icon),
            title: Text(entry.title),
            subtitle: Text(entry.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: entry.builder),
              );
            },
          );
        },
      ),
    );
  }
}
