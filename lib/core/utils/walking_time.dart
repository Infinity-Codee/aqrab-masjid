import '../constants/app_constants.dart';

class WalkingTime {
  /// Converts distance in km to a human-readable Arabic walking-time string.
  static String fromKm(double distanceKm) {
    final totalMinutes =
        (distanceKm / AppConstants.walkingSpeedKmH * 60).ceil();

    if (totalMinutes <= 0) return 'أقل من دقيقة';
    if (totalMinutes == 1) return 'دقيقة واحدة';
    if (totalMinutes == 2) return 'دقيقتان';
    if (totalMinutes >= 3 && totalMinutes <= 10) return '$totalMinutes دقائق';
    if (totalMinutes > 10 && totalMinutes < 60) return '$totalMinutes دقيقة';

    final hours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;
    if (hours == 1 && remainingMinutes == 0) return 'ساعة واحدة';
    if (hours == 1) return 'ساعة و $remainingMinutes دقيقة';
    if (hours == 2 && remainingMinutes == 0) return 'ساعتان';
    return '$hours ساعات و $remainingMinutes دقيقة';
  }

  /// Converts distance in km to meters string (e.g. "140 متر").
  static String distanceDisplay(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters متر';
    }
    return '${distanceKm.toStringAsFixed(1)} كم';
  }
}
