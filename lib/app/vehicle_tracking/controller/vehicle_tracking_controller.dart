import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';
import 'package:seedsuser/app/vehicle_tracking/model/specific_vehicle_tracking_response.dart';
import 'package:seedsuser/app/vehicle_tracking/model/vehicle_tracking_model.dart';

class VehicleTrackingController extends GetxController {
  RxBool isLoading = false.obs;
  RxList<VehicleTrackingModel> vehicleList = <VehicleTrackingModel>[].obs;
  var selectedMonth = ''.obs;
  var selectedYear = ''.obs;
  var selectedDate = ''.obs;
  Future<void> fetchVehicleList() async {
    try {
      isLoading.value = true;

      // Build Query
      String query = "";
      if (selectedMonth.value.isNotEmpty) {
        query += "?month=${selectedMonth.value}";
      }
      if (selectedYear.value.isNotEmpty) {
        query += query.isEmpty
            ? "?year=${selectedYear.value}"
            : "&year=${selectedYear.value}";
      }
      if (selectedDate.value.isNotEmpty) {
        query += query.isEmpty
            ? "?date=${selectedDate.value}"
            : "&date=${selectedDate.value}";
      }

      final headers = await buildHeader();

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/vehicle_list$query",
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
      vehicleListDummyData();
      isLoading.value = false;
    }
  }

  RxBool specificLoading = false.obs;
  Rx<SpecificVehicleTrackingResponse?> specificVehicle =
      Rx<SpecificVehicleTrackingResponse?>(null);

  Future<void> fetchSpecificVehicleTracking(String vehicleId) async {
    try {
      specificLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/vehicle_tracking/$vehicleId",
        headers: await buildHeader(),
      );

      print("Specific Vehicle Res: ${response.body}");

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
      if (specificVehicle.value == null) {
        specificVehicleTrackingDummyData();
      }
      specificLoading.value = false;
    }
  }

  void vehicleListDummyData() {
    final dummyJson = {
      "vehicles": [
        {
          "hatchery_name": "Super Hatchery Farm",
          "category_name": "Broiler Chick",
          "images": [
            "https://images.pexels.com/photos/112460/pexels-photo-112460.jpeg", // Truck 1
            "https://images.pexels.com/photos/2199293/pexels-photo-2199293.jpeg", // Truck 2
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
          "images": [
            "https://images.pexels.com/photos/19366773/pexels-photo-19366773.jpeg", // Truck 3
          ],
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

  void specificVehicleTrackingDummyData() {
    final dummyResponse = {
      "status": true,
      "message": "Tracking data fetched successfully",
      "data": {
        "pickup": {"name": "Hyderabad", "lat": 17.3850, "lng": 78.4867},
        "drop": {"name": "Bhopal", "lat": 23.2599, "lng": 77.4126},

        "driver_location": {
          "name": "Nagpur Highway Checkpost",
          "lat": 21.1458,
          "lng": 78.0060,
        },

        "delivery_updates": {
          "order_placed_date": "23/06/2025",
          "order_placed_time": "10:30 AM",
          "delivery_expected": "27/06/2025",
        },

        "timeline": [
          {
            "title": "Started from",
            "subtitle": "Hyderabad Depot",
            "time": "6:00 AM",
            "date": "24/06/2025",
          },
          {
            "title": "On the way",
            "subtitle": "Near Nagpur Highway",
            "time": "2:30 PM",
            "date": "24/06/2025",
          },
          {
            "title": "Expected Drop",
            "subtitle": "Bhopal Warehouse",
            "time": "10:30 AM",
            "date": "27/06/2025",
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
