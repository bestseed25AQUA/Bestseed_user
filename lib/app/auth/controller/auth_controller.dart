import 'dart:async';
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

      // Decoded defensively, and no longer before the status check: pointed at
      // the wrong host this returns an HTML error page, and jsonDecode threw on
      // it — turning "wrong server" into the catch below rather than a message
      // the user could act on.
      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) data = decoded;
      } catch (_) {
        // Not JSON — fall through to the generic message below.
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.to(
          () => OtpVerificationScreen(
            phoneNumber: phoneNumber.value,
          ),
        );

        isOtpSent.value = true;
        CustomToast.success("OTP sent successfully!");
      } else {
        // Show the error message from API response
        final errorMessage = data['message'] ?? "Failed to send OTP. Please try again.";
        CustomToast.error(errorMessage);
      }
    } catch (e, s) {
      debugPrint("Send OTP Error: $e");
      debugPrint("Send OTP Error: $s");

      // CustomToast, not Get.snackbar.
      //
      // Get.snackbar needs an Overlay from GetMaterialApp's navigator, and the
      // login screen is reached before one is in scope here — so a plain
      // network timeout became an unhandled "No Overlay widget found"
      // exception on top of the failure it was trying to report. Every other
      // failure path in this app already uses CustomToast, which is a native
      // toast and needs no ancestor.
      //
      // And a message the farmer can act on, rather than the raw exception:
      // "TimeoutException: I'm Facing Network Issue" told them nothing.
      CustomToast.error(
        e is TimeoutException
            ? 'Could not reach the server. Check your connection and try again.'
            : 'Could not send the OTP. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
