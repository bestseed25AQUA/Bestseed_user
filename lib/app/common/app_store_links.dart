import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Store links used by "Rate us" and "Share app".
///
/// Each action tries the store's own app-scheme URI first (`market://` on
/// Android, `itms-apps://` on iOS) so the installed Play Store / App Store app
/// opens directly, and only falls back to the https link — which the browser or
/// the store app's link handler picks up — if that fails.
class AppStoreLinks {
  AppStoreLinks._();

  static const String appName = 'Bestseed';

  /// Android applicationId — keep in sync with android/app/build.gradle.kts.
  static const String androidPackageId = 'com.app.bestseed';

  /// Numeric Apple App Store id (the digits in `apps.apple.com/app/id123456789`,
  /// shown as "Apple ID" on the App Store Connect app page). It is NOT the
  /// bundle id.
  ///
  /// While this is empty, iOS falls back to an App Store *search* for the app
  /// name — the buttons still work, but they can't land on the listing. Fill it
  /// in once the app is registered in App Store Connect.
  static const String appStoreId = '';

  static bool get _isIOS => !kIsWeb && Platform.isIOS;
  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  static String get appStoreUrl => appStoreId.isEmpty
      ? 'https://apps.apple.com/search?term=$appName'
      : 'https://apps.apple.com/app/id$appStoreId';

  /// The public https link for the *current* platform — this is what goes into
  /// the share message, so an Android user shares the Play Store link and an
  /// iOS user shares the App Store link.
  static String get storeUrl => _isIOS ? appStoreUrl : playStoreUrl;

  /// Message put on the share sheet.
  static String get shareMessage =>
      'Book quality shrimp seed from trusted hatcheries with $appName.\n\n'
      'Download the app: $storeUrl';

  /// Store-app URI for the listing.
  static Uri? get _nativeStoreUri {
    if (_isAndroid) return Uri.parse('market://details?id=$androidPackageId');
    if (_isIOS && appStoreId.isNotEmpty) {
      return Uri.parse('itms-apps://itunes.apple.com/app/id$appStoreId');
    }
    return null;
  }

  /// Store-app URI that lands on the review composer. Play Store has no
  /// write-review deep link, so Android just opens the listing (where the
  /// rating stars are); iOS supports `?action=write-review`.
  static Uri? get _nativeReviewUri {
    if (_isAndroid) return _nativeStoreUri;
    if (_isIOS && appStoreId.isNotEmpty) {
      return Uri.parse(
        'itms-apps://itunes.apple.com/app/id$appStoreId?action=write-review',
      );
    }
    return null;
  }

  static Uri get _webReviewUri {
    if (_isIOS && appStoreId.isNotEmpty) {
      return Uri.parse('https://apps.apple.com/app/id$appStoreId?action=write-review');
    }
    return Uri.parse(storeUrl);
  }

  /// Channel implemented in MainActivity.kt — see [_openPlayStoreDirectly].
  static const MethodChannel _androidChannel = MethodChannel('bestseed/store');

  /// Android only: opens Play Store with no app-chooser in between.
  ///
  /// `url_launcher` can only send an *implicit* intent, so on devices that ship
  /// a second app store the system asks the user to pick one first. The native
  /// side pins the intent to the Play Store package instead, which lands on the
  /// listing directly. Returns false when Play Store is absent/disabled, so the
  /// caller can fall back to the browser.
  static Future<bool> _openPlayStoreDirectly() async {
    if (!_isAndroid) return false;
    try {
      final ok = await _androidChannel.invokeMethod<bool>(
        'openPlayStore',
        {'packageName': androidPackageId},
      );
      return ok ?? false;
    } catch (e) {
      debugPrint('🔗 [STORE] native Play Store launch failed: $e');
      return false;
    }
  }

  /// Opens the store listing. Returns false if nothing could handle it.
  static Future<bool> openStoreListing() async {
    if (await _openPlayStoreDirectly()) return true;
    return _launchFirst([_nativeStoreUri, Uri.parse(storeUrl)]);
  }

  /// Opens the review page (falls back to the plain listing).
  static Future<bool> openReviewPage() async {
    // Play Store has no write-review deep link — the listing (with its rating
    // stars) is the destination on Android either way.
    if (await _openPlayStoreDirectly()) return true;
    return _launchFirst([_nativeReviewUri, _webReviewUri, Uri.parse(storeUrl)]);
  }

  /// Tries each URI in order, returning as soon as one opens.
  ///
  /// Deliberately does NOT use `canLaunchUrl` — on Android 11+ that returns
  /// false for any scheme missing from the manifest `<queries>` block, which
  /// made the buttons silently do nothing. Attempting the launch and catching
  /// the failure is both simpler and more forgiving.
  static Future<bool> _launchFirst(List<Uri?> uris) async {
    final tried = <String>{};
    for (final uri in uris) {
      if (uri == null || !tried.add(uri.toString())) continue;
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
        debugPrint('🔗 [STORE] launch returned false for $uri');
      } catch (e) {
        debugPrint('🔗 [STORE] launch failed for $uri: $e');
      }
    }
    return false;
  }
}
