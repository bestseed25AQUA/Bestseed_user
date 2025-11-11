import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Logout success, clear local storage
        await AuthLocalStorage.clear();
        CustomToast.success("Logged out successfully");

        // Navigate to login
        Get.offAll(() => const LoginWithMobileScreen());
      } else {
        CustomToast.error(
          "Logout failed  ${response.reasonPhrase}",
        );
      }
    } catch (e) {
      debugPrint("Logout Error  ");
      CustomToast.error("Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }
}
