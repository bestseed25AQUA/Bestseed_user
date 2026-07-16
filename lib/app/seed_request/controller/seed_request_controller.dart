import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/safe_back.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';  

class SeedRequestController extends GetxController {
  var isLoading = false.obs;
  var isBooking = false.obs;

  /// 🚚 Send Seed Request API
  Future<void> sendSeedRequest({
    required int categoryId,
    required String hatcheryName,
    required String name,
    required String mobile,
    required int pieces,
    required String droppingLocation,
    required String packingDate,
  }) async {
    try {
      isBooking.value = true;

      int? farmerId;
      try {
        final profileController = Get.find<ProfileController>();
        farmerId = profileController.profile.value?.id;
      } catch (e) {
        print("ProfileController not found: $e");
      }

      final body = {
        "category_id": categoryId,
        "hatchery_name": hatcheryName,
        "name": name,
        "mobile": mobile,
        "quantity": pieces,
        "dropping_location": droppingLocation,
        "packing_date": packingDate,
        if (farmerId != null) "farmer_id": farmerId,
      };
      print(body);

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/seed-request",
        body: body,
        headers: await buildHeader(),
      );

print("Seed Request Response: ${response.body}");
print("Status Code: ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        safeBack();

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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => safeBack(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          radius: 16.0,
        );

        CustomToast.success(result["message"] ?? "Request sent successfully!");
      } else {
        CustomToast.error("Booking failed ");
        print("Booking failed: ${response.body}");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
      print("Send Seed Request Error: $e");
    } finally {
      isBooking.value = false;
    }
  }
}
