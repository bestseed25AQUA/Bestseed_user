import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:seedsuser/app/announcement/announcement_dialog.dart';
import 'package:seedsuser/app/announcement/controller/announcement_controller.dart';
import 'package:seedsuser/app/announcement/model/announcement_model.dart';
import 'package:seedsuser/app/common/app_globals.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/utils/network_config.dart';

/// Decides when a new announcement pops up as a dialog.
///
/// The server is the source of truth: GET /farmer/announcements/popup returns
/// the newest announcement this user has never been shown, or null. The same
/// call marks every other never-shown announcement as "offered" — so only the
/// newest ever interrupts, and the rest simply wait, still unread, in
/// Profile > Announcements.
///
/// Triggered from every app state so an announcement is never missed:
///  1. Real-time — foreground FCM `announcement` → [onAnnouncementPush].
///  2. Resume — background → foreground.
///  3. Start / just-logged-in — Dashboard landing calls [check].
class AnnouncementPromptService {
  AnnouncementPromptService._();
  static final AnnouncementPromptService instance = AnnouncementPromptService._();

  bool _isShowing = false;

  static String get _base => NetworkConfig.baseURL;

  /// Real-time path: an announcement push arrived while the app is open.
  Future<void> onAnnouncementPush(Map<String, dynamic> data) async {
    if (data['type']?.toString() != 'announcement') return;
    await check();
  }

  /// Start / resume path. Safe to call often — no-ops when logged out, when
  /// nothing is pending, or when a dialog is already up.
  Future<void> check() async {
    if (_isShowing) return;

    try {
      final token = await AuthLocalStorage.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$_base/farmer/announcements/popup'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data['status'] != true) return;

      // Keep the Profile badge in step even when nothing pops up — the popup
      // call is the most frequent signal we get about the unread count.
      _syncBadge(data['unread_count']);

      final payload = data['announcement'];
      if (payload == null) return;

      await _present(AnnouncementModel.fromJson(
        Map<String, dynamic>.from(payload),
      ));
    } catch (e) {
      debugPrint('Announcement popup check failed: $e');
      // Network hiccup — try again on the next resume/start.
    }
  }

  Future<void> _present(AnnouncementModel announcement) async {
    if (_isShowing) return;

    final context = navigatorKey.currentContext;
    // Navigator not mounted yet (e.g. still on splash) — leave it so a later
    // resume/landing trigger shows it from a stable screen.
    if (context == null) return;

    _isShowing = true;
    try {
      // The close (X) is the only way out — no barrier dismiss, so the user
      // has actually seen it before it drops into the list.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AnnouncementDialog(announcement: announcement),
      );

      await _markRead(announcement.id);
    } finally {
      _isShowing = false;
    }
  }

  Future<void> _markRead(int id) async {
    if (Get.isRegistered<AnnouncementController>()) {
      await Get.find<AnnouncementController>().markAsRead(id);
      return;
    }

    // List screen was never opened this session — mark it on the server
    // directly so the dialog doesn't count as unread.
    try {
      final token = await AuthLocalStorage.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('$_base/farmer/announcements/$id/read'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint('Announcement mark-read failed: $e');
    }
  }

  void _syncBadge(dynamic unreadCount) {
    if (unreadCount == null) return;
    if (!Get.isRegistered<AnnouncementController>()) return;

    final count = int.tryParse('$unreadCount');
    if (count != null) {
      Get.find<AnnouncementController>().unreadCount.value = count;
    }
  }
}
