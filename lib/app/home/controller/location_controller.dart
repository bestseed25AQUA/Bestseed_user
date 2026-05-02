import 'dart:convert';
import 'dart:io' show Platform;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class LocationController extends GetxController {

  var allLocationLoading = false.obs;
  var isAutoDetectingLocation = false.obs;

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
        // No default location - keep empty until user enables location permission
        selectedLocation.assignAll({});
        selectedLatiude.value = "";
        selectedLongitude.value = "";
        selectedCity.value = "";
        selectedFullAddress.value = "";
        selectedLocationId.value = '';
      }
    } on FormatException catch (e) {
      CustomToast.error("Failed to fetch default location");
    } on Exception catch (e) {
      CustomToast.error("Failed to fetch default location");
    } catch (e) {
      CustomToast.error("Failed to fetch default location");
    }
  }

  /// ✅ Auto-detect current location and save to database
  Future<Map<String, dynamic>?> autoDetectCurrentLocation({
    required String farmerId,
  }) async {
    try {
      isAutoDetectingLocation.value = true;

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return null;
      }

      // iOS-specific: detect if user disabled "Precise Location" toggle and
      // ask for a one-shot upgrade. We must only ask ONCE per install —
      // calling requestTemporaryFullAccuracy on every cold start triggers
      // the iOS popup every launch (the user's "always asking permissions"
      // complaint). After the first ask, respect the user's choice and use
      // the reduced position silently.
      if (Platform.isIOS) {
        try {
          final status = await Geolocator.getLocationAccuracy();
          if (status == LocationAccuracyStatus.reduced) {
            final prefs = await SharedPreferences.getInstance();
            const askedKey = 'ios_precise_location_asked_v1';
            if (!(prefs.getBool(askedKey) ?? false)) {
              await prefs.setBool(askedKey, true);
              await Geolocator.requestTemporaryFullAccuracy(
                purposeKey: 'ResolveCurrentLocation',
              );
            }
          }
        } catch (_) {
          // iOS < 14 or purpose key missing — fall through with reduced accuracy.
        }
      }

      // Force a fresh GPS fix instead of accepting a cached coarse position.
      //  • iOS: bestForNavigation rejects WiFi/cell-only positions (gives Cheyyeru, not Katrenikona)
      //  • Android: best is equivalent
      //  • timeLimit prevents iOS from returning the first stale fix from memory.
      //  • If the GPS lock can't complete in 15s (indoor / weak signal), fall
      //    back to the last known position rather than failing entirely.
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: Platform.isIOS
              ? AppleSettings(
                  accuracy: LocationAccuracy.bestForNavigation,
                  activityType: ActivityType.other,
                )
              : AndroidSettings(
                  accuracy: LocationAccuracy.best,
                ),
        ).timeout(const Duration(seconds: 15));
      } catch (_) {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return null;
        position = last;
      }

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      Placemark place = placemarks.first;

      // Build location name with proper context (locality, city, state)
      List<String> locationParts = [];
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        locationParts.add(place.subLocality!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        locationParts.add(place.locality!);
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        locationParts.add(place.administrativeArea!);
      }
      String locationName = locationParts.toSet().toList().join(', ');
      if (locationName.startsWith(', ')) {
        locationName = locationName.substring(2);
      }

      String fullAddress =
          "${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}";

      // Clean up the address
      fullAddress = fullAddress
          .replaceAll(RegExp(r', ,'), ',')
          .replaceAll(RegExp(r',,'), ',')
          .trim();
      if (fullAddress.endsWith(',')) {
        fullAddress = fullAddress.substring(0, fullAddress.length - 1);
      }
      if (locationName.startsWith(',')) {
        locationName = locationName.substring(1).trim();
      }

      // Save location to database
      Map? response = await addLocation(
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        locationName: locationName,
        fullAddress: fullAddress,
        farmerId: farmerId,
      );

      if (response != null && response['data'] != null) {
        // Update selected location
        selectedLocationId.value = response['data']['id']?.toString() ?? '';
        selectedCity.value = response['data']['title']?.toString() ?? locationName;
        selectedLatiude.value = position.latitude.toString();
        selectedLongitude.value = position.longitude.toString();
        selectedFullAddress.value = fullAddress;

        print('Auto-detected location saved: $locationName');
        return response['data'];
      }

      return null;
    } catch (e) {
      print('Error auto-detecting location: $e');
      return null;
    } finally {
      isAutoDetectingLocation.value = false;
    }
  }
}
