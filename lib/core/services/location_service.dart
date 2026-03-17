import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Describes how the location was obtained.
enum LocationSource {
  gps,
  network,
  lastKnown,
}

/// Wraps a [Position] with metadata about how it was obtained.
class LocationResult {
  const LocationResult({
    required this.position,
    required this.source,
  });

  final Position position;
  final LocationSource source;
}

/// Robust location service that works reliably on real devices AND emulators.
///
/// Strategy (progressive fallback):
/// 1. Try a direct fix with [LocationAccuracy.high] (15 s timeout).
/// 2. If that fails or is inaccurate, open a position stream for up to 20 s.
/// 3. If both fail, use [getLastKnownPosition] filtered by staleness (≤ 5 min).
///
/// On Android emulators the Fused Location Provider often hangs because there
/// is no real GPS hardware, so when an emulator is detected we fall back to
/// the legacy [LocationManager] via [AndroidSettings.forceLocationManager].
class LocationService {
  // ─── tunables ───────────────────────────────────────────────
  static const Duration _directTimeout = Duration(seconds: 15);
  static const Duration _streamTimeout = Duration(seconds: 20);
  static const double _goodAccuracyMeters = 50;
  static const double _acceptableAccuracyMeters = 150;
  static const Duration _maxLastKnownAge = Duration(minutes: 5);

  bool? _isRunningOnEmulator;

  // ─── public API ─────────────────────────────────────────────

  /// Returns the best location available, throwing a user-friendly [Exception]
  /// if it is truly impossible (GPS off + permission denied + no last-known).
  Future<LocationResult> getCurrentLocation() async {
    // 1. Check if location services are enabled.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Attempt to open settings so the user can enable GPS.
      await Geolocator.openLocationSettings();
      // Re-check after the user comes back.
      final enabledAfter = await Geolocator.isLocationServiceEnabled();
      if (!enabledAfter) {
        throw Exception('خدمة الموقع غير مفعلة. فعّل GPS ثم أعد المحاولة.');
      }
    }

    // 2. Handle permissions.
    await _ensurePermission();

    // 3. Detect emulator (cached after first call).
    _isRunningOnEmulator ??= await _detectEmulator();
    if (_isRunningOnEmulator!) {
      debugPrint('[LocationService] Running on emulator — using fallback strategy.');
    }

    // 4. Try direct fix.
    final directResult = await _tryDirectFix();
    if (directResult != null &&
        directResult.position.accuracy <= _goodAccuracyMeters) {
      debugPrint(
        '[LocationService] Direct fix: '
        '(${directResult.position.latitude}, ${directResult.position.longitude}) '
        'accuracy=${directResult.position.accuracy}m',
      );
      return directResult;
    }

    // 5. Try stream fix for a more accurate reading.
    final streamResult = await _tryStreamFix();
    if (streamResult != null) {
      debugPrint(
        '[LocationService] Stream fix: '
        '(${streamResult.position.latitude}, ${streamResult.position.longitude}) '
        'accuracy=${streamResult.position.accuracy}m',
      );
      // Prefer stream over a poor direct fix.
      if (directResult == null ||
          streamResult.position.accuracy < directResult.position.accuracy) {
        return streamResult;
      }
    }

    // 6. Return direct fix even if accuracy is mediocre.
    if (directResult != null) {
      debugPrint('[LocationService] Returning mediocre direct fix.');
      return directResult;
    }

    // 7. Last resort: cached position (filtered by age).
    final lastKnown = await _tryLastKnown();
    if (lastKnown != null) {
      debugPrint('[LocationService] Using last-known position.');
      return lastKnown;
    }

