import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:seedsuser/app/utils/itunes_lookup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:seedsuser/app/common/local_storage.dart';

// Dev-only override used for on-device UI verification. Must be false
// for production builds — leaving it true would force every launch onto
// ForceUpdateScreen regardless of Play state.
const bool _kForceScreenForTest = false;

/// What the splash should do after `AppVersionManager.checkForceUpdate`.
enum ForceUpdateDecision {
  /// No update required — carry on with the normal auth / dashboard flow.
  proceed,

  /// Show the branded Bestseed ForceUpdateScreen. The screen's Update Now
  /// button then either (a) triggers Google's native immediate-update
  /// installer via `InAppUpdate.performImmediateUpdate` when the result's
  /// `useInAppUpdate` flag is true, or (b) deep-links to the Play Store
  /// / App Store when it's false (iOS, sideloaded, or RC-only floor).
  showBlockScreen,
}

class VersionCheckResult {
  final ForceUpdateDecision decision;
  final String currentVersion;
  final String minRequiredVersion;
  final String storeUrlAndroid;
  final String storeUrlIos;

  /// True when the Play In-App Updates API confirmed a newer version is
  /// available AND the device can do an immediate install. Tells the
  /// ForceUpdateScreen to call `InAppUpdate.performImmediateUpdate()` on
  /// tap instead of launching a `market://` URL — Google's install flow
  /// takes over inside our app and auto-restarts with the new version.
  final bool useInAppUpdate;

  const VersionCheckResult({
    required this.decision,
    required this.currentVersion,
    required this.minRequiredVersion,
    required this.storeUrlAndroid,
    required this.storeUrlIos,
    this.useInAppUpdate = false,
  });
}

class AppVersionManager {
  static const _keyLastSeenVersion = 'last_seen_app_version';

  // Remote Config keys — set these in the Firebase console.
  static const _rcMinVersion = 'min_app_version';
  static const _rcStoreAndroid = 'store_url_android';
  static const _rcStoreIos = 'store_url_ios';

  // Play Store URL — real deep link for the published app.
  static const _defaultStoreAndroid =
      'https://play.google.com/store/apps/details?id=com.app.bestseed';
  // App Store SEARCH URL — safe default until the app is published on
  // iOS. Always resolves to a working page (unlike the old
  // `idYOUR_APP_ID` placeholder that opened App Store to
  // "App Not Available"). Replace with the real id-based URL once live.
  static const _defaultStoreIos =
      'https://apps.apple.com/search?term=bestseed';

