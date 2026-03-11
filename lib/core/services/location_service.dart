import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  static const Duration _fixTimeout = Duration(seconds: 12);
  static const double _targetAccuracyMeters = 40;

  Future<Position> getCurrentLocation() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw Exception('خدمة الموقع غير مفعلة. فعّل GPS ثم أعد المحاولة.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('تم رفض إذن الموقع.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('إذن الموقع مرفوض نهائياً من الإعدادات.');
    }

    Position? directFix;
    try {
      directFix = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      ).timeout(_fixTimeout);
    } on TimeoutException {
      directFix = await Geolocator.getLastKnownPosition();
    }

    if (directFix != null && directFix.accuracy <= _targetAccuracyMeters) {
      return directFix;
    }

    final streamedFix = await _getFixFromStream();
    if (streamedFix != null) {
      return streamedFix;
    }

    if (directFix != null) {
      return directFix;
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      return lastKnown;
    }

    throw Exception('تعذر تثبيت موقع دقيق. أعد المحاولة في مكان مفتوح.');
  }

  Future<Position?> _getFixFromStream() async {
    final stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    );

    Position? latest;
    var samples = 0;

    try {
      await for (final position in stream.timeout(_fixTimeout)) {
        latest = position;
        samples += 1;

        if (position.accuracy <= _targetAccuracyMeters) {
          return position;
        }

        if (samples >= 3 && position.accuracy <= 120) {
          return position;
        }
      }
    } on TimeoutException {
      return latest;
    }

    return latest;
  }
}
