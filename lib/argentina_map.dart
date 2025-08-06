import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class ArgentinaMapApp extends StatefulWidget {
  @override
  _ArgentinaMapAppState createState() => _ArgentinaMapAppState();
}

class _ArgentinaMapAppState extends State<ArgentinaMapApp> {
  List<Polygon> _polygons = [];

  @override
  void initState() {
    super.initState();
    _loadArgentinaBoundary();
  }

  Future<void> _loadArgentinaBoundary() async {
    final String geoJsonString = await rootBundle.loadString('assets/argentina_boundary.geojson');
    final geoJsonData = json.decode(geoJsonString);

    final List<LatLng> points = [];
    for (var coordinate in geoJsonData['features'][0]['geometry']['coordinates'][0]) {
      points.add(LatLng(coordinate[1], coordinate[0]));
    }

    setState(() {
      _polygons.add(
        Polygon(
          points: points,
          color: Colors.blue.withOpacity(0.5),
          borderColor: Colors.transparent,
          borderStrokeWidth: 2,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map of Argentina'),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(-38.4161, -63.6167),
          zoom: 4.0,
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
