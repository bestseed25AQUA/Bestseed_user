import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_cache_helper.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/model/location_model.dart';
import 'package:seedsuser/app/model/price_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class SeedsPriceController extends GetxController {
  var isLoading = false.obs;
  var isPriceLoading = true.obs; // Dedicated loading state for price table

  Rx<PriceModel?> priceData = Rx<PriceModel?>(null);
  Rx<PriceModel?> homePriceData = Rx<PriceModel?>(null);

  var locations = <Location>[].obs;
  var categories = <Category>[].obs;

  Rx<Location?> selectedLocation = Rx<Location?>(null);
  Rx<Category?> selectedCategory = Rx<Category?>(null);

  @override
  void onInit() {
    super.onInit();
    // Fetch only when we don't already have data in memory (so reusing the
    // controller doesn't re-hit the API). isPriceLoading starts true, so the
    // price screen shows its shimmer until this first fetch completes.
    if (locations.isEmpty || categories.isEmpty) {
      fetchData();
    }
  }

  Future<void> fetchData() async {
    isPriceLoading.value = true;
    await Future.wait([getLocations(), getCategories()]);

    if (locations.isNotEmpty) {
      final dummyCategory = <Location>[];
      try {
        bool isFound = false;
        for (var location in locations) {
          if (location.title.toLowerCase() == "India".toLowerCase()) {
            selectedLocation.value = location;
            isFound = true;
            locations = locations;
            dummyCategory.add(location);
            break;
          }
        }
        locations.value = dummyCategory;
        if (!isFound) {
          selectedLocation.value = locations.first;
        }
      } catch (e) {
        selectedLocation.value = locations.first;
      }
    }

    /// for default category
    if (categories.isNotEmpty) {
      final dummyCategory = <Category>[];
      try {
        bool isFound = false;
        for (var category in categories) {
          if (category.categoryName.toLowerCase() == "Vannamei".toLowerCase() ||
              category.categoryName.toLowerCase() == "tiger".toLowerCase()) {
            selectedCategory.value = category;
            isFound = true;
            dummyCategory.add(category);
          }
        }
        categories.value = dummyCategory;
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

      // Load from cache first
      final cached = await AppCacheHelper.get('seed_price_locations');
      if (cached != null) {
        try {
          final data = jsonDecode(cached);
          final List<dynamic> locList = data['locations'];
          locations.assignAll(
            locList.map((e) => Location.fromJson(e)).toList(),
          );
          debugPrint('[Cache] Loaded ${locations.length} locations from cache');
        } catch (e) {
          debugPrint('[Cache] Error parsing cached locations: $e');
        }
      }

      // Fetch from API
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/locations",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        try {
          final List<dynamic> locList = data['locations'];
          locations.assignAll(
            locList.map((e) => Location.fromJson(e)).toList(),
          );
          // Save to cache
          await AppCacheHelper.save('seed_price_locations', response.body);
          debugPrint('[API] Loaded ${locations.length} locations & cached');
        } catch (e) {
          debugPrint('[API] Error parsing locations: $e');
        }
      } else {
        if (locations.isEmpty) {
          CustomToast.error("Failed to fetch locations ");
        }
      }
    } catch (e) {
      if (locations.isEmpty) {
        CustomToast.error("Something went wrong  ");
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getCategories() async {
    try {
      isLoading.value = true;

      // Load from cache first
      final cached = await AppCacheHelper.get('seed_price_categories');
      if (cached != null) {
        try {
          final data = jsonDecode(cached);
          final List<dynamic> catList = data['categories'];
          categories.assignAll(
            catList.map((e) => Category.fromJson(e)).toList(),
          );
          debugPrint('[Cache] Loaded ${categories.length} categories from cache');
        } catch (e) {
          debugPrint('[Cache] Error parsing cached categories: $e');
        }
      }

      // Fetch from API
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/categories",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List<dynamic> catList = data['categories'];
        categories.assignAll(
          catList.map((e) => Category.fromJson(e)).toList(),
        );
        // Save to cache
        await AppCacheHelper.save('seed_price_categories', response.body);
        debugPrint('[API] Loaded ${categories.length} categories & cached');
      } else {
        if (categories.isEmpty) {
          // CustomToast.error("Failed to fetch categories ");
        }
      }
    } catch (e) {
      if (categories.isEmpty) {
        CustomToast.error("Something went wrong  ");
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getPrices() async {
    if (selectedLocation.value == null || selectedCategory.value == null) {
      isPriceLoading.value = false;
      return;
    }

    final catId = selectedCategory.value!.id;
    final locId = selectedLocation.value!.id;
    final cacheKey = 'seed_prices_${catId}_$locId';

    try {
      isPriceLoading.value = true;

      // Load from cache first for instant display
      final cached = await AppCacheHelper.get(cacheKey);
      if (cached != null) {
        try {
          final data = jsonDecode(cached);
          priceData.value = PriceModel.fromJson(data);
          isPriceLoading.value = false; // Show cached data immediately
          debugPrint('[Cache] Loaded prices from cache for cat=$catId loc=$locId');
        } catch (e) {
          debugPrint('[Cache] Error parsing cached prices: $e');
        }
      }

      // Fetch from API (updates silently if cache was shown)
      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/prices?category_id=$catId&location_id=$locId",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        priceData.value = PriceModel.fromJson(data);
        await AppCacheHelper.save(cacheKey, response.body);
        debugPrint('[API] Loaded prices & cached for cat=$catId loc=$locId');
      } else {
        if (priceData.value == null) {
          // Don't show a failure toast — the screen shows a Retry state instead.
          // CustomToast.error("Failed to fetch prices");
        }
      }
    } catch (e) {
      if (priceData.value == null) {
        CustomToast.error("Something went wrong");
      }
    } finally {
      isPriceLoading.value = false;
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
        // Don't show a failure toast for prices.
        // CustomToast.error("Failed to fetch prices ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
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
