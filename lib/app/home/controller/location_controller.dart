import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class LocationController extends GetxController {
  Rx<bool> allLocationLoading = true.obs;
  RxMap<dynamic, dynamic> selectedLocation = {}.obs;
  RxList allLocations = [].obs;
  Future<void> getAllLocation() async {
    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/locations/all",
        headers: await buildHeader(),
      );
      print('============');
      print("${NetworkConfig.baseURL}/farmer/locations/all");
      print(response.statusCode);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        try {
          selectedLocation?.value = data['locations'].first;
          allLocations.value = List.generate(
            data['locations'].length,
            (index) => data['locations'][index],
          );
        } catch (e) {
          print(e.toString());
        }

        print('========all locaitons=======');
        print(data.toString());
      } else {
        print('else error');
      }
    } catch (e, s) {
      print(e);
      print(s);
      CustomToast.error("Something went wrong: $e");
    } finally {
      allLocationLoading.value = true;
    }
  }

  Future<void> addAllLocation({
    required String latitude,
    required String longitude,
    required String locationName,
    required String farmerId,
  }) async {
    try {
      String endPoint =  "${NetworkConfig.baseURL}/farmer/locations_farmer";
      Map<String,String> body = {
          "location_name": locationName,
          "longitude": longitude,
          "latitude": latitude,
          "farmer_id": farmerId,
        };
        print(endPoint);
        print(body);
      final response = await postRequest(
        endPoint: endPoint,
        headers: await buildHeader(),
        body: body,
      );
      print('============');
      print("${NetworkConfig.baseURL}/farmer/locations_farmer");
      print(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        try {
          getAllLocation();
        } catch (e) {
          print(e.toString());
        }

        print('========all locaitons=======');
        print(data.toString());
      } else {
        print('else error');
      }
    } catch (e, s) {
      print(e);
      print(s);
      CustomToast.error("Something went wrong: $e");
    } finally {
      allLocationLoading.value = true;
    }
  }
}
