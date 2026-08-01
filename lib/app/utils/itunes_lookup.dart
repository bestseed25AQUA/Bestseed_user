import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of a successful iTunes Lookup for an app.
class ITunesLookupResult {
  /// Latest version published on the App Store (semver, e.g. "1.2.2").
  final String version;

  /// Canonical App Store deep-link — `https://apps.apple.com/<cc>/app/<slug>/id<numeric>`.
  /// Empty string if Apple's response was malformed.
  final String trackViewUrl;

  const ITunesLookupResult({
    required this.version,
    required this.trackViewUrl,
  });
}

/// iOS equivalent of Google Play's `in_app_update` version check. Queries
/// Apple's public iTunes Lookup endpoint by bundle ID and returns the
/// current App Store version + the canonical store URL for that app.
///
/// Unauthenticated, no API key needed. Returns null on any error
/// (network failure, malformed JSON, app not found in the queried
/// storefront). Callers should soft-fail — an outage must never brick
/// the app.
class ITunesLookup {
  ITunesLookup._();

  /// Look up the current App Store version for [bundleId] in the given
  /// [country] storefront (ISO-3166 code; use "in" for India, "us" for
  /// US, etc.). Returns null on any failure.
  ///
  /// If the requested storefront returns no result, the lookup retries
  /// ONCE against the US storefront with HALF the remaining timeout
  /// (worst-case caller wait is ~1.5x the passed timeout, not 2x). This
  /// covers apps not yet published in the primary market without letting
  /// a slow network double the splash latency.
  static Future<ITunesLookupResult?> lookup({
    required String bundleId,
    String country = 'in',
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      // Uri.https URL-encodes query params so a stray `&`/`=`/`#`/space
      // in bundleId can't inject extra params or truncate the URL.
      final uri = Uri.https(
        'itunes.apple.com',
        '/lookup',
        {'bundleId': bundleId, 'country': country},
      );
      final res = await http.get(uri).timeout(timeout);
      if (res.statusCode != 200) {
        debugPrint('ITunesLookup: HTTP ${res.statusCode}');
        return null;
      }
      final data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) return null;
      final results = data['results'];
      if (results is! List || results.isEmpty) {
        // App isn't published in this storefront. Retry once against
        // the US storefront (compare lower-cased so `US` also short-
        // circuits) with HALF the remaining timeout so we don't blow
        // the caller's overall budget.
        if (country.toLowerCase() != 'us') {
          return lookup(
            bundleId: bundleId,
            country: 'us',
            timeout: Duration(milliseconds: timeout.inMilliseconds ~/ 2),
          );
        }
        return null;
      }
      final r = results.first;
      if (r is! Map<String, dynamic>) return null;
      // Type-safe field extraction — Apple could ship a numeric or
      // nested value here (unlikely but possible on future schema
      // changes); handle each field independently so one bad field
      // doesn't discard the rest.
      final vRaw = r['version'];
      final version = (vRaw is String) ? vRaw.trim() : '';
      final tRaw = r['trackViewUrl'];
      final trackUrl = (tRaw is String) ? tRaw.trim() : '';
      if (version.isEmpty) return null;
      return ITunesLookupResult(
        version: version,
        trackViewUrl: trackUrl,
      );
    } catch (e) {
      debugPrint('ITunesLookup: $e');
      return null;
    }
  }
}
