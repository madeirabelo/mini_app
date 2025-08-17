import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class BarriosCorrientesMapApp extends StatefulWidget {
  @override
  _BarriosCorrientesMapAppState createState() => _BarriosCorrientesMapAppState();
}

class _BarriosCorrientesMapAppState extends State<BarriosCorrientesMapApp> {
  final MapController _mapController = MapController();
  List<Polygon> _polygons = [];

  @override
  void initState() {
    super.initState();
    _loadBarriosBoundary();
  }

  Future<void> _loadBarriosBoundary() async {
    final String geoJsonString = await rootBundle.loadString('assets/barrios_corrientes.geojson');
    final geoJsonData = json.decode(geoJsonString);

    final List<Polygon> polygons = [];

    if (geoJsonData['features'] != null) {
      for (var feature in geoJsonData['features']) {
        final geometry = feature['geometry'];
        final properties = feature['properties'];
        String barrioName = properties['barrio'] ?? 'Unknown';

        if (geometry['type'] == 'Polygon') {
          final List<LatLng> points = [];
          for (var point in geometry['coordinates'][0]) {
            points.add(LatLng(point[1], point[0]));
          }
          polygons.add(
            Polygon(
              points: points,
              color: Colors.blue.withOpacity(0.7),
              borderColor: Colors.black,
              borderStrokeWidth: 1,
              isFilled: true,
              label: barrioName,
            ),
          );
        }
      }
    }

    setState(() {
      _polygons = polygons;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barrios de Corrientes'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: LatLng(-27.467, -58.833),
          zoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          PolygonLayer(polygons: _polygons),
        ],
      ),
    );
  }
}
