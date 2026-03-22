import '../../data/models/mosque_model.dart';
import 'platform_url_launcher.dart';

class MapService {
  static Future<void> openDirections({
    required MosqueModel mosque,
    double? originLat,
    double? originLng,
  }) async {
    final query = <String, String>{
      'api': '1',
      'destination': '${mosque.latitude},${mosque.longitude}',
      'travelmode': 'driving',
    };

    if (originLat != null && originLng != null) {
      query['origin'] = '$originLat,$originLng';
    }

    final uri = Uri.https('www.google.com', '/maps/dir/', query);
    if (!await PlatformUrlLauncher.openExternalUrl(uri)) {
      throw Exception('تعذر فتح الاتجاهات في الخرائط.');
    }
  }

  static Future<void> openMosqueLocation(MosqueModel mosque) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${mosque.latitude},${mosque.longitude}',
    });

    if (!await PlatformUrlLauncher.openExternalUrl(uri)) {
      throw Exception('تعذر فتح موقع الجامع على الخريطة.');
    }
  }
}
