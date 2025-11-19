import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_tracking_model.dart';

final dummyJson = {
  "vehicles": [
    {
      "hatchery_name": "Super Hatchery Farm",
      "category_name": "Broiler Chicks",
      "images": [
        "https://example.com/v1_img1.jpg",
        "https://example.com/v1_img2.jpg",
      ],
      "customer": {"name": "Vicky Patel", "mobile": "852885555"},
      "booking_details": {
        "id": 101,
        "pieces": "5000",
        "unit_name": "PCS",
        "available_date": "2025-02-15",
      },
      "driver_details": {
        "driver_name": "Ramesh Kumar",
        "driver_mobile": "9876543210",
        "vehicle_number": "GJ05AB1234",
      },
      "sms_to": "9876543210",
    },
    {
      "hatchery_name": "Premium Hatchery Pvt Ltd",
      "category_name": "Layer Chicks",
      "images": ["https://example.com/v2_img1.jpg"],
      "customer": {"name": "Suresh Yadav", "mobile": "9090909090"},
      "booking_details": {
        "id": 102,
        "pieces": "3500",
        "unit_name": "PCS",
        "available_date": "2025-02-16",
      },
      "driver_details": {
        "driver_name": "Mahesh Sen",
        "driver_mobile": "9090909090",
        "vehicle_number": "RJ14CD9988",
      },
      "sms_to": "9090909090",
    },
  ],
};

class VehicleTrackingController extends GetxController {
  RxBool isLoading = false.obs;
  RxList<VehicleTrackingModel> vehicleList = <VehicleTrackingModel>[].obs;

  @override
  void onInit() {
    loadDummyData();
    // fetchVehicleList();
    super.onInit();
  }

  Future<void> fetchVehicleList() async {
    try {
      isLoading.value = true;

      final headers = await buildHeader();

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/vehicle_list",
        headers: headers,
      );

      // Debug response
      print("Vehicle List Status: ${response.statusCode}");
      print("Vehicle List Body: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Extract list safely
        if (body['vehicles'] != null && body['vehicles'] is List) {
          List vehiclesJson = body['vehicles'];

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

  void loadDummyData() {
    final dummyJson = {
      "vehicles": [
        {
          "hatchery_name": "Super Hatchery Farm",
          "category_name": "Broiler Chicks",
          "images": [
            "https://example.com/v1_img1.jpg",
            "https://example.com/v1_img2.jpg",
          ],
          "customer": {"name": "Vicky Patel", "mobile": "852885555"},
          "booking_details": {
            "id": 101,
            "pieces": "5000",
            "unit_name": "PCS",
            "available_date": "2025-02-15",
          },
          "driver_details": {
            "driver_name": "Ramesh Kumar",
            "driver_mobile": "9876543210",
            "vehicle_number": "GJ05AB1234",
          },
          "sms_to": "9876543210",
        },
        {
          "hatchery_name": "Premium Hatchery Pvt Ltd",
          "category_name": "Layer Chicks",
          "images": ["https://example.com/v2_img1.jpg"],
          "customer": {"name": "Suresh Yadav", "mobile": "9090909090"},
          "booking_details": {
            "id": 102,
            "pieces": "3500",
            "unit_name": "PCS",
            "available_date": "2025-02-16",
          },
          "driver_details": {
            "driver_name": "Mahesh Sen",
            "driver_mobile": "9090909090",
            "vehicle_number": "RJ14CD9988",
          },
          "sms_to": "9090909090",
        },
      ],
    };

    vehicleList.value = (dummyJson['vehicles'] as List)
        .map((e) => VehicleTrackingModel.fromJson(e))
        .toList();
  }
}
