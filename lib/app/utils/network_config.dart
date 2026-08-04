import 'package:seedsuser/app/utils/app_keys.dart';

class NetworkConfig {
  // ----------------------------------------------------------------
  // INTERNAL DEV TESTING
  // ----------------------------------------------------------------
  static const baseURL =
      // "https://antiquewhite-alpaca-43 3299.hostingersite.com/api";
      // "http://192.168.0.104:8000/api";
      // "https://staging.bestseed.in/api";
      // "https://bestseed.in/api";
      "https://aqua.bestseed.in/api";

  static const imageURL = "https://aqua.bestseed.in";
  // static const imageURL = "https://bestseed.in";
  // static const imageURL = "https://staging.bestseed.in";
  // static const imageURL = "http://127.0.0.1:8000";

  // Injected at build time from the gitignored secrets.json — see [AppKeys].
  // Both names are kept because call sites use each; they are the same key.
  static const googleApiKey = AppKeys.googleMaps;
  static const googleApiKey2 = AppKeys.googleMaps;

  static const noInternetMsg = 'Oops No Internet';
  static const msg = 'message';
  static const status = 'status';
  static const int timeoutDuration = 30;
}
