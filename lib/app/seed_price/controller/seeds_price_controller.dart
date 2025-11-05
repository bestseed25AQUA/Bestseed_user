import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/model/location_model.dart';
import 'package:seedsuser/app/model/price_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class SeedsPriceController extends GetxController {
  var isLoading = false.obs;

  Rx<PriceModel?> priceData = Rx<PriceModel?>(null);
  Rx<PriceModel?> homePriceData = Rx<PriceModel?>(null);

  var locations = <Location>[].obs;
  var categories = <Category>[].obs;

  Rx<Location?> selectedLocation = Rx<Location?>(null);
  Rx<Category?> selectedCategory = Rx<Category?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    await Future.wait([getLocations(), getCategories()]);
    // Set default selection if lists are not empty
    // if (locations.isNotEmpty) selectedLocation.value = locations.first;
    // if (categories.isNotEmpty) selectedCategory.value = categories.first;
    /// for default location
    if (locations.isNotEmpty) {
      try {
        bool isFound = false;
        for (var location in locations) {
          if (location.locationName == "East Godawari") {
            selectedLocation.value = location;
            isFound = true;
            break;
          }
        }
        if (!isFound) {
          selectedLocation.value = locations.first;
        }
      } catch (e) {
        selectedLocation.value = locations.first;
      }
    }

    /// for default category
    if (categories.isNotEmpty) {
      try {
        bool isFound = false;
        for (var category in categories) {
          if (category.categoryName == "Vannamei") {
            selectedCategory.value = category;
            isFound = true;
            break;
          }
        }
        if (!isFound) {
          selectedCategory.value = categories.first;
        }
      } catch (e) {
        selectedCategory.value = categories.first;
      }
    }

    await getPrices();
  }

  Future<void> getLocations() async {
    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/locations",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List<dynamic> locList = data['locations'];
        locations.assignAll(locList.map((e) => Location.fromJson(e)).toList());
      } else {
        CustomToast.error("Failed to fetch locations: ${response.statusCode}");
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getCategories() async {
    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/categories",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List<dynamic> catList = data['categories'];
        categories.assignAll(catList.map((e) => Category.fromJson(e)).toList());
      } else {
        CustomToast.error("Failed to fetch categories: ${response.statusCode}");
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getPrices() async {
    if (selectedLocation.value == null || selectedCategory.value == null)
      return;

    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/prices?category_id=${selectedCategory.value!.id}&location_id=${selectedLocation.value!.id}",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        priceData.value = PriceModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch prices: ${response.statusCode}");
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getPricesForHome({
    required String categoryId,
    required String locationId,
  }) async {
    try {
      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/prices?category_id=$categoryId&location_id=$locationId",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        homePriceData.value = PriceModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch prices: ${response.statusCode}");
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {}
  }

  void onLocationChanged(Location? loc) {
    selectedLocation.value = loc;
    getPrices();
  }

  void onCategoryChanged(Category? cat) {
    selectedCategory.value = cat;
    getPrices();
  }
}
