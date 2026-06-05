import 'package:get/get.dart';
import 'package:seedsuser/app/auth/view/login_screen.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

/// Enforces single-device login on the *previous* device.
///
/// When the same account logs in on another phone, the backend revokes THIS
/// device's token. From then on:
///   - any authenticated request returns HTTP 401, which
///     `network_utils._handle401()` turns into "clear session + go to login",
///     and
///   - the backend also pushes an FCM `force_logout` (best effort).
///
/// This service makes the logout reliable in every state of the old device —
/// foreground, background, terminated, or temporarily offline:
///   - It pings a tiny authenticated endpoint (profile) on app start, on every
///     app-resume, and periodically while open. A revoked token → 401 → logout.
///     This is the backbone: it works even if the FCM push never arrives, and
///     it fires as soon as a previously-offline device reconnects.
///   - If the token was already wiped out from under us (a background FCM
///     `force_logout` cleared it while the app was backgrounded), the very next
///     check sees no token and forces navigation to the login screen so the old
///     device never sits on an authenticated screen without a session.
class SessionService {
  /// Guard so overlapping checks (resume firing during the periodic tick)
  /// don't stack multiple profile requests.
  static bool _checking = false;

  /// Guard so we don't fire repeated redirects to login.
  static bool _redirecting = false;

  static Future<void> validate() async {
    if (_checking) return;
    _checking = true;
    try {
      final token = await AuthLocalStorage.getToken();
      if (token == null || token.isEmpty) {
        // Session was cleared out from under us — e.g. a background FCM
        // force_logout wiped the token while the app was backgrounded, or a
        // prior 401 cleared it. Make sure we're actually on the login screen.
        // (The login screen shows the "signed in on another device" dialog if
        // the ForceLogoutNotice flag was raised; a normal logout leaves no flag
        // so it just lands on login silently.)
        _redirectToLoginIfNeeded();
        return;
      }
      // A 401 here is handled inside getRequest (_checkUnauthorized →
      // _handle401): it clears storage and navigates to the login screen.
      await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/profile",
        headers: await buildHeader(),
      );
    } catch (_) {
      // Ignore network/timeout errors — only a real 401 forces logout, and
      // that path is handled inside getRequest, not here. (Offline simply means
      // we try again on the next tick / resume / reconnect.)
    } finally {
      _checking = false;
    }
  }

  /// Send the user to login unless they're already there or a redirect is
  /// already in flight.
  static void _redirectToLoginIfNeeded() {
    if (_redirecting) return;
    if (Get.currentRoute.contains('LoginWithMobileScreen')) return;
    _redirecting = true;
    Get.offAll(() => LoginWithMobileScreen());
    // Release the guard shortly after, once navigation has settled.
    Future.delayed(const Duration(seconds: 2), () => _redirecting = false);
  }
}
