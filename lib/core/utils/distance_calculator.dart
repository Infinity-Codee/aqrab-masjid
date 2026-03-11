import 'dart:math';

class DistanceCalculator {
  static double distanceInKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(toLat - fromLat);
    final dLng = _degToRad(toLng - fromLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(fromLat)) *
            cos(_degToRad(toLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double degree) => degree * pi / 180.0;
}