    throw Exception(
      'تعذر تحديد موقعك. تأكد أن GPS مفعّل وأنك في مكان مفتوح ثم أعد المحاولة.',
    );
  }

  // ─── permission handling ────────────────────────────────────

  Future<void> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'تم رفض إذن الموقع. يرجى السماح بالوصول للموقع من إعدادات التطبيق.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      // Tell the user they need to go to Settings manually.
      await Geolocator.openAppSettings();
      throw Exception(
        'إذن الموقع مرفوض نهائياً. فعّل الإذن من إعدادات الجهاز ثم أعد المحاولة.',
      );
    }
  }

  // ─── platform-specific settings ─────────────────────────────

  LocationSettings _buildSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        // On emulators, Fused Location Provider may hang because there is no
        // real GPS hardware.  Force the legacy LocationManager instead.
        forceLocationManager: _isRunningOnEmulator ?? false,
        // Faster initial update.
        intervalDuration: const Duration(seconds: 1),
      );
    }

    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: 0,
        activityType: ActivityType.other,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
      );
    }

    // Fallback for other platforms (web, desktop, etc.)
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: 0,
    );
  }

  // ─── strategy: direct position ──────────────────────────────

  Future<LocationResult?> _tryDirectFix() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _buildSettings(),
      ).timeout(_directTimeout);

      return LocationResult(
        position: position,
        source: position.accuracy <= _goodAccuracyMeters
            ? LocationSource.gps
            : LocationSource.network,
      );
    } on TimeoutException {
      debugPrint('[LocationService] Direct fix timed out.');
      return null;
    } catch (e) {
      debugPrint('[LocationService] Direct fix error: $e');
      return null;
    }
  }

  // ─── strategy: position stream ──────────────────────────────

  Future<LocationResult?> _tryStreamFix() async {
    StreamSubscription<Position>? subscription;
    Position? best;
    var samples = 0;
    final completer = Completer<LocationResult?>();

    try {
      final stream = Geolocator.getPositionStream(
        locationSettings: _buildSettings(),
      );

      subscription = stream.listen(
        (position) {
          samples++;
          debugPrint(
            '[LocationService] Stream sample #$samples: '
            'accuracy=${position.accuracy}m',
          );

          // Keep the best reading.
          if (best == null || position.accuracy < best!.accuracy) {
            best = position;
          }

          // Return immediately if accuracy is good enough.
          if (position.accuracy <= _goodAccuracyMeters) {
            if (!completer.isCompleted) {
              completer.complete(LocationResult(
                position: position,
                source: LocationSource.gps,
              ));
            }
            return;
          }

          // After 3 samples, accept "acceptable" accuracy.
          if (samples >= 3 && position.accuracy <= _acceptableAccuracyMeters) {
            if (!completer.isCompleted) {
              completer.complete(LocationResult(
                position: position,
                source: LocationSource.network,
              ));
            }
          }
        },
        onError: (Object error) {
          debugPrint('[LocationService] Stream error: $error');
          if (!completer.isCompleted) {
            completer.complete(
              best != null
                  ? LocationResult(
                      position: best!,
                      source: LocationSource.network,
                    )
                  : null,
            );
          }
        },
        cancelOnError: true,
      );

      // Timeout guard.
      Future.delayed(_streamTimeout, () {
        if (!completer.isCompleted) {
          completer.complete(
            best != null
                ? LocationResult(
                    position: best!,
                    source: LocationSource.network,
                  )
                : null,
          );
        }
      });

      return await completer.future;
    } catch (e) {
      debugPrint('[LocationService] Stream setup error: $e');
      return null;
    } finally {
      // CRITICAL: always cancel the subscription to stop GPS updates.
      await subscription?.cancel();
      debugPrint('[LocationService] Stream subscription cancelled.');
    }
  }

  // ─── strategy: last known position ──────────────────────────

  Future<LocationResult?> _tryLastKnown() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      // Filter out stale positions.
      final age = DateTime.now().difference(position.timestamp);
      if (age > _maxLastKnownAge) {
        debugPrint(
          '[LocationService] Last-known position too old (${age.inMinutes} min). Discarded.',
        );
        return null;
      }

      return LocationResult(
        position: position,
        source: LocationSource.lastKnown,
      );
    } catch (e) {
      debugPrint('[LocationService] Last-known error: $e');
      return null;
    }
  }

  // ─── emulator detection ─────────────────────────────────────

  Future<bool> _detectEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        return !android.isPhysicalDevice;
      }

      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        return !ios.isPhysicalDevice;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
