import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;

class ArgentinaProvinceMapApp extends StatefulWidget {
  @override
  _ArgentinaProvinceMapAppState createState() => _ArgentinaProvinceMapAppState();
}

class _ArgentinaProvinceMapAppState extends State<ArgentinaProvinceMapApp> {
  List<Polygon> _polygons = [];
  List<Polygon> _allProvincesPolygons = [];
  String? _tappedProvince;
  String _selectedProvince = 'All Provinces';

  @override
  void initState() {
    super.initState();
    _loadProvincesBoundary();
  }

  Future<void> _loadProvincesBoundary() async {
    final String geoJsonString = await rootBundle.loadString('assets/ignprovincia.json');
    final geoJsonData = json.decode(geoJsonString);

    final List<Polygon> polygons = [];
    final random = Random();

    if (geoJsonData['features'] != null) {
      for (var feature in geoJsonData['features']) {
        final geometry = feature['geometry'];
        final properties = feature['properties'];
        String provinceName = 'Unknown Province';

        // Try to parse from description HTML
        if (properties['description'] != null) {
          final document = parse(properties['description']);
          final tableCells = document.querySelectorAll('td');
          for (var i = 0; i < tableCells.length; i++) {
            if (tableCells[i].text.trim() == 'NAM' && i + 1 < tableCells.length) {
              provinceName = tableCells[i + 1].text.trim();
              break;
            }
          }
        }

        // Fallback to other properties if HTML parsing fails or NAM is not found
        if (provinceName == 'Unknown Province') {
          provinceName = properties['nombre_completo'] ?? properties['nombre'] ?? 'Unknown Province';
        }

        if (geometry['type'] == 'Polygon') {
          final List<LatLng> exteriorRing = [];
          final List<List<LatLng>> interiorRings = [];

          // Exterior ring
          for (var coordinate in geometry['coordinates'][0]) {
            exteriorRing.add(LatLng(coordinate[1].toDouble(), coordinate[0].toDouble()));
          }

          // Interior rings (holes)
          for (int i = 1; i < geometry['coordinates'].length; i++) {
            final List<LatLng> holeRing = [];
            for (var coordinate in geometry['coordinates'][i]) {
              holeRing.add(LatLng(coordinate[1].toDouble(), coordinate[0].toDouble()));
            }
            interiorRings.add(holeRing);
          }
          polygons.add(_createPolygon(exteriorRing, provinceName, random, interiorRings.isNotEmpty ? interiorRings : null));
        } else if (geometry['type'] == 'MultiPolygon') {
          for (var singlePolygonCoordinates in geometry['coordinates']) {
            final List<LatLng> exteriorRing = [];
            final List<List<LatLng>> interiorRings = [];

            // Exterior ring of this single polygon
            for (var coordinate in singlePolygonCoordinates[0]) {
              exteriorRing.add(LatLng(coordinate[1].toDouble(), coordinate[0].toDouble()));
            }

            // Interior rings (holes) of this single polygon
            for (int i = 1; i < singlePolygonCoordinates.length; i++) {
              final List<LatLng> holeRing = [];
              for (var coordinate in singlePolygonCoordinates[i]) {
                holeRing.add(LatLng(coordinate[1].toDouble(), coordinate[0].toDouble()));
              }
              interiorRings.add(holeRing);
            }
            polygons.add(_createPolygon(exteriorRing, provinceName, random, interiorRings.isNotEmpty ? interiorRings : null));
          }
        }
      }
    }

    setState(() {
      _allProvincesPolygons = List.from(polygons);
      _polygons = List.from(polygons);
    });
  }

  Polygon _createPolygon(List<LatLng> points, String provinceName, Random random, [List<List<LatLng>>? holePointsList]) {
    return Polygon(
      points: points,
      holePointsList: holePointsList,
      color: Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        0.7,
      ),
      borderColor: Colors.black,
      borderStrokeWidth: 1,
      label: provinceName,
      isFilled: true,
    );
  }

  void _handleTap(tapPosition, latlng) {
    for (var polygon in _polygons) {
      if (_isPointInPolygon(latlng, polygon.points)) {
        setState(() {
          _tappedProvince = polygon.label;
        });
        return;
      }
    }
    setState(() {
      _tappedProvince = null;
    });
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      if (_rayCastIntersect(point, polygon[j], polygon[j + 1])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1; // odd = inside, even = outside;
  }

  bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double aY = vertA.latitude;
    double bY = vertB.latitude;
    double aX = vertA.longitude;
    double bX = vertB.longitude;
    double pY = point.latitude;
    double pX = point.longitude;

    if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
      return false; // point is not between the y coordinates of the segment
    }

    double m = (aY - bY) / (aX - bX); // Rise over run
    double bee = (-aX) * m + aY; // y = mx + b
    double x = (pY - bee) / m; // algebra

    return x > pX;
  }

  @override
  Widget build(BuildContext context) {
    List<String> provinceNames = ['All Provinces'] + _allProvincesPolygons.map((p) => p.label).where((label) => label != null).cast<String>().toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Map of Argentina Provinces'),
        actions: [
          Container(
            width: 150, // Reduced width to prevent overflow
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                isExpanded: true,
                value: _selectedProvince,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedProvince = newValue!;
                    if (_selectedProvince == 'All Provinces') {
                      _polygons = List.from(_allProvincesPolygons);
                    } else {
                      _polygons = _allProvincesPolygons.where((p) => p.label == _selectedProvince).toList();
                    }
                  });
                },
                items: provinceNames.map<DropdownMenuItem<String>>((String value) {
                  // Truncate long province names
                  String displayValue = value;
                  if (value.length > 20) {
                    displayValue = value.substring(0, 17) + '...';
                  }
                  
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      displayValue,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(-38.4161, -63.6167),
          zoom: 4.0,
          onTap: _handleTap,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          PolygonLayer(polygons: _polygons),
          if (_tappedProvince != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: _getPolygonCenter(_tappedProvince!),
                  child: Container(
                    child: Text(_tappedProvince!),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  LatLng _getPolygonCenter(String provinceName) {
    final polygon = _allProvincesPolygons.firstWhere((p) => p.label == provinceName);
    double lat = 0;
    double lng = 0;
    for (var point in polygon.points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / polygon.points.length, lng / polygon.points.length);
  }
}