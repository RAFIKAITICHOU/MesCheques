import 'package:flutter/services.dart';

class WindowSecurityService {
  static const MethodChannel _channel = MethodChannel('com.mescheques/security');

  /// Toggles Android FLAG_SECURE to block screen captures and mask recent apps snapshot
  static Future<void> setSecure(bool enable) async {
    try {
      await _channel.invokeMethod('setSecure', {'enable': enable});
    } on PlatformException catch (_) {
      // Platform doesn't support FLAG_SECURE (e.g. desktop/web during tests)
    } catch (_) {}
  }
}
