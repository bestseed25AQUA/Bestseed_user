import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';
import 'package:seedsuser/app/vehicle_tracking/model/specific_vehicle_tracking_response.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_booking_detail_model.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_tracking_model.dart';

class VehicleTrackingController extends GetxController {
  RxBool isLoading = false.obs;
  RxList<VehicleTrackingModel> vehicleList = <VehicleTrackingModel>[].obs;

  Future<void> fetchVehicleList() async {
    try {
      isLoading.value = true;

      final headers = await buildHeader();

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/vehicle_available_booking",
        headers: headers,
      );
      print("Vehicle List Status: ${response.statusCode}");
      print("Vehicle List Body: ${response.body}");
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        /// NEW FIX ✔ Use "data" instead of "vehicles"
        if (body['data'] != null && body['data'] is List) {
          List vehiclesJson = body['data'];

          vehicleList.value = vehiclesJson
              .map((item) => VehicleTrackingModel.fromJson(item))
              .toList();
        } else {
          vehicleList.clear();
        }
      } else {
        print("❌ API Failed: ${response.statusCode}");
        vehicleList.clear();
      }
    } catch (e, s) {
      print("❌ Error in fetchVehicleList: $e");
      print(s);
      vehicleList.clear();
    } finally {
      isLoading.value = false;
    }
  }

  //////////////
  RxBool isDetailLoading = false.obs;

  Rx<VehicleBookingDetailModel?> bookingDetail = Rx<VehicleBookingDetailModel?>(
    null,
  );

  /// 🔥 Fetch Vehicle Booking Detail
  Future<void> fetchVehicleBookingDetail(String id) async {
    try {
      isDetailLoading.value = true;

      final headers = await buildHeader();

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/vehicle_booking_detail/$id",
        headers: headers,
      );

      print("Booking Detail Status: ${response.statusCode}");
      print("Booking Detail Body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body["data"] != null) {
          bookingDetail.value = VehicleBookingDetailModel.fromJson(
            body["data"],
          );
        } else {
          // bookingDetail.value = dummyBookingDetail(); // fallback
        }
      } else {
        // bookingDetail.value = dummyBookingDetail(); // fallback
      }
    } catch (e, s) {
      print("❌ Error in booking detail API: $e");
      print(s);
      // bookingDetail.value = dummyBookingDetail(); // fallback
    } finally {
      isDetailLoading.value = false;
      //  bookingDetail.value = dummyBookingDetail();
    }
  }

  Future<void> cancelBooking(String id, String reason) async {
    try {
      // isDetailLoading(true);
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        barrierDismissible: false,
      );
      final headers = await buildHeader();

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/vehicle_booking_delete/$id",
        headers: headers,
        body: {"booking_id": "$id", "reason_code": "$reason"},
      );
      print('========+++++++==============');
      print(response.body.toString());

      final body = jsonDecode(response.body);
      if ( response.statusCode == 200) {
        CustomToast.success('Cancelled');
        isDetailLoading(false);
        await fetchVehicleBookingDetail(id);
        await fetchVehicleList();
      } else {
        CustomToast.error('Failed to Cancel');
      }
    } catch (e, s) {
      print('======+++++++========');
      print(e.toString());
      print(s.toString());
      CustomToast.error('Failed to Cancel');
      isDetailLoading(false);
    } finally {
       if (isDetailLoading.value) isDetailLoading(false);
      Get.back();
    }
  }

  //////////

  RxBool specificLoading = false.obs;
  Rx<SpecificVehicleTrackingResponse?> specificVehicle =
      Rx<SpecificVehicleTrackingResponse?>(null);

  Future<void> fetchSpecificVehicleTracking(String vehicleId, {bool silent = false}) async {
    try {
      if (!silent) specificLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/vehicle_tracking/$vehicleId",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        specificVehicle.value = SpecificVehicleTrackingResponse.fromJson(body);
      } else {
        print("❌ Failed to fetch tracking");
      }
    } catch (e, s) {
      print("❌ Error: $e");
      print(s);
    } finally {
      if (!silent) specificLoading.value = false;
    }
  }

}
