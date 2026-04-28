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
      // vehicleListDummyData();
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
      if (!silent) {
        specificLoading.value = true;
        specificVehicle.value = null; // Clear stale data so a new screen never shows the previous booking
      }

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

  void vehicleListDummyData() {
    final dummyJson = {
      "success": true,
      "message": "Vehicle availability bookings fetched successfully",
      "data": [
        {
          "id": "1",
          "booking_id": "324646",
          "time": "12:30 PM",
          "date": "25/11/2025",
          "hatchery_name": "Seven Star Hatchery",
          "category_name": "Syaqua",
          "status": "Pending",
          "pickup_location": "Seven Star Hatchery",
          "drop_location": "Kakinada, Andhra Pradesh",
          "quantity": "1400 Pieces",
        },
        {
          "id": "2",
          "booking_id": "324647",
          "time": "03:10 PM",
          "date": "26/11/2025",
          "hatchery_name": "Blue Ocean Hatchery",
          "category_name": "Golda",
          "status": "Confirmed",
          "pickup_location": "Blue Ocean Hatchery",
          "drop_location": "Vijayawada",
          "quantity": "2000 Pieces",
        },
      ],
    };

    /// Correct key → body["data"]
    vehicleList.value = (dummyJson['data'] as List)
        .map((e) => VehicleTrackingModel.fromJson(e))
        .toList();
  }

  void specificVehicleTrackingDummyData() {
    final dummyResponse = {
      "status": true,
      "message": "Tracking data fetched successfully",
      "data": {
        "vehicle_id": 14,
        "booking_id": 1,

        "pickup": {
          "name": "Seven Star Hatchery",
          "lat": 17.3850,
          "lng": 78.4867,
        },

        "drop": {"name": "Amalapuram", "lat": 16.5775, "lng": 82.0061},

        "driver_location": {
          "name": "Near Kakinada",
          "lat": 16.9891,
          "lng": 82.2475,
        },

        "driver_details": {
          "driver_name": "Ramesh",
          "driver_phone": "+91xxxxxxxxxx",
          "vehicle_number": "TSN05656",
          "driver_image": "https://example.com/profile.png",
        },

        "delivery_updates": {
          "delivery_expected": "27/06/2025",
          "note":
              "We’ve received your booking. Within a few days, we will assign your vehicle",
        },

        "timeline": [
          {
            "title": "Pickup started from",
            "subtitle": "Seven Star Hatchery",
            "time": "2:30 PM",
            "date": "24/06/2025",
            "status": "completed",
          },
          {
            "title": "Kakinada",
            "subtitle": "",
            "time": "10:30 PM",
            "date": "24/06/2025",
            "status": "completed",
          },
          {
            "title": "Vizag",
            "subtitle": "",
            "time": "-",
            "date": "24/06/2025",
            "status": "pending",
          },
          {
            "title": "Vijayawada",
            "subtitle": "",
            "time": "-",
            "date": "",
            "status": "pending",
          },
          {
            "title": "Destination",
            "subtitle": "Amalapuram",
            "time": "-",
            "date": "",
            "status": "pending",
          },
        ],
      },
    };

    specificVehicle.value = SpecificVehicleTrackingResponse.fromJson(
      dummyResponse,
    );

    specificLoading.value = false;
  }
}

// VehicleBookingDetailModel dummyBookingDetail() {
//   return VehicleBookingDetailModel(
//     driverId: 1,
//     bookingId: 1,
//     status: "Confirmed",
//     statusDescription:
//         "We'll notify you when the driver assigned and start their journey",
//     pickupDetails: PickupDrop(
//       location: "Dummy Hatchery",
//       date: "24/11/2025",
//       time: "10:20 AM",
//     ),
//     dropDetails: PickupDrop(
//       location: "Dummy Andhra Pradesh",
//       date: "26/11/2025",
//       time: "01:20 PM",
//     ),
//     vehicleDetails: VehicleDetails(
//       hatchery: "Dummy Rama Hatchery",
//       brand: "Dummy Brand",
//       qty: "5 tones",
//       bookingDate: "20/11/2025",
//       bookingTime: "05:30 PM",
//     ),
//     bookingStatus: [
//       BookingStatusStep(
//         title: "confirm",
//         status: 1,
//         date: "Mon,21-11-2025",
//         time: "12:23 PM",
//       ),
//       BookingStatusStep(
//         title: "driver_assigned",
//         date: "Mon,21-11-2025",
//         time: "12:23 PM",
//         status: 1,
//       ),
//       BookingStatusStep(
//         title: "in_progress",
//         date: "Mon,21-11-2025",
//         time: "12:23 PM",
//         status: 0,
//       ),
//       BookingStatusStep(
//         title: "delivered",
//         date: "Mon,21-11-2025",
//         time: "12:23 PM",
//         status: 0,
//       ),
//     ],
//   );
// }
