import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/notification/model/push_notification_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';

class NotificationController extends GetxController {
  final notifications = <PushNotificationModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final _currentPage = 1.obs;
  final _lastPage = 1.obs;
  final scrollController = ScrollController();

  bool get hasMore => _currentPage.value < _lastPage.value;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    fetchNotifications();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore.value &&
        hasMore) {
      loadMore();
    }
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
      _currentPage.value = 1;
      final headers = await _buildHeaders();

      final response = await http.get(
        Uri.parse(
            '${NetworkConfig.baseURL}/farmer/push-notifications?page=1&per_page=10'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['notifications'] != null) {
          final list = (data['notifications'] as List)
              .map((e) => PushNotificationModel.fromJson(e))
              .toList();
          notifications.assignAll(list);
          _currentPage.value = data['current_page'] ?? 1;
          _lastPage.value = data['last_page'] ?? 1;
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      final nextPage = _currentPage.value + 1;
      final headers = await _buildHeaders();

      final response = await http.get(
        Uri.parse(
            '${NetworkConfig.baseURL}/farmer/push-notifications?page=$nextPage&per_page=10'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['notifications'] != null) {
          final list = (data['notifications'] as List)
              .map((e) => PushNotificationModel.fromJson(e))
              .toList();
          notifications.addAll(list);
          _currentPage.value = data['current_page'] ?? nextPage;
          _lastPage.value = data['last_page'] ?? 1;
        }
      }
    } catch (e) {
      debugPrint('Error loading more notifications: $e');
    } finally {
      isLoadingMore.value = false;
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
          module: old.module,
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
