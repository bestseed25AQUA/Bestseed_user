import 'package:seedsuser/app/utils/app_keys.dart';

class NetworkConfig {
  // ----------------------------------------------------------------
  // INTERNAL DEV TESTING
  // ----------------------------------------------------------------
  // LOCAL: this Mac on the LAN. Works from the simulator AND a physical device
  // on the same Wi-Fi. Requires: php artisan serve --host=0.0.0.0 --port=8100
  static const baseURL = "http://192.168.1.7:8100/api";
  // "https://lemonchiffon-dragonfly-369328.hostingersite.com/api";
  // "http://192.168.0.104:8000/api";
  // "https://staging.bestseed.in/api";
  // "https://bestseed.in/api";
  // "https://aqua.bestseed.in/api";
  // "http://192.168.31.8:8000/api";

  // static const imageURL = "https://aqua.bestseed.in";
  // static const imageURL = "https://bestseed.in";
  static const imageURL = "http://192.168.1.7:8100";
  // static const imageURL =
  // "https://lemonchiffon-dragonfly-369328.hostingersite.com";
  // static const imageURL = "http://192.168.31.8:8000";

  // Injected at build time from the gitignored secrets.json — see [AppKeys].
  // Both names are kept because call sites use each; they are the same key.
  static const googleApiKey = AppKeys.googleMaps;
  static const googleApiKey2 = AppKeys.googleMaps;

  static const noInternetMsg = 'Oops No Internet';
  static const msg = 'message';
  static const status = 'status';
  static const int timeoutDuration = 30;
}
