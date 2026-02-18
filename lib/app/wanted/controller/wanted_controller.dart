import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/model/location_model.dart';
import 'package:seedsuser/app/model/wanted_crop_model.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';
import 'package:seedsuser/app/wanted/model/wanted_banner_model.dart';

class WantedCropController extends GetxController {
  var isLoading = false.obs;
  var isBannerLoading = false.obs;

  var bannerList = <WantedBannerItem>[].obs;
  var wantedCropsList = <WantedCrop>[].obs;

  // Categories and locations from the wanted-crops API
  var apiCategories = <Category>[].obs;
  var apiLocations = <Location>[].obs;

  Rx<Location?> selectedLocation = Rx<Location?>(null);
  Rx<Category?> selectedCategory = Rx<Category?>(null);

  getDefaultCrops() {
    final SeedsPriceController seedController = Get.put(SeedsPriceController());

    // Set default location
    if (seedController.locations.isNotEmpty) {
      try {
        bool isFound = false;
        for (var location in seedController.locations) {
          if (location.title == "East Godavari" ||
              location.title == "East Godawari") {
            selectedLocation.value = location;
            isFound = true;
            break;
          }
        }
        if (!isFound) {
          selectedLocation.value = seedController.locations.first;
        }
      } catch (e) {
        selectedLocation.value = seedController.locations.first;
      }
    }

    // Set default category
    if (seedController.categories.isNotEmpty) {
      try {
        bool isFound = false;
        for (var category in seedController.categories) {
          if (category.categoryName == "Vannamei") {
            selectedCategory.value = category;
            isFound = true;
            break;
          }
        }
        if (!isFound) {
          selectedCategory.value = seedController.categories.first;
        }
      } catch (e) {
        selectedCategory.value = seedController.categories.first;
      }
    }

    // Fetch crops AFTER both location and category are set
    if (selectedLocation.value != null || selectedCategory.value != null) {
      fetchCrops();
    }
  }

  // ======================================================
  // 1️⃣ FETCH WANTED BANNERS
  // ======================================================
  Future<void> fetchWantedBanners() async {
    try {
      isBannerLoading(true);
      print('========${"${NetworkConfig.baseURL}/farmer/wanted"}========');

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/wanted",
        headers: await buildHeader(),
      );
      print(response.body.toString());

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["status"] == true) {
          try {
            bannerList.assignAll(
              (jsonData["wanted_banners"] as List)
                  .map((e) => WantedBannerItem.fromJson(e))
                  .toList(),
            );
            print('+++++++++++++data initialize+++++++++++');
          } catch (e, s) {
            print(e.toString());
            print(s.toString());
          }
        }
      } else {
        // CustomToast.error("Failed to fetch banners");
      }
    } catch (e) {
      // CustomToast.error("Something went wrong");
    } finally {
      isBannerLoading(false);
    }
  }

  // ======================================================
  // 2️⃣ FETCH CROPS (Normal OR Filtered)
  // ======================================================
  Future<void> fetchCrops() async {
    try {
      isLoading(true);

      // Build URL dynamically
      String endPoint = "${NetworkConfig.baseURL}/farmer/wanted-crops";
        endPoint += "?";
        endPoint += "category_id=${selectedCategory.value?.id}&";
        endPoint += "location_id=${selectedLocation.value?.id}";
    

      print('==================');
      print(endPoint);

      final response = await getRequest(
        endPoint: endPoint,
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('++++++++data is +++++++');
        print(jsonData);

        // Parse categories and locations from the API response
        if (jsonData["categories"] != null) {
          try {
            apiCategories.assignAll(
              (jsonData["categories"] as List)
                  .map((e) => Category.fromJson(e))
                  .toList(),
            );
          } catch (_) {}
        }
        if (jsonData["locations"] != null) {
          try {
            apiLocations.assignAll(
              (jsonData["locations"] as List).map((e) => Location(
                id: e['id'].toString(),
                title: e['location_name'] ?? e['title'] ?? '',
                subtitle: e['subtitle'] ?? '',
                longitude: e['longitude']?.toString() ?? '',
                latitude: e['latitude']?.toString() ?? '',
                isDefault: e['is_default'] ?? false,
              )).toList(),
            );
          } catch (_) {}
        }

        // Re-match selected values so dropdown highlights them correctly
        if (apiLocations.isNotEmpty && selectedLocation.value != null) {
          try {
            final match = apiLocations.firstWhere(
              (l) => l.id == selectedLocation.value!.id,
            );
            selectedLocation.value = match;
          } catch (_) {}
        }
        if (apiCategories.isNotEmpty && selectedCategory.value != null) {
          try {
            final match = apiCategories.firstWhere(
              (c) => c.id == selectedCategory.value!.id,
            );
            selectedCategory.value = match;
          } catch (_) {}
        }

        if (jsonData["status"] == true && jsonData["wanted_crops"] != null) {
          try {
            final cropsList = (jsonData["wanted_crops"] as List)
                .map((e) => WantedCrop.fromJson(e))
                .toList();
            wantedCropsList.assignAll(cropsList);
            print('wanted crops loaded: ${cropsList.length} items');
          } catch (e, s) {
            print('error parsing wanted crops');
            print(e);
            print(s.toString());
          }
        } else {
          wantedCropsList.clear();
          print('wanted_crops key is null or status is false');
        }
      } else {
        CustomToast.error("Failed to fetch crops");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isLoading(false);
    }
  }
}
