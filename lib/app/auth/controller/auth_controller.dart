import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:seedsuser/app/auth/view/otp_verification_screen.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class AuthController extends GetxController {
  // Loading states
  RxBool isLoading = false.obs;
  RxBool isOtpSent = false.obs;

  // OTP fields
  RxString phoneNumber = ''.obs;
  RxString otp = ''.obs;

  // Send OTP
  Future<void> sendOtp() async {
    try {
      isLoading.value = true;
      final body = {"mobile": phoneNumber.value};

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/login",
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint("Send OTP Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        Get.to(
          () => OtpVerificationScreen(
            phoneNumber: phoneNumber.value,
            otp: data['otp_debug'].toString(),
          ),
        );

        isOtpSent.value = true;
        CustomToast.success("OTP sent successfully!");
      } else {
        CustomToast.error("Server error ");
      }
    } catch (e, s) {
      debugPrint("Send OTP Error  ");
      debugPrint("Send OTP Error: $s");
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
