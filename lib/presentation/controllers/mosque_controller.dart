import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/location_service.dart';
import '../../core/utils/distance_calculator.dart';
import '../../data/models/mosque_model.dart';
import '../../data/repositories/mosque_repository.dart';

/// Holds a mosque together with its distance from the user.
class MosqueWithDistance {
  const MosqueWithDistance({required this.mosque, required this.distanceKm});

  final MosqueModel mosque;
  final double distanceKm;
}

class MosqueController extends ChangeNotifier {
  MosqueController({
    LocationService? locationService,
    MosqueRepository? mosqueRepository,
  }) : _locationService = locationService ?? LocationService(),
       _mosqueRepository = mosqueRepository ?? MosqueRepository();

  final LocationService _locationService;
  final MosqueRepository _mosqueRepository;

  bool isLoading = true;
  String? errorMessage;
  String? locationNotice;
  Position? userPosition;
  double? locationAccuracyMeters;
  LocationSource? locationSource;
  List<MosqueModel> mosques = <MosqueModel>[];

  /// The nearest mosque and its distance.
  MosqueModel? nearestMosque;
  double? nearestDistanceKm;

  /// 2nd and 3rd closest mosques for the horizontal list.
  List<MosqueWithDistance> nearbyMosques = <MosqueWithDistance>[];

  /// Whether the data was fetched online (true) or from local JSON (false).
  bool isOnline = false;

  Future<void> loadNearestMosque() async {
    isLoading = true;
    errorMessage = null;
    locationNotice = null;
    locationSource = null;
    notifyListeners();

    try {
      final result = await _locationService.getCurrentLocation();
      userPosition = result.position;
      locationAccuracyMeters = result.position.accuracy;
      locationSource = result.source;

      // Warn if the location source is not GPS.
      if (result.source == LocationSource.lastKnown) {
        locationNotice =
            'تم استخدام آخر موقع معروف لأن تحديد الموقع الحالي تعذر. '
            'النتائج قد لا تكون دقيقة.';
      } else if (result.position.accuracy > 100) {
        locationNotice =
            'دقة الموقع الحالي منخفضة (±${result.position.accuracy.toStringAsFixed(0)} م). '
            'انتقل لمكان مفتوح لتحسين الدقة.';
      }

      final mosqueResult = await _mosqueRepository.getMosques(
        userLat: userPosition!.latitude,
        userLng: userPosition!.longitude,
      );
      mosques = mosqueResult.mosques;
      isOnline = mosqueResult.sourceType == MosqueSourceType.onlineNearby;

      if (mosques.isEmpty) {
        throw Exception('لا توجد بيانات جوامع.');
      }

      // Sort all mosques by distance.
      final sorted = _sortByDistance(
        fromLat: userPosition!.latitude,
        fromLng: userPosition!.longitude,
        mosquesList: mosques,
      );

      // Nearest (hero)
      nearestMosque = sorted.first.mosque;
      nearestDistanceKm = sorted.first.distanceKm;

      // 2nd and 3rd for horizontal list
      nearbyMosques =
          sorted.length > 1
              ? sorted.sublist(1, sorted.length.clamp(0, 4))
              : <MosqueWithDistance>[];

      if (!isOnline && nearestDistanceKm! > 5) {
        locationNotice =
            'تعذر جلب جوامع قريبة من الإنترنت، '
            'فتم استخدام البيانات المحلية وقد تكون بعيدة عن موقعك.';
      } else if (nearestDistanceKm! > 120) {
        locationNotice =
            'الموقع الحالي يبدو بعيداً جداً عن بيانات الجوامع. '
            'تحقق من تفعيل GPS أو اضبط الموقع يدوياً إذا كنت تستخدم المحاكي.';
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Human-readable label for the location source.
  String get locationSourceLabel {
    switch (locationSource) {
      case LocationSource.gps:
        return 'GPS';
      case LocationSource.network:
        return 'الشبكة';
      case LocationSource.lastKnown:
        return 'آخر موقع معروف';
      case null:
        return '';
    }
  }

  Future<void> refresh() => loadNearestMosque();

  List<MosqueWithDistance> _sortByDistance({
    required double fromLat,
    required double fromLng,
    required List<MosqueModel> mosquesList,
  }) {
    final withDistances = mosquesList.map((mosque) {
      final distance = DistanceCalculator.distanceInKm(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: mosque.latitude,
        toLng: mosque.longitude,
      );
      return MosqueWithDistance(mosque: mosque, distanceKm: distance);
    }).toList();

    withDistances.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return withDistances;
  }
}
