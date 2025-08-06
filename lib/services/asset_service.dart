import 'package:flutter/services.dart' show rootBundle;

class AssetService {
  Future<String> loadGeoJson(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (e) {
      throw Exception('Failed to load GeoJSON from assets: $e');
    }
  }
}
