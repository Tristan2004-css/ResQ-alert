import 'package:flutter/services.dart';

class OverlayPermission {
  static const _ch = MethodChannel('app.overlay.channel');

  /// Opens the system overlay permission settings page.
  static Future<void> openSettings() async {
    try {
      await _ch.invokeMethod('openOverlaySettings');
    } catch (e) {
      // ignore
    }
  }

  /// Checks overlay permission status
  static Future<bool> canDrawOverlays() async {
    try {
      final res = await _ch.invokeMethod('canDrawOverlays');
      return res == true;
    } catch (e) {
      return false;
    }
  }
}
