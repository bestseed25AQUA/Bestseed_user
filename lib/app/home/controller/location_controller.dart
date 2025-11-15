import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class LocationController extends GetxController {

  var allLocationLoading = false.obs;

  /// Store all locations list
  var allLocations = <Map<String, dynamic>>[].obs;

  /// Selected location details
  var selectedLocation = <String, dynamic>{}.obs;
  RxString selectedCity = ''.obs;
  RxString selectedFullAddress = ''.obs;
  RxString selectedLatiude = ''.obs;
  RxString selectedLongitude = ''.obs;
  RxString selectedLocationId = ''.obs;

  final ProfileController profileController = Get.put(ProfileController());

  /// Get All Saved Locations
  Future<void> getAllLocation() async {
    allLocationLoading.value = true;

    try {
      final response = await getRequest(
        ///${profileController.profile.value?.id}
        endPoint:
            "${NetworkConfig.baseURL}/farmer/locations/history",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true && data["data"] != null) {
          allLocations.assignAll(List<Map<String, dynamic>>.from(data['data']));
          // if (allLocations.isNotEmpty) {
          //   selectedLocation.assignAll(allLocations.first);
          //   selectedCity.value = selectedLocation["location_name"] ?? "";
          //   selectedLatiude.value = selectedLocation["latitude"] ?? "";
          //   selectedLongitude.value = selectedLocation["longitude"] ?? "";
          // }
        } else {
          allLocations.clear();
        }
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      allLocationLoading.value = false;
    }
  }

  /// ✅ Add New Location
  Future<dynamic> addLocation({
    required String latitude,
    required String longitude,
    required String locationName,
    required String farmerId,
    required String fullAddress,
  }) async {
    try {
      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/locations_farmer",
        headers: await buildHeader(),
        body: {
          "location_name": locationName,
          "latitude": latitude,
          "longitude": longitude,
          "full_address": fullAddress,
          "farmer_id": farmerId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success("Location Saved");
        print('============++++++++++++================');
        print(jsonDecode(response.body.toString()));
        return jsonDecode(response.body.toString());
        // await getAllLocation();
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    }
  }

  /// ✅ Update existing location
  /// Example: PUT /farmer/locations/{id}
  Future<void> updateLocation({
    required String id,
    String? latitude,
    String? longitude,
    required String locationName,
    required String fullAddress,
  }) async {
    try {
      final body = <String, dynamic>{
        // backend may accept latitude/longitude but location_name is required
        "location_name": locationName,
        "full_address": fullAddress,
      };

      if (latitude != null) body["latitude"] = latitude;
      if (longitude != null) body["longitude"] = longitude;

      final response = await putRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/locations/$id",
        headers: await buildHeader(),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success("Location updated successfully");
        await getAllLocation();
      } else {
        CustomToast.error("Failed to update location");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    }
  }

  /// ✅ Search Location
  RxBool isSearching = false.obs;
  var searchedLocations = <Map<String, dynamic>>[].obs;

  Future<void> searchLocation(String keyword) async {
    // ✅ If search is empty → show full location list
    if (keyword.isEmpty) {
      isSearching.value = false;
      searchedLocations.clear();
      return;
    }

    isSearching.value = true;

    try {
      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/locations/search?keyword=$keyword",
        headers: await buildHeader(),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == true && data["data"] != null) {
        searchedLocations.assignAll(
          List<Map<String, dynamic>>.from(data["data"]),
        );
      } else {
        searchedLocations.clear();
      }
    } catch (e) {
      searchedLocations.clear();
    }
  }

  /// ✅ Delete Location
  Future<void> deleteLocation(String locationId) async {
    try {
      final response = await deleteRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/locations/$locationId",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success("Location removed successfully");
        getAllLocation();
      } else {
        CustomToast.error("Failed to delete");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    }
  }

  /// ✅ Set Default Location
  Future<void> setDefaultLocation(String locationId) async {
    String url =
        "${NetworkConfig.baseURL}/farmer/locations/set-default/$locationId";
    try {
      final response = await postRequest(
        endPoint: url,
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success("Default location set successfully");
        getAllLocation();
      } else {
        CustomToast.error("Failed to set default");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    }
  }

  Future<void> fetchDefaultLocation(String userId) async {
    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/locations/default",
        headers: await buildHeader(),
      );
      print('===========fetch default locaiton=============');
      print(response.body.toString());
      if (response.statusCode == 200) {
        final respBody = jsonDecode(response.body);
        if (respBody is! Map ||
            respBody["status"] != true ||
            respBody["data"] == null) {
          throw Exception('Invalid response format');
        }

        final Map<String, dynamic> data = Map<String, dynamic>.from(
          respBody["data"],
        );

        selectedLocation.assignAll(data);
        selectedLatiude.value = data["latitude"]?.toString() ?? "";
        selectedLongitude.value = data["longitude"]?.toString() ?? "";
        selectedCity.value = (data["title"]?.toString() ?? "");
        selectedFullAddress.value = (data["subtitle"]?.toString() ?? "");
        selectedLocationId.value = data["id"]?.toString() ?? '';
      } else {
        selectedLocation.assignAll({});
        selectedLatiude.value = "";
        selectedLongitude.value = "";
        selectedCity.value = "Madhapur, Hydrabad";
        selectedFullAddress.value = "Madhapur, Hydrabad, Telangana";
        selectedLocationId.value = '';
        //  CustomToast.error("Failed to fetch default location");
      }
    } on FormatException catch (e) {
      CustomToast.error("Failed to fetch default location");
    } on Exception catch (e) {
      CustomToast.error("Failed to fetch default location");
    } catch (e) {
      CustomToast.error("Failed to fetch default location");
    }
  }
}
