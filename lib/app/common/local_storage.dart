import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalStorage {
  static const _keyToken = 'user_token';
  static const _keyMobile = 'user_mobile';
  static const _installMarkerFileName = '.auth_install_marker';

  static Future<void> saveUserData({
    required String token,
    required String mobile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyMobile, mobile);
    await _ensureInstallMarker();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyMobile);
  }

  // App documents survive normal launches but are wiped on uninstall on both
  // Android and iOS, even when SharedPreferences (Android Auto Backup / D2D
  // restore) or Keychain (iOS) hand a stale token back to the new install.
  // If the marker is missing on launch, any token we find is a restored
  // ghost — drop it so the splash routes to login.
  static Future<void> dropStaleTokenIfFreshInstall() async {
    try {
      final marker = await _markerFile();
      if (await marker.exists()) return;
      await clear();
      await marker.create(recursive: true);
    } catch (_) {
      // Marker unreadable (sandboxed test, locked FS) — let the existing
      // server-side token validation in splash catch the stale token.
    }
  }

  static Future<void> _ensureInstallMarker() async {
    try {
      final marker = await _markerFile();
      if (!await marker.exists()) await marker.create(recursive: true);
    } catch (_) {}
  }

  static Future<File> _markerFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_installMarkerFileName');
  }
}
