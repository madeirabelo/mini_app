import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';
import 'package:html/parser.dart' show parse;

class Province {
  final String id;
  final String name;

  Province({required this.id, required this.name});
}

class ExtendedPolygon extends Polygon {
  final String provinceId;
  final String uniqueId;

  ExtendedPolygon({
    required List<LatLng> points,
    required this.provinceId,
    required this.uniqueId,
    String? label,
    Color color = const Color(0xFF00FF00),
    double borderStrokeWidth = 0.0,
    Color borderColor = const Color(0xFFFFFF00),
    bool isFilled = false,
    List<List<LatLng>>? holePointsList,
  }) : super(
          points: points,
          label: label,
          color: color,
          borderStrokeWidth: borderStrokeWidth,
          borderColor: borderColor,
          isFilled: isFilled,
          holePointsList: holePointsList,
        );
}

class DepartamentoMapApp extends StatefulWidget {
  @override
  _DepartamentoMapAppState createState() => _DepartamentoMapAppState();
}

class _DepartamentoMapAppState extends State<DepartamentoMapApp> {
  final MapController _mapController = MapController();
  List<ExtendedPolygon> _polygons = [];
  List<ExtendedPolygon> _allDepartamentosPolygons = [];
  String? _tappedDepartamentoUniqueId;
  String _selectedDepartamentoUniqueId = 'All Departamentos';
  Province? _selectedProvince;

  final List<Province> provinces = [
    Province(id: '02', name: 'Ciudad Autónoma de Buenos Aires'),
    Province(id: '06', name: 'Buenos Aires'),
    Province(id: '10', name: 'Catamarca'),
    Province(id: '14', name: 'Córdoba'),
    Province(id: '18', name: 'Corrientes'),
    Province(id: '22', name: 'Chaco'),
    Province(id: '26', name: 'Chubut'),
    Province(id: '30', name: 'Entre Ríos'),
    Province(id: '34', name: 'Formosa'),
    Province(id: '38', name: 'Jujuy'),
    Province(id: '42', name: 'La Pampa'),
    Province(id: '46', name: 'La Rioja'),
    Province(id: '50', name: 'Mendoza'),
    Province(id: '54', name: 'Misiones'),
    Province(id: '58', name: 'Neuquén'),
    Province(id: '62', name: 'Río Negro'),
    Province(id: '66', name: 'Salta'),
    Province(id: '70', name: 'San Juan'),
    Province(id: '74', name: 'San Luis'),
    Province(id: '78', name: 'Santa Cruz'),
    Province(id: '82', name: 'Santa Fe'),
    Province(id: '86', name: 'Santiago del Estero'),
    Province(id: '90', name: 'Tucumán'),
    Province(id: '94', name: 'Tierra del Fuego, Antártida e Islas del Atlántico Sur'),
  ];

  @override
  void initState() {
    super.initState();
    _loadDepartamentosBoundary();
  }

  Future<void> _loadDepartamentosBoundary() async {
    final String geoJsonString = await rootBundle.loadString('assets/ign_departamento.json');
    final geoJsonData = json.decode(geoJsonString);

    final List<ExtendedPolygon> polygons = [];

    if (geoJsonData['features'] != null) {
      for (var feature in geoJsonData['features']) {
        final geometry = feature['geometry'];
        final properties = feature['properties'];
        String departamentoName = 'Unknown Departamento';
        String provinceId = '';

        if (properties['description'] != null) {
          var document = parse(properties['description']);
          var tdElements = document.querySelectorAll('td');
          for (var i = 0; i < tdElements.length - 1; i++) {
            if (tdElements[i].text.trim() == 'NAM') {
              departamentoName = tdElements[i + 1].text.trim();
            } else if (tdElements[i].text.trim() == 'IN1') {
              provinceId = tdElements[i + 1].text.trim().substring(0, 2);
            }
          }
        }

        if (departamentoName != 'Unknown Departamento') {
          final uniqueId = '$departamentoName-$provinceId';
          if (geometry['type'] == 'Polygon') {
            final List<LatLng> exteriorRing = [];
            for (var coordinate in geometry['coordinates'][0]) {
              exteriorRing.add(LatLng(coordinate[1].toDouble(), coordinate[0].toDouble()));
            }
            polygons.add(_createPolygon(exteriorRing, departamentoName, provinceId, uniqueId));
          } else if (geometry['type'] == 'MultiPolygon') {
            for (var singlePolygonCoordinates in geometry['coordinates']) {
              final List<LatLng> exteriorRing = [];
              for (var coordinate in singlePolygonCoordinates[0]) {
                exteriorRing.add(LatLng(coordinate[1].toDouble(), coordinate[0].toDouble()));
              }
              polygons.add(_createPolygon(exteriorRing, departamentoName, provinceId, uniqueId));
            }
          }
        }
      }
    }

    setState(() {
      _allDepartamentosPolygons = List.from(polygons);
      _polygons = List.from(polygons);
    });
  }

  ExtendedPolygon _createPolygon(List<LatLng> points, String departamentoName, String provinceId, String uniqueId, [List<List<LatLng>>? holePointsList]) {
    return ExtendedPolygon(
      points: points,
      provinceId: provinceId,
      uniqueId: uniqueId,
      holePointsList: holePointsList,
      color: Colors.blue.withOpacity(0.7),
      borderColor: Colors.black,
      borderStrokeWidth: 1,
      label: departamentoName,
      isFilled: true,
    );
  }

