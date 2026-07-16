import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'package:seedsuser/app/common/app_globals.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/rating/pending_rating.dart';
import 'package:seedsuser/app/rating/rating_dialog.dart';
import 'package:seedsuser/app/utils/network_config.dart';

/// Decides when to show the post-delivery rating popup.
///
/// The server is the source of truth for "should we ask?":
/// GET /api/farmer/pending-rating returns the delivered, *unrated and
/// not-dismissed* booking (or null). So once the user submits a rating OR
/// closes the popup (which calls /dismiss-rating), it never shows again — even
/// across reinstalls or other devices.
///
/// Triggered from every app state so a delivery is never missed:
///  1. Real-time — foreground FCM `booking_status` status 5 → [onDeliveredPush].
///  2. Resume — background → foreground (genuine resume only).
///  3. Start / terminated → open / just-logged-in — Dashboard landing calls
///     [checkPending] once the home screen is mounted.
class RatingPromptService {
  RatingPromptService._();
  static final RatingPromptService instance = RatingPromptService._();

  bool _isShowing = false;
  // Show at most ONE rating prompt per app session. Without this, a user with a
  // backlog of delivered-but-unrated bookings gets prompted again for the NEXT
  // booking the moment they finish rating one (pending-rating just returns the
  // next in the queue) — which reads as "the rating keeps popping up". Rating
  // one per launch clears the backlog gradually without nagging. Reset on
  // restart; the server + _handled set keep already-handled ones suppressed.
  bool _promptedThisSession = false;
  final GetStorage _box = GetStorage();
  // Persisted across restarts so a booking the user already rated/dismissed is
  // never shown again on THIS device, even if the server call failed. The
  // server stays the authority across devices/reinstalls.
  static const String _handledKey = 'handled_rating_booking_ids';

  static String get _base => NetworkConfig.baseURL;

  bool _isHandled(String id) {
    final raw = _box.read<List>(_handledKey) ?? [];
    final handled = raw.map((e) => e.toString()).contains(id);
    debugPrint('⭐[RATING] _isHandled($id) -> $handled | stored=$raw');
    return handled;
  }

  Future<void> _markHandled(String id) async {
    final ids = (_box.read<List>(_handledKey) ?? [])
        .map((e) => e.toString())
        .toSet()
      ..add(id);
    // Await the write so the dismissal survives an immediate app kill.
    await _box.write(_handledKey, ids.toList());
    debugPrint('⭐[RATING] _markHandled($id) | now stored=${ids.toList()}');
  }

  /// Real-time path: a "Delivered" (status 5) push arrived in the foreground.
  /// We re-fetch from the server so the popup gets the full booking details
  /// and honours any prior rating/dismissal.
  Future<void> onDeliveredPush(Map<String, dynamic> data) async {
    debugPrint('⭐[RATING] onDeliveredPush: $data');
    if (data['type']?.toString() != 'booking_status') return;
    if (data['status']?.toString() != '5') return;
    await checkPending();
  }

  /// Start / resume path. Safe to call often — no-ops when logged out, when
  /// nothing is pending, or when a dialog is already up.
  Future<void> checkPending() async {
    debugPrint('⭐[RATING] checkPending() called | _isShowing=$_isShowing');
    if (_isShowing) return;
    // One rating prompt per app session — don't nag through a backlog.
    if (_promptedThisSession) {
      debugPrint('⭐[RATING] already prompted this session — skip');
      return;
    }

    final token = await AuthLocalStorage.getToken();
    if (token == null) {
      debugPrint('⭐[RATING] checkPending: no token (logged out) — skip');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_base/farmer/pending-rating'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
          '⭐[RATING] pending-rating HTTP ${response.statusCode} -> ${response.body}');
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final booking = body['booking'];
      if (booking is! Map) {
        debugPrint('⭐[RATING] no pending booking — skip');
        return;
      }

      final pending =
          PendingRating.fromJson(Map<String, dynamic>.from(booking));
      debugPrint('⭐[RATING] pending booking id=${pending.id}');
      if (pending.id.isEmpty || _isHandled(pending.id)) {
        debugPrint('⭐[RATING] already handled or empty — skip showing');
        return;
      }

      await _present(pending);
    } catch (e) {
      debugPrint('⭐[RATING] checkPending error: $e');
      // Network hiccup — try again on the next resume/start.
    }
  }

  Future<void> _present(PendingRating pending) async {
    if (_isShowing) return;
    final context = navigatorKey.currentContext;
    // Navigator not mounted yet (e.g. still on splash) — leave it so a later
    // resume/landing trigger shows it from a stable screen.
    if (context == null) {
      debugPrint('⭐[RATING] _present: navigator context null — defer');
      return;
    }

    _isShowing = true;
    // Consume this session's single rating prompt the moment we commit to
    // presenting, so no resume / repeated FCM re-triggers another one (for this
    // or the next backlog booking) until the app is relaunched.
    _promptedThisSession = true;
    debugPrint('⭐[RATING] _present: showing dialog for booking ${pending.id}');

    try {
      // Dismissible only via the close (X) inside the dialog, not by tapping
      // outside — dismissal is permanent so it must be intentional.
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => RatingDialog(pending: pending),
      );
      debugPrint('⭐[RATING] dialog closed with result=$result '
          '(${result == true ? 'SUBMITTED' : 'DISMISSED'})');

      // Either way the user has handled this booking — never show it again on
      // this device. Persist immediately so a reopen won't re-prompt even if
      // the server call below fails.
      await _markHandled(pending.id);

      // Submitted → server already has the rating. Closed/cancelled (null or
      // false) → tell the server not to ask again (cross-device).
      if (result != true) {
        await _dismissOnServer(pending.id);
      }
    } finally {
      _isShowing = false;
    }
  }

  Future<void> _dismissOnServer(String bookingId) async {
    debugPrint('⭐[RATING] _dismissOnServer($bookingId) POST...');
    try {
      final token = await AuthLocalStorage.getToken();
      if (token == null) return;
      final res = await http.post(
        Uri.parse('$_base/farmer/dismiss-rating'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'booking_id': bookingId}),
      );
      debugPrint(
          '⭐[RATING] dismiss-rating HTTP ${res.statusCode} -> ${res.body}');
    } catch (e) {
      debugPrint('⭐[RATING] dismiss-rating error: $e');
      // Best-effort. If it fails the popup may reappear next launch, which is
      // acceptable — we simply didn't record the dismissal.
    }
  }
}
