import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'package:seedsuser/app/common/local_storage.dart';

class VersionCheckResult {
  final bool forceUpdateRequired;
  final String currentVersion;
  final String minRequiredVersion;
  final String storeUrlAndroid;
  final String storeUrlIos;

  const VersionCheckResult({
    required this.forceUpdateRequired,
    required this.currentVersion,
    required this.minRequiredVersion,
    required this.storeUrlAndroid,
    required this.storeUrlIos,
  });
}

class AppVersionManager {
  static const _keyLastSeenVersion = 'last_seen_app_version';

  // Remote Config keys — set these in the Firebase console.
  static const _rcMinVersion = 'min_app_version';
  static const _rcStoreAndroid = 'store_url_android';
  static const _rcStoreIos = 'store_url_ios';

  // Fallbacks used when Remote Config has no value yet (first run, no network).
  static const _defaultStoreAndroid =
      'https://play.google.com/store/apps/details?id=com.bestseed.user';
  static const _defaultStoreIos =
      'https://apps.apple.com/app/idYOUR_APP_ID';

  /// Compares the current build fingerprint against the one stored from the
  /// previous launch. If anything changed, the auth token is cleared so the
  /// next screen is the login screen. Two signals are combined:
  ///   1. `version+buildNumber` — catches Play Store / App Store updates
  ///      (assumes the developer bumps the version per release).
  ///   2. `updateTime` — catches APK reinstalls during testing where the
  ///      version is NOT bumped (sideloaded release builds replace the
  ///      install but SharedPreferences and the token survive). Android
  ///      returns the new install timestamp; iOS may return null, in which
  ///      case only signal #1 applies.
  static Future<void> clearTokenIfVersionChanged() async {
    try {
      final info = await PackageInfo.fromPlatform();
      // Use updateTime — it changes every time an APK is installed over
      // an existing install (the sideload-testing flow). installTime would
      // only change on uninstall+reinstall and miss this case. iOS returns
      // a value here too. Fall back to installTime if updateTime is null.
      final updateAt = info.updateTime ?? info.installTime;
      final updateStamp = updateAt?.millisecondsSinceEpoch.toString() ?? '';
      final current = '${info.version}+${info.buildNumber}|$updateStamp';

      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(_keyLastSeenVersion);

      if (lastSeen != null && lastSeen != current) {
        await AuthLocalStorage.clear();
      }
      await prefs.setString(_keyLastSeenVersion, current);
    } catch (e) {
      debugPrint('AppVersionManager.clearTokenIfVersionChanged error: $e');
    }
  }

  /// Decides whether the installed build must be force-updated. Two checks
  /// run in order:
  ///   1. Firebase Remote Config `min_app_version` — manual override for
  ///      emergencies (e.g. block a specific bad build).
  ///   2. Store auto-detect via `upgrader` — queries Play Store / App Store
  ///      directly and returns true the moment a newer version is published,
  ///      with no Firebase change needed.
  /// Soft-fails on any error so an outage cannot brick the app.
  static Future<VersionCheckResult> checkForceUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    String minRequired = '';
    String storeAndroid = _defaultStoreAndroid;
    String storeIos = _defaultStoreIos;

    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 6),
        minimumFetchInterval: const Duration(minutes: 30),
      ));
      await rc.setDefaults({
        _rcMinVersion: '0.0.0',
        _rcStoreAndroid: _defaultStoreAndroid,
        _rcStoreIos: _defaultStoreIos,
      });
      await rc.fetchAndActivate();

      minRequired = rc.getString(_rcMinVersion).trim();
      final a = rc.getString(_rcStoreAndroid).trim();
      final i = rc.getString(_rcStoreIos).trim();
      if (a.isNotEmpty) storeAndroid = a;
      if (i.isNotEmpty) storeIos = i;
    } catch (e) {
      debugPrint('AppVersionManager.checkForceUpdate RC error: $e');
    }

    bool force = minRequired.isNotEmpty &&
        _isBelow(currentVersion, minRequired);

    // Store-driven auto-detect — only consult the store if Remote Config
    // didn't already force the update, since the RC check is faster and
    // more authoritative (admin-controlled).
    String storeLatest = '';
    if (!force) {
      try {
        final upgrader = Upgrader(
          durationUntilAlertAgain: const Duration(seconds: 0),
          debugLogging: kDebugMode,
        );
        await upgrader.initialize();
        if (upgrader.isUpdateAvailable()) {
          force = true;
          storeLatest = upgrader.currentAppStoreVersion ?? '';
        }
      } catch (e) {
        debugPrint('AppVersionManager.checkForceUpdate store error: $e');
      }
    }

    // Surface the store version on the screen if the gate was triggered by
    // the store check, otherwise show the Remote Config minimum.
    final displayedRequired =
        storeLatest.isNotEmpty ? storeLatest : minRequired;

    return VersionCheckResult(
      forceUpdateRequired: force,
      currentVersion: currentVersion,
      minRequiredVersion: displayedRequired,
      storeUrlAndroid: storeAndroid,
      storeUrlIos: storeIos,
    );
  }

  // Returns true if `current` semver is strictly less than `minimum`. Compares
  // numeric segments only ("1.2.3" vs "1.10.0" → 1.2.3 is lower).
  static bool _isBelow(String current, String minimum) {
    final c = _segments(current);
    final m = _segments(minimum);
    final len = c.length > m.length ? c.length : m.length;
    for (var i = 0; i < len; i++) {
      final cv = i < c.length ? c[i] : 0;
      final mv = i < m.length ? m[i] : 0;
      if (cv < mv) return true;
      if (cv > mv) return false;
    }
    return false;
  }

  static List<int> _segments(String version) {
    return version
        .split('+')
        .first
        .split('.')
        .map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }
}
