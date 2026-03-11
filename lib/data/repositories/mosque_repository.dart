import '../datasource/mosque_api_data.dart';
import '../datasource/mosque_data.dart';
import '../models/mosque_model.dart';

enum MosqueSourceType { onlineNearby, localJson }

class MosqueFetchResult {
  const MosqueFetchResult({required this.mosques, required this.sourceType});

  final List<MosqueModel> mosques;
  final MosqueSourceType sourceType;
}

class MosqueRepository {
  MosqueRepository({
    MosqueDataSource? localDataSource,
    MosqueApiDataSource? apiDataSource,
  }) : _localDataSource = localDataSource ?? MosqueDataSource(),
       _apiDataSource = apiDataSource ?? MosqueApiDataSource();

  final MosqueDataSource _localDataSource;
  final MosqueApiDataSource _apiDataSource;

  Future<MosqueFetchResult> getMosques({
    required double userLat,
    required double userLng,
  }) async {
    try {
      final onlineMosques = await _apiDataSource.fetchNearbyMosques(
        latitude: userLat,
        longitude: userLng,
      );
      if (onlineMosques.isNotEmpty) {
        return MosqueFetchResult(
          mosques: onlineMosques,
          sourceType: MosqueSourceType.onlineNearby,
        );
      }
    } catch (_) {
      // Ignore network/API issues and fallback to local JSON data.
    }

    final localMosques = await _localDataSource.loadMosques();
    return MosqueFetchResult(
      mosques: localMosques,
      sourceType: MosqueSourceType.localJson,
    );
  }
}
