import 'package:seedsuser/app/utils/app_keys.dart';

class NetworkConfig {
  // ----------------------------------------------------------------
  // INTERNAL DEV TESTING
  // ----------------------------------------------------------------
  // LOCAL, for the iOS simulator: it shares this Mac's network, so 127.0.0.1
  // works and — unlike the LAN IP — never changes when DHCP moves you.
  // For a PHYSICAL device swap this for the Mac's LAN IP (ipconfig getifaddr en0).
  // Either way: php artisan serve --host=0.0.0.0 --port=8100
  static const baseURL =
      // "http://127.0.0.1:8100/api";
      // "https://lemonchiffon-dragonfly-369328.hostingersite.com/api";
      // 192.168.29.1 is the ROUTER, not this machine — requests to it hang
      // until they time out. This PC is .202 (ipconfig / Get-NetIPAddress),
      // and DHCP can move it, so re-check the last octet if the app starts
      // timing out again after a reconnect.
      "http://192.168.29.202:8000/api";
  // "https://staging.bestseed.in/api";
  // "https://bestseed.in/api";
  // "https://aqua.bestseed.in/api";
  // "http://192.168.31.8:8000/api";

  // static const imageURL = "https://aqua.bestseed.in";
  // static const imageURL = "https://bestseed.in";
  // static const imageURL = "http://127.0.0.1:8100";
  // static const imageURL =
      // "https://lemonchiffon-dragonfly-369328.hostingersite.com";
  static const imageURL = "http://192.168.29.202:8000";

  // Injected at build time from the gitignored secrets.json — see [AppKeys].
  // Both names are kept because call sites use each; they are the same key.
  static const googleApiKey = AppKeys.googleMaps;
  static const googleApiKey2 = AppKeys.googleMaps;

  static const noInternetMsg = 'Oops No Internet';
  static const msg = 'message';
  static const status = 'status';
  static const int timeoutDuration = 30;
}
