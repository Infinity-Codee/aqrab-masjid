import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/location_service.dart';
import '../../core/utils/distance_calculator.dart';
import '../../data/models/mosque_model.dart';
import '../../data/repositories/mosque_repository.dart';

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
  List<MosqueModel> mosques = <MosqueModel>[];
  MosqueModel? nearestMosque;
  double? nearestDistanceKm;

  Future<void> loadNearestMosque() async {
    isLoading = true;
    errorMessage = null;
    locationNotice = null;
    notifyListeners();

    try {
      userPosition = await _locationService.getCurrentLocation();
      locationAccuracyMeters = userPosition?.accuracy;
      final mosqueResult = await _mosqueRepository.getMosques(
        userLat: userPosition!.latitude,
        userLng: userPosition!.longitude,
      );
      mosques = mosqueResult.mosques;

      if (mosques.isEmpty) {
        throw Exception('لا توجد بيانات جوامع.');
      }

      final nearest = _findNearest(
        fromLat: userPosition!.latitude,
        fromLng: userPosition!.longitude,
        mosquesList: mosques,
      );
      nearestMosque = nearest.mosque;
      nearestDistanceKm = nearest.distanceKm;

      if (mosqueResult.sourceType == MosqueSourceType.localJson &&
          nearestDistanceKm! > 5) {
        locationNotice =
            'تعذر جلب جوامع قريبة من الإنترنت الآن، '
            'فتم استخدام البيانات المحلية وقد تكون بعيدة عن موقعك.';
      } else if (nearestDistanceKm! > 120) {
        locationNotice =
            'الموقع الحالي يبدو بعيداً عن بيانات الجوامع. إذا كنت تستخدم المحاكي، '
            'اضبط الموقع من قائمة Simulator > Features > Location.';
      }
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadNearestMosque();

  _NearestResult _findNearest({
    required double fromLat,
    required double fromLng,
    required List<MosqueModel> mosquesList,
  }) {
    final first = mosquesList.first;
    var bestMosque = first;
    var bestDistance = DistanceCalculator.distanceInKm(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: first.latitude,
      toLng: first.longitude,
    );

    for (final mosque in mosquesList.skip(1)) {
      final distance = DistanceCalculator.distanceInKm(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: mosque.latitude,
        toLng: mosque.longitude,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        bestMosque = mosque;
      }
    }

    return _NearestResult(mosque: bestMosque, distanceKm: bestDistance);
  }
}

class _NearestResult {
  const _NearestResult({required this.mosque, required this.distanceKm});

  final MosqueModel mosque;
  final double distanceKm;
}
