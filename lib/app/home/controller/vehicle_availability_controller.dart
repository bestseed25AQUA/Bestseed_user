

import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/vehicle_availability_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class VehicleController extends GetxController {
  var isLoading = false.obs;
  var vehicles = <Vehicle>[].obs;
  var filteredVehicles = <Vehicle>[].obs;
  var isBooking = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchVehicles();
  }

  /// Fetch all available vehicles
  Future<void> fetchVehicles() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/vehicle-availability",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        VehicleAvailabilityModel vehicleData =
            VehicleAvailabilityModel.fromJson(data);
        vehicles.value = vehicleData.vehicles;
        filteredVehicles.value = vehicleData.vehicles;
      } else {
        CustomToast.error("Failed to fetch vehicles ");
      }
    } catch (e,s) { 
      print(e.toString());
      print(s.toString());
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }

  /// Search by hatchery name
  void searchVehicle(String query) {
    if (query.isEmpty) {
      filteredVehicles.value = vehicles;
    } else {
      filteredVehicles.value = vehicles
          .where(
            (v) => v.hatcheryName.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  /// 🚚 Book Vehicle API
  Future<bool> bookVehicle({
    required String vehicleNumber,
    required String hatcheryName,
    required String name,
    required String mobile,
    required String date,
    required String deliveryAddress,
    required int seedQuantity,
  }) async {
    try {
      isBooking.value = true;

      final body = {
        "vehicle_number": vehicleNumber,
        "hatchery_name": hatcheryName,
        "name": name,
        "mobile": mobile,
        "date": date,
        "delivery_address": deliveryAddress,
        "seed_quantity": seedQuantity,
      };

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/book-vehicle",
        body: body,
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // final result = json.decode(response.body);
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
                height: 109,
                width: 109,
              ),
              const SizedBox(height: 16),
              Text(
                'Your request was recorded', // You can localize this using AppLocalizations
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          radius: 16.0,
        );
        CustomToast.success("Vehicle booked successfully!");
      } else {
        CustomToast.error("Booking failed ");
      }
    } catch (e, s) {
      print(s.toString());
      CustomToast.error("Something went wrong  ");
    } finally {
      isBooking.value = false;
    }
    return false;
  }

  void loadDummyVehicles() {
    final dummyJson = {
      "status": true,
      "vehicles": [
        {
          "vehicle_number": "GJ05AB1234",
          "driver_name": "Ramesh Kumar",
          "driver_mobile": "9876543210",
          "vehicle_images": [
            "https://images.pexels.com/photos/170811/pexels-photo-170811.jpeg",
            "https://images.pexels.com/photos/210019/pexels-photo-210019.jpeg",
            "https://images.pexels.com/photos/358070/pexels-photo-358070.jpeg",
          ],
          "hatchery_name": "Super Hatchery Farm",
          "hatchery_location": "Palanpur, Gujarat",
          "vechile_location_tracking": [
            "Puducherry",
            "Vijayawada",
            "Malappuram",
          ],
          "start_date": "2025-01-15T10:30:00.000Z",
          "end_date": "2025-01-15T18:45:00.000Z",
          "available_space": 150,
          "call_now": "9876543210",
          "whatsapp": "9876543210",
        },
        {
          "vehicle_number": "RJ14CD9988",
          "driver_name": "Suresh Patel",
          "driver_mobile": "9090909090",
          "vehicle_images": [
            "https://images.pexels.com/photos/358070/pexels-photo-358070.jpeg",
            "https://images.pexels.com/photos/112460/pexels-photo-112460.jpeg",
          ],
          "hatchery_name": "Premium Hatchery Pvt Ltd",
          "vechile_location_tracking": [
            "Puducherry",
            "Vijayawada",
            "Malappuram",
          ],
          "start_date": "2025-01-16T08:00:00.000Z",
          "end_date": null,
          "available_space": 200,
          "call_now": "9090909090",
          "whatsapp": "9090909090",
        },
      ],
    };

    /// Convert JSON → Model
    VehicleAvailabilityModel dummyData = VehicleAvailabilityModel.fromJson(
      dummyJson,
    );

    /// Assign to controller variables
    vehicles.value = dummyData.vehicles;
    filteredVehicles.value = dummyData.vehicles;
  }
}
