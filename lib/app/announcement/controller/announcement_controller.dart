import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:seedsuser/app/announcement/model/announcement_model.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

/// Holds the announcement list shown under Profile > Announcements and the
/// unread count that drives the badge on that menu row.
///
/// Kept permanent so the badge stays correct wherever the user is in the app;
/// the popup service refreshes it after a dialog is closed.
class AnnouncementController extends GetxController {
  /// The one shared instance. Both the profile badge and the list screen reach
  /// the controller through here — a plain Get.put in each would replace the
  /// registered instance and reset the unread count.
  static AnnouncementController get to =>
      Get.isRegistered<AnnouncementController>()
          ? Get.find<AnnouncementController>()
          : Get.put(AnnouncementController(), permanent: true);

  final announcements = <AnnouncementModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnnouncements();
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthLocalStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchAnnouncements() async {
    try {
      isLoading.value = true;

      final response = await http.get(
        Uri.parse('${NetworkConfig.baseURL}/farmer/announcements'),
        headers: await _headers(),
      );

      // Revoked token (logged in elsewhere) → force logout.
      if (checkUnauthorizedResponse(response)) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          announcements.assignAll(
            (data['announcements'] as List? ?? [])
                .map((e) => AnnouncementModel.fromJson(e))
                .toList(),
          );
          unreadCount.value = data['unread_count'] ?? 0;
        }
      }
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Drop the previous account's announcements. The controller is permanent, so
  /// without this the next user to log in on this device would briefly see the
  /// old list and unread badge.
  void reset() {
    announcements.clear();
    unreadCount.value = 0;
  }

  /// Marks one announcement read and keeps the local list/badge in sync so the
  /// UI updates without another round trip.
  Future<void> markAsRead(int id) async {
    final index = announcements.indexWhere((a) => a.id == id);
    if (index != -1 && announcements[index].isRead) return;

    if (index != -1) {
      announcements[index] = announcements[index].copyWith(isRead: true);
      if (unreadCount.value > 0) unreadCount.value--;
    }

    try {
      final response = await http.post(
        Uri.parse('${NetworkConfig.baseURL}/farmer/announcements/$id/read'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['unread_count'] != null) {
          unreadCount.value = data['unread_count'];
        }
      }
    } catch (e) {
      debugPrint('Error marking announcement as read: $e');
    }
  }
}