  void _handleTap(tapPosition, latlng) {
    for (var polygon in _polygons) {
      if (_isPointInPolygon(latlng, polygon.points)) {
        setState(() {
          _tappedDepartamentoUniqueId = polygon.uniqueId;
        });
        return;
      }
    }
    setState(() {
      _tappedDepartamentoUniqueId = null;
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
      return false;
    }

    double m = (aY - bY) / (aX - bX);
    double bee = (-aX) * m + aY;
    double x = (pY - bee) / m;

    return x > pX;
  }

  void _zoomToSelected(List<ExtendedPolygon> polygons) {
    if (polygons.isEmpty) return;

    LatLngBounds bounds;
    if (polygons.length == 1) {
      bounds = LatLngBounds.fromPoints(polygons.first.points);
    } else {
      List<LatLng> allPoints = [];
      for (var p in polygons) {
        allPoints.addAll(p.points);
      }
      bounds = LatLngBounds.fromPoints(allPoints);
    }

    _mapController.fitBounds(bounds, options: FitBoundsOptions(padding: EdgeInsets.all(20.0)));
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter polygons based on the selected province
    final filteredPolygons = _allDepartamentosPolygons
        .where((p) => _selectedProvince == null || p.provinceId == _selectedProvince!.id);

    // 2. Create a map to get unique departments by their uniqueId, mapping uniqueId to label.
    final uniqueDepartments = <String, String>{};
    for (final polygon in filteredPolygons) {
      if (polygon.label != null) {
        uniqueDepartments[polygon.uniqueId] = polygon.label!;
      }
    }

    // 3. Convert the map to a list of DropdownMenuItem widgets and sort it by label.
    final departamentoItems = uniqueDepartments.entries.map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
      );
    }).toList()
      ..sort((a, b) => a.child.toString().compareTo(b.child.toString()));

    // 4. Add the 'All Departamentos' option at the beginning.
    departamentoItems.insert(
      0,
      DropdownMenuItem<String>(
        value: 'All Departamentos',
        child: Text('All Departamentos'),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Map of Argentina Departamentos'),
      ),
      body: Column(
        children: [
          // Province Dropdown
          DropdownButton<Province>(
            hint: Text('Select Province'),
            value: _selectedProvince,
            onChanged: (Province? newValue) {
              setState(() {
                _selectedProvince = newValue;
                _selectedDepartamentoUniqueId = 'All Departamentos';
                if (newValue == null) {
                  _polygons = List.from(_allDepartamentosPolygons);
                } else {
                  _polygons = _allDepartamentosPolygons.where((p) => p.provinceId == newValue.id).toList();
                }
                _zoomToSelected(_polygons);
              });
            },
            items: provinces.map<DropdownMenuItem<Province>>((Province province) {
              return DropdownMenuItem<Province>(
                value: province,
                child: Text(province.name, style: TextStyle(fontSize: 12)),
              );
            }).toList(),
          ),
          // Department Dropdown
          Container(
            width: 300, // Increased width for better display
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                isExpanded: true,
                value: _selectedDepartamentoUniqueId,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDepartamentoUniqueId = newValue!;
                    final newPolygons = <ExtendedPolygon>[];
                    if (_selectedDepartamentoUniqueId == 'All Departamentos') {
                      if (_selectedProvince == null) {
                        _polygons = List.from(_allDepartamentosPolygons);
                      } else {
                        _polygons = _allDepartamentosPolygons.where((p) => p.provinceId == _selectedProvince!.id).toList();
                      }
                    } else {
                      for (var p in _allDepartamentosPolygons) {
                        if (p.provinceId == _selectedProvince?.id) {
                          final color = p.uniqueId == _selectedDepartamentoUniqueId ? Colors.red.withOpacity(0.7) : Colors.blue.withOpacity(0.7);
                          newPolygons.add(
                            ExtendedPolygon(
                              points: p.points,
                              provinceId: p.provinceId,
                              uniqueId: p.uniqueId,
                              label: p.label,
                              color: color,
                              borderColor: p.borderColor,
                              borderStrokeWidth: p.borderStrokeWidth,
                              isFilled: p.isFilled,
                              holePointsList: p.holePointsList,
                            ),
                          );
                        }
                      }
                      _polygons = newPolygons;
                    }
                    _zoomToSelected(_polygons);
                  });
                },
                items: departamentoItems,
              ),
            ),
          ),
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(-38.4161, -63.6167),
                zoom: 4.0,
                onTap: _handleTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                KeyedSubtree(
                  key: ValueKey(_polygons.toString()),
                  child: PolygonLayer(polygons: _polygons),
                ),
                if (_tappedDepartamentoUniqueId != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _getPolygonCenter(_tappedDepartamentoUniqueId!),
                        child: Container(
                          child: Text(_getPolygonLabel(_tappedDepartamentoUniqueId!)!),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LatLng _getPolygonCenter(String uniqueId) {
    final polygon = _allDepartamentosPolygons.firstWhere((p) => p.uniqueId == uniqueId);
    double lat = 0;
    double lng = 0;
    for (var point in polygon.points) {
      lat += point.latitude;
      lng += point.longitude;
    }
    return LatLng(lat / polygon.points.length, lng / polygon.points.length);
  }

  String? _getPolygonLabel(String uniqueId) {
    final polygon = _allDepartamentosPolygons.firstWhere((p) => p.uniqueId == uniqueId);
    return polygon.label;
  }
}