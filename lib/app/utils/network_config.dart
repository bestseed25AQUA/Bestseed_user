import 'package:seedsuser/app/utils/app_keys.dart';

class NetworkConfig {
  // ----------------------------------------------------------------
  // INTERNAL DEV TESTING
  // ----------------------------------------------------------------
  // LOCAL — this Mac's LAN IP, so the same value serves the iOS simulator AND a
  // real phone on the same Wi-Fi.
  //
  // Run the backend as: php artisan serve --host=0.0.0.0 --port=8000
  // `--host=0.0.0.0` matters — a server bound to 127.0.0.1 only is unreachable
  // at this address.
  //
  // RE-CHECK THE IP after any reconnect: DHCP moves it, and a stale address
  // fails as a timeout, which looks like a dead server rather than a wrong URL.
  //   ipconfig getifaddr en0
  //
  // Both of these must name the same host and port. They did not: the API was
  // on :8100 — where nothing listens at all — while images were on :8000, so
  // every request failed before it left the device.
  static const baseURL =
      //   "http://10.79.117.125:8000/api";
      "https://lemonchiffon-dragonfly-369328.hostingersite.com/api";
  static const imageURL =
      //   "http://10.79.117.125:8000";
      "https://lemonchiffon-dragonfly-369328.hostingersite.com";

  // Other environments, kept for switching back:
  // "https://lemonchiffon-dragonfly-369328.hostingersite.com/api";
  // "http://127.0.0.1:8000/api";   // simulator only — a phone calls itself
  // "https://staging.bestseed.in/api";
  // "https://bestseed.in/api";
  // "https://aqua.bestseed.in/api";

  // Injected at build time from the gitignored secrets.json — see [AppKeys].
  // Both names are kept because call sites use each; they are the same key.
  static const googleApiKey = AppKeys.googleMaps;
  static const googleApiKey2 = AppKeys.googleMaps;

  static const noInternetMsg = 'Oops No Internet';
  static const msg = 'message';
  static const status = 'status';
  static const int timeoutDuration = 30;
}
