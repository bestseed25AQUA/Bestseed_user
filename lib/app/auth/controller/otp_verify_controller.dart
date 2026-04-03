import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:http/http.dart' as http;
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/dashboard/dashboard.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/notification/notification_service.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class OtpVerifyController extends GetxController {
  // Observables
  RxBool isLoading = false.obs;
  RxBool isResending = false.obs;

  RxString phoneNumber = ''.obs;
  RxString otp = ''.obs;

  // Timer for resend OTP (2 minutes = 120 seconds)
  RxInt resendTimer = 0.obs;
  Timer? _timer;

  bool get canResend => resendTimer.value == 0;

  void startResendTimer() {
    resendTimer.value = 120; // 2 minutes
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer.value > 0) {
        resendTimer.value--;
      } else {
        timer.cancel();
      }
    });
  }

  String get formattedTimer {
    final minutes = (resendTimer.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (resendTimer.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // Resend OTP
  Future<void> resendOtp() async {
    try {
      isResending.value = true;

      final body = {
        "mobile": phoneNumber.value,
      };

      http.Response response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/resend-otp",
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint("Resend OTP Response: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        CustomToast.success(data["message"] ?? "OTP resent successfully");
        startResendTimer(); // Start 2-minute countdown
      } else if (response.statusCode == 429) {
        // Rate limited - start timer to show remaining time
        startResendTimer();
        CustomToast.error(data['message'] ?? "Please wait before requesting a new OTP.");
      } else {
        // Show the error message from API response
        final errorMessage = data['message'] ?? "Failed to resend OTP. Please try again.";
        CustomToast.error(errorMessage);
      }
    } catch (e) {
      debugPrint("Resend OTP Error  ");
      CustomToast.error(e.toString());
    } finally {
      isResending.value = false;
    }
  }

  // Verify OTP
  Future<void> verifyOtp() async {
    try {
      isLoading.value = true;

      final body = {"mobile": phoneNumber.value, "otp_code": otp.value};

      http.Response response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/verify-otp",
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint("Verify OTP Response: ${response.body}");
       

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract token — check common response structures
        final token = data['token'] ?? data['access_token'] ?? data['data']?['token'];
        final mobile = data['mobile'] ?? data['data']?['mobile'] ?? phoneNumber.value;

        debugPrint("=======token at login time=========");
        debugPrint('=====token: $token====');

        // Save token & mobile locally
        if (token != null) {
          await AuthLocalStorage.saveUserData(
            token: token.toString(),
            mobile: mobile.toString(),
          );
          debugPrint("Token saved successfully");
        } else {
          debugPrint("WARNING: No token found in response! Full response: ${response.body}");
        }

        CustomToast.success("OTP verified successfully");

        // Register FCM token with server after login
        NotificationService().registerToken();

        Get.offAll(() => DashboardScreen());
      } else {
        // Show the error message from API response
        final errorMessage = data['message'] ?? "Invalid OTP. Please try again.";
        CustomToast.error(errorMessage);
      }
    } catch (e) {
      debugPrint("Verify OTP Error  ");
      CustomToast.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
