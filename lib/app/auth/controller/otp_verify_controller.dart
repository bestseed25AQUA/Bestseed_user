import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/common/local_storage.dart';
import 'package:seedsuser/app/dashboard/dashboard.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class OtpVerifyController extends GetxController {
  // Observables
  RxBool isLoading = false.obs;
  RxBool isResending = false.obs;

  RxString phoneNumber = ''.obs;
  RxString otp = ''.obs;

  // Resend OTP
  Future<void> resendOtp() async {
    try {
      isResending.value = true;

      final body = {
        "phone": phoneNumber.value, // change key as per your API
      };

      http.Response response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/resend-otp",
        body: body,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint("Resend OTP Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == true) {
          CustomToast.success("OTP resent successfully");
        } else {
          CustomToast.error(data["message"] ?? "Unable to resend OTP");
        }
      } else {
        CustomToast.error("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Resend OTP Error: $e");
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Save token & mobile locally
        if (data['token'] != null) {
          await AuthLocalStorage.saveUserData(
            token: data['token'],
            mobile: data['mobile'] ?? phoneNumber.value,
          );
        }

        CustomToast.success("OTP verified successfully");

        Get.offAll(() => DashboardScreen());
      } else {
        CustomToast.error("Server error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Verify OTP Error: $e");
      CustomToast.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
