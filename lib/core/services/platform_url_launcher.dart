import 'package:flutter/services.dart';

class PlatformUrlLauncher {
  PlatformUrlLauncher._();

  static const MethodChannel _channel = MethodChannel('aqrab_masjid/platform');

  static Future<bool> openExternalUrl(Uri uri) async {
    try {
      final didOpen = await _channel.invokeMethod<bool>('openExternalUrl', {
        'url': uri.toString(),
      });
      return didOpen ?? false;
    } on PlatformException {
      return false;
    }
  }
}
