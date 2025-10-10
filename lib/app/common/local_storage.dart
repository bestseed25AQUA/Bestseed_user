import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalStorage {
  static const _keyToken = 'user_token';
  static const _keyMobile = 'user_mobile';

  static Future<void> saveUserData({
    required String token,
    required String mobile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyMobile, mobile);
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
}
