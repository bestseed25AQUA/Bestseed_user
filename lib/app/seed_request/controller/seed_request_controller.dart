import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class SeedRequestController extends GetxController {
  var isLoading = false.obs;
  var isBooking = false.obs; // 👈 Booking loader

  /// 🚚 Send Seed Request API
  Future<void> sendSeedRequest({
    required int farmerId,
    required int categoryId,
    required int brandId,
    required String name,
    required String mobile,
    required int quantity,
    required String droppingLocation,
    required String packingDate,
  }) async {
    try {
      isBooking.value = true;

      final body = {
        "farmer_id": farmerId,
        "category_id": categoryId,
        "brand_id": brandId,
        "name": name,
        "mobile": mobile,
        "quantity": quantity,
        "dropping_location": droppingLocation,
        "packing_date": packingDate,
      };

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/seed-request",
        body: body,
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        Get.back();

        Get.defaultDialog(
          barrierDismissible: true,
          title: '',
          contentPadding: const EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/SealCheck.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 24),
              Text(
                'Your \nrequest was sent',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We will notify you within 24 Hours',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          radius: 16.0,
        );

        CustomToast.success(result["message"] ?? "Request sent successfully!");
      } else {
        CustomToast.error("Booking failed: ${response.statusCode}");
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {
      isBooking.value = false;
    }
  }
}
