import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mosque_model.dart';

class MosqueApiDataSource {
  MosqueApiDataSource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<MosqueModel>> fetchNearbyMosques({
    required double latitude,
    required double longitude,
    double radiusMeters = 15000,
    int limit = 80,
  }) async {
    final query =
        '''
[out:json][timeout:25];
(
  node["amenity"="place_of_worship"]["religion"~"muslim|islam",i](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="place_of_worship"]["religion"~"muslim|islam",i](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="place_of_worship"]["religion"~"muslim|islam",i](around:$radiusMeters,$latitude,$longitude);

  node["building"="mosque"](around:$radiusMeters,$latitude,$longitude);
  way["building"="mosque"](around:$radiusMeters,$latitude,$longitude);
  relation["building"="mosque"](around:$radiusMeters,$latitude,$longitude);
);
out center $limit;
''';

    final uri = Uri.https('overpass-api.de', '/api/interpreter', {
      'data': query,
    });

    final response = await _client
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'aqrab-masjid-app/1.0',
          },
        )
        .timeout(const Duration(seconds: 18));

    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الجوامع القريبة من الإنترنت.');
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
      throw Exception('استجابة مزود بيانات الجوامع غير صالحة.');
    }

    final elements = decoded['elements'] as List;
    final mosques = <MosqueModel>[];
    final seen = <String>{};

    for (final rawElement in elements) {
      if (rawElement is! Map<String, dynamic>) {
        continue;
      }

      final point = _extractCoordinates(rawElement);
      if (point == null) {
        continue;
      }

      final tags =
          (rawElement['tags'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final name = _readName(tags);
      final address = _readAddress(tags);
      final type = rawElement['type']?.toString() ?? 'unknown';
      final id = rawElement['id']?.toString() ?? '${point.lat},${point.lng}';
      final uniqueKey = '$type-$id-${point.lat}-${point.lng}';
      if (!seen.add(uniqueKey)) {
        continue;
      }

      mosques.add(
        MosqueModel(
          id: uniqueKey.hashCode,
          name: name,
          latitude: point.lat,
          longitude: point.lng,
          address: address,
        ),
      );
    }

    return mosques;
  }

  _LatLng? _extractCoordinates(Map<String, dynamic> element) {
    final lat = _toDouble(element['lat']);
    final lng = _toDouble(element['lon']);
    if (lat != null && lng != null) {
      return _LatLng(lat: lat, lng: lng);
    }

    final center = element['center'];
    if (center is Map<String, dynamic>) {
      final centerLat = _toDouble(center['lat']);
      final centerLng = _toDouble(center['lon']);
      if (centerLat != null && centerLng != null) {
        return _LatLng(lat: centerLat, lng: centerLng);
      }
    }

    return null;
  }

  String _readName(Map<String, dynamic> tags) {
    final nameAr = tags['name:ar']?.toString().trim();
    final name = tags['name']?.toString().trim();
    if (nameAr != null && nameAr.isNotEmpty) {
      return nameAr;
    }
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'جامع قريب';
  }

  String _readAddress(Map<String, dynamic> tags) {
    final full = tags['addr:full']?.toString().trim();
    if (full != null && full.isNotEmpty) {
      return full;
    }

    final parts = <String>[
      tags['addr:street']?.toString().trim() ?? '',
      tags['addr:housenumber']?.toString().trim() ?? '',
      tags['addr:city']?.toString().trim() ?? '',
      tags['addr:district']?.toString().trim() ?? '',
    ].where((part) => part.isNotEmpty).toList(growable: false);

    if (parts.isEmpty) {
      return 'قريب من موقعك الحالي';
    }
    return parts.join(' - ');
  }

  double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

class _LatLng {
  const _LatLng({required this.lat, required this.lng});

  final double lat;
  final double lng;
}
