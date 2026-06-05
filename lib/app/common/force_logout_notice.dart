import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Coordinates the "you were signed out because your account was used on another
/// device" notice.
///
/// Force-logout can be triggered from three places — an FCM `force_logout` in
/// the foreground, the same FCM handled in a background isolate, or a 401 on a
/// revoked token. Rather than each trying to show a dialog mid-navigation
/// (fragile), they all just raise a persisted flag and navigate to login. The
/// login screen then shows the dialog once, when it's safely mounted.
class ForceLogoutNotice {
  ForceLogoutNotice._();

  static const String _key = 'force_logout_pending';

  /// Raise the flag — call this right before clearing the session / navigating
  /// to the login screen.
  static Future<void> raise() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_key, true);
    } catch (_) {}
  }

  /// Read-and-clear the flag. Returns true if a force-logout notice is pending.
  static Future<bool> consume() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final pending = sp.getBool(_key) ?? false;
      if (pending) await sp.remove(_key);
      return pending;
    } catch (_) {
      return false;
    }
  }

  /// Show the notice dialog if one is pending. Safe to call from the login
  /// screen's first frame.
  static Future<void> showIfPending(BuildContext context) async {
    if (!await consume()) return;
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Logged out',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Your account was just signed in on another device, so you have '
          'been logged out here. Please log in again to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
