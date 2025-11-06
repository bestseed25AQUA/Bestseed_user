import 'dart:convert';

import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class LocationController extends GetxController {
  var allLocationLoading = false.obs;
  var selectedLocation = <String, dynamic>{}.obs;
  var allLocations = <Map<String, dynamic>>[].obs;

  // RxString selectedLatiude = ''.obs;
  // RxString selectedLongitude = ''.obs;
  RxString selectedCity = ''.obs;
  RxString selectedStreet = ''.obs;
  RxString selectedLatiude = ''.obs;
  RxString selectedLongitude = ''.obs;

  Future<void> getAllLocation() async {
    allLocationLoading.value = true;

    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/locations/all",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Assign all locations
        allLocations.assignAll(
          List<Map<String, dynamic>>.from(data['locations']),
        );

        // Set default selected location only if empty
        // if (selectedLocation.isEmpty) {
        //   selectedLocation.assignAll(data['locations'].first);
        // }
      }
    } catch (e, s) {
      print(e);
      print(s);
      CustomToast.error("Something went wrong: $e");
    } finally {
      allLocationLoading.value = false;
    }
  }

  Future<void> addAllLocation({
    required String latitude,
    required String longitude,
    required String locationName,
    required String farmerId,
  }) async {
    try {
      String endPoint = "${NetworkConfig.baseURL}/farmer/locations_farmer";

      Map<String, String> body = {
        "location_name": locationName,
        "longitude": longitude,
        "latitude": latitude,
        "farmer_id": farmerId,
      };

      final response = await postRequest(
        endPoint: endPoint,
        headers: await buildHeader(),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await getAllLocation();
      }
    } catch (e, s) {
      print(e);
      print(s);
      CustomToast.error("Something went wrong: $e");
    }
  }
}