  /// Compares the current build fingerprint against the one stored from
  /// the previous launch. If anything changed, the auth token is cleared
  /// so the next screen is the login screen.
  static Future<void> clearTokenIfVersionChanged() async {
    try {
      final info = await PackageInfo.fromPlatform();
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

  /// Decides whether the splash should hand control to ForceUpdateScreen.
  ///
  /// 1. **Android — Google Play In-App Updates.** `checkForUpdate()`
  ///    asks Play directly whether a newer version is published. If yes,
  ///    we return `showBlockScreen` with `useInAppUpdate: true` so the
  ///    branded Bestseed screen appears first — its Update Now button
  ///    then triggers Google's immediate-update installer inline (no
  ///    kick-out to the Play Store app). If Play says no update, we
  ///    trust it and return `proceed` — Remote Config is NOT consulted
  ///    on this path, so a misconfigured RC floor can't lock latest
  ///    users.
  /// 2. **iOS + Android when Play was unreachable** — Firebase Remote
  ///    Config `min_app_version` floor. If installed < floor, return
  ///    `showBlockScreen` with `useInAppUpdate: false` so the button
  ///    deep-links to the store.
  ///
  /// Every step soft-fails so a client-side outage cannot brick users.
  static Future<VersionCheckResult> checkForceUpdate() async {
    // Fail-safe: if PackageInfo itself throws (rare corrupt install /
    // OEM ROM), default currentVersion to '0.0.0'. The pipeline still
    // runs, and on Android Play Store is authoritative regardless.
    String currentVersion = '0.0.0';
    try {
      final info = await PackageInfo.fromPlatform();
      currentVersion = info.version;
    } catch (e) {
      debugPrint('AppVersionManager: PackageInfo.fromPlatform failed: $e');
    }

    // TEMP dev override — see _kForceScreenForTest above.
    if (_kForceScreenForTest) {
      debugPrint('AppVersionManager: _kForceScreenForTest=true — forcing block screen');
      return VersionCheckResult(
        decision: ForceUpdateDecision.showBlockScreen,
        currentVersion: currentVersion,
        // Empty so the version chip on ForceUpdateScreen doesn't render
        // (matches production behaviour when Play In-App Update detects
        // an update: `minRequiredVersion` is passed empty and the chip's
        // `isNotEmpty` guard hides it). User sees logo + title + button
        // only, which is the real UI they'll ship.
        minRequiredVersion: '',
        storeUrlAndroid: _defaultStoreAndroid,
        storeUrlIos: _defaultStoreIos,
        useInAppUpdate: false,
      );
    }

    String storeAndroid = _defaultStoreAndroid;
    String storeIos = _defaultStoreIos;
    String minRequired = '';

    // ── 1) Android: Google Play In-App Updates ──
    // MUST guard with Platform.isAndroid — the plugin throws
    // MissingPluginException on iOS.
    if (Platform.isAndroid) {
      try {
        final upd = await InAppUpdate.checkForUpdate()
            .timeout(const Duration(seconds: 6));

        if (upd.updateAvailability == UpdateAvailability.updateAvailable) {
          // Show branded screen first; the button will invoke
          // performImmediateUpdate() on tap. If Play won't allow
          // immediate on this device, `useInAppUpdate` is false and the
          // button falls back to a Play Store deep-link.
          return VersionCheckResult(
            decision: ForceUpdateDecision.showBlockScreen,
            currentVersion: currentVersion,
            minRequiredVersion: '',
            storeUrlAndroid: storeAndroid,
            storeUrlIos: storeIos,
            useInAppUpdate: upd.immediateUpdateAllowed,
          );
        }

        // Play answered authoritatively: no update available. Trust
        // Play and skip Remote Config — this prevents a misconfigured
        // RC floor (staging leftover, premature emergency bump) from
        // locking users on the latest Play build.
        return VersionCheckResult(
          decision: ForceUpdateDecision.proceed,
          currentVersion: currentVersion,
          minRequiredVersion: '',
          storeUrlAndroid: storeAndroid,
          storeUrlIos: storeIos,
        );
      } catch (e) {
        // ERROR_API_NOT_AVAILABLE (sideloaded APK, no Play Services),
        // network error, or plugin crash. Fall through to Remote
        // Config as the emergency backup.
        debugPrint('AppVersionManager: InAppUpdate check failed: $e');
      }
    }

    // ── 2) iOS: Apple iTunes Lookup API ──
    // Apple has no equivalent to Google's Play In-App Updates, so we
    // query the public iTunes Lookup endpoint by bundle ID and compare
    // its `version` field against the installed build. If iTunes answers
    // authoritatively (either "update needed" or "no update"), trust it
    // and skip Remote Config — same pattern as the Android branch above.
    // Only fall through to RC when iTunes is unreachable / malformed.
    //
    // SAFETY: skip the comparison entirely when currentVersion is still
    // the '0.0.0' placeholder from a PackageInfo failure — otherwise
    // _isBelow('0.0.0', anyRealAppStoreVersion) is unconditionally true
    // and we'd block every iOS user with a bogus "Your version: 0.0.0"
    // chip. Better to fall through to RC (which has its own guard) and
    // ultimately proceed than to hard-lock users we can't diagnose.
    if (Platform.isIOS && currentVersion != '0.0.0') {
      final lookup = await ITunesLookup.lookup(
        bundleId: 'com.app.bestseed',
      );
      if (lookup != null) {
        // Adopt the store URL Apple returned — canonical deep link.
        if (lookup.trackViewUrl.isNotEmpty) storeIos = lookup.trackViewUrl;

        if (_isBelow(currentVersion, lookup.version)) {
          return VersionCheckResult(
            decision: ForceUpdateDecision.showBlockScreen,
            currentVersion: currentVersion,
            minRequiredVersion: lookup.version,
            storeUrlAndroid: storeAndroid,
            storeUrlIos: storeIos,
            useInAppUpdate: false, // iOS has no in-app update installer
          );
        }
        // iTunes said no update available — trust it, skip RC.
        return VersionCheckResult(
          decision: ForceUpdateDecision.proceed,
          currentVersion: currentVersion,
          minRequiredVersion: '',
          storeUrlAndroid: storeAndroid,
          storeUrlIos: storeIos,
        );
      }
      // iTunes lookup failed (network, storefront miss, malformed JSON).
      // Fall through to Remote Config as the emergency backup.
      debugPrint('AppVersionManager: iTunes Lookup returned null — falling back to RC');
    }

    // ── 3) Both platforms: Remote Config floor (emergency backup) ──
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 6),
        // Zero interval: emergency floor propagates on the very next
        // cold start after admin bumps it.
        minimumFetchInterval: Duration.zero,
      ));
      await rc.setDefaults(const {
        _rcMinVersion: '0.0.0',
        // Empty defaults so `isNotEmpty` below is a real signal — the
        // compile-time defaults above are used only when RC didn't
        // set an override.
        _rcStoreAndroid: '',
        _rcStoreIos: '',
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

    final bool needsUpdate = minRequired.isNotEmpty &&
        minRequired != '0.0.0' &&
        _isBelow(currentVersion, minRequired);

    return VersionCheckResult(
      decision: needsUpdate
          ? ForceUpdateDecision.showBlockScreen
          : ForceUpdateDecision.proceed,
      currentVersion: currentVersion,
      minRequiredVersion: minRequired,
      storeUrlAndroid: storeAndroid,
      storeUrlIos: storeIos,
      // RC-only path: no Play in-app updater available (either iOS or
      // Play was unreachable). Button will deep-link to the store URL.
      useInAppUpdate: false,
    );
  }

  // Returns true if `current` semver is strictly less than `minimum`.
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
