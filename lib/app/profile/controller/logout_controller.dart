import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:seedsuser/app/announcement/controller/announcement_controller.dart';
import 'package:seedsuser/app/auth/view/login_screen.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/utils/network_config.dart';

class LogoutController extends GetxController {
  var isLoading = false.obs;

  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Get token from storage
      String? token = await AuthLocalStorage.getToken();
      if (token == null || token.isEmpty) {
        CustomToast.error("No token found");
        return;
      }

      final url = Uri.parse("${NetworkConfig.baseURL}/farmer/logout");

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Clear local storage and navigate to login regardless of API response
      // (even if token is expired/invalid, we should still log out locally)
      await AuthLocalStorage.clear();
      _clearAnnouncements();

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success("Logged out successfully");
      }

      Get.offAll(() => const LoginWithMobileScreen());
    } catch (e) {
      debugPrint("Logout Error: $e");
      // Even if API call fails (network error etc), clear token and go to login
      await AuthLocalStorage.clear();
      _clearAnnouncements();
      Get.offAll(() => const LoginWithMobileScreen());
    } finally {
      isLoading.value = false;
    }
  }

  /// The announcement controller is permanent, so its list and unread badge
  /// would otherwise carry over to whoever logs in next on this device.
  void _clearAnnouncements() {
    if (Get.isRegistered<AnnouncementController>()) {
      Get.find<AnnouncementController>().reset();
    }
  }
}
