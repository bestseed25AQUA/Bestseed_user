import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/notification/model/push_notification_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';

class NotificationController extends GetxController {
  final notifications = <PushNotificationModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<Map<String, String>> _buildHeaders() async {
    final token = await AuthLocalStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final headers = await _buildHeaders();

      final response = await http.get(
        Uri.parse('${NetworkConfig.baseURL}/farmer/push-notifications'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['notifications'] != null) {
          final list = (data['notifications'] as List)
              .map((e) => PushNotificationModel.fromJson(e))
              .toList();
          notifications.assignAll(list);
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final headers = await _buildHeaders();

      await http.post(
        Uri.parse(
            '${NetworkConfig.baseURL}/farmer/push-notifications/$notificationId/read'),
        headers: headers,
      );

      // Update local state
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final old = notifications[index];
        notifications[index] = PushNotificationModel(
          id: old.id,
          title: old.title,
          body: old.body,
          image: old.image,
          type: old.type,
          data: old.data,
          readAt: DateTime.now().toIso8601String(),
          createdAt: old.createdAt,
        );
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Group notifications by date label (Today, Yesterday, Earlier)
  Map<String, List<PushNotificationModel>> get groupedNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<PushNotificationModel>> grouped = {};

    for (final n in notifications) {
      final dt = n.createdDateTime;
      String label;
      if (dt == null) {
        label = 'Earlier';
      } else {
        final date = DateTime(dt.year, dt.month, dt.day);
        if (date == today) {
          label = 'Today';
        } else if (date == yesterday) {
          label = 'Yesterday';
        } else {
          label = 'Earlier';
        }
      }
      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(n);
    }

    return grouped;
  }
}
