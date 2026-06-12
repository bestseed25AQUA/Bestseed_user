import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_cache_helper.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';
import 'package:seedsuser/app/home/model/brand_model.dart';
import 'package:seedsuser/app/home/model/hatcheries_model.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/model/price_home_model.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';
import 'package:seedsuser/app/utils/app_names_constants.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class HomeController extends GetxController {
  var isLoading = false.obs;
  var categories = <Category>[].obs;

  final FilterHatcheryController filterHatcheryController = Get.put(
    FilterHatcheryController(),
  );

  @override
  void onInit() {
    super.onInit();
    getCategories();
    getBrands();
  }

  final _newsSpecificController = Get.put(NewsSpecificController());
  final _hatcheryController = Get.put(HatcheryUpdatesController());

  RxString selectedCategoryId = ''.obs;
  RxString selectedCateogryName = ''.obs;
  changeHomeData(String categoryId, String locationId) async {
    print('========calling for the======');
    print('categoryId - $categoryId, locationId $locationId');

    // hatcheries api
    await getHatcheries(categoryId);

    // Today's prices preview (first few sizes) for the home card.
    await getPricesForHome();

    // NOTE: full broodstock is intentionally NOT fetched here. Broodstock
    // loads only on the Broodstock screen (avoids the home request burst +
    // "failed to fetch" toast).

    // medicine home api
    await _newsSpecificController.fetch(
      'medicine news',
      categoryId: categoryId,
      locationId: locationId,
      isHome: true,
    );
    // hatchery updates
    await _hatcheryController.fetchHatcheryHomeUpdate(
      // categoryId: categoryId,
      // locationId: locationId
      categoryId: categoryId,
      locationId: locationId,
    );
  }

  Future<void> getCategories() async {
    try {
      isLoading.value = true;

      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('categories');
        if (cached != null) {
          final data = jsonDecode(cached);
          final List<dynamic> catList = data['categories'];
          categories.assignAll(catList.map((e) => Category.fromJson(e)).toList());
          isLoading.value = false;
        }
      } catch (e) {
        debugPrint('Cache read failed (categories): $e');
      }

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/categories",
        headers: await buildHeader(),
      );
      print('=====get cat apis========');
      print(response.body);
      print(response.statusCode);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List<dynamic> catList = data['categories'];
        categories.assignAll(catList.map((e) => Category.fromJson(e)).toList());
        // ⭐ Pass data to search filter controller
        try { await AppCacheHelper.save('categories', response.body); } catch (e) { debugPrint('Cache save failed (categories): $e'); }
      } else {
        // CustomToast.error("Failed to fetch categories ");
      }
    } catch (e) {
      debugPrint("Categories API Error: $e");
      // Don't show a failure toast on the home screen.
      // if (e.toString().contains('Network Issue')) {
      //   CustomToast.error(AppConstNames.networkError);
      // }
    } finally {
      isLoading.value = false;
    }
  }

  var brands = <BrandModel>[].obs;

  Future<void> getBrands() async {
    try {
      isLoading.value = true;

      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('brands');
        if (cached != null) {
          final data = jsonDecode(cached);
          final List<dynamic> brandList = data['brands'];
          brands.assignAll(brandList.map((e) => BrandModel.fromJson(e)).toList());
          isLoading.value = false;
        }
      } catch (e) {
        debugPrint('Cache read failed (brands): $e');
      }

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/brands",
        headers: await buildHeader(),
      );

      print('=====get brands api========');
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List<dynamic> brandList = data['brands'];
        brands.assignAll(brandList.map((e) => BrandModel.fromJson(e)).toList());
        try { await AppCacheHelper.save('brands', response.body); } catch (e) { debugPrint('Cache save failed (brands): $e'); }
      } else {
        // Don't show a failure toast on the home screen.
        // CustomToast.error("Failed to fetch brands ");
      }
    } catch (e) {
      debugPrint("Brands API Error: $e");
      // Don't show a failure toast on the home screen.
      // if (e.toString().contains('Network Issue')) {
      //   CustomToast.error(AppConstNames.networkError);
      // }
    } finally {
      isLoading.value = false;
    }
  }

  var hatcheries = <HatcheryHomeModel>[].obs;

  Future<void> getHatcheries(String? categoryId) async {
    try {
      final cacheKey = 'home_hatcheries_${categoryId ?? ''}';

      // Load from cache first
      try {
        final cached = await AppCacheHelper.get(cacheKey);
        if (cached != null) {
          final data = jsonDecode(cached);
          if (data['data'] != null && data['data'] is List) {
            final List<dynamic> hatcheryList = data['data'];
            hatcheries.assignAll(
              hatcheryList.map((e) => HatcheryHomeModel.fromJson(e ?? {})).toList(),
            );
          }
        }
      } catch (e) {
        debugPrint('Cache read failed (hatcheries): $e');
      }

      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/home-hatcheries?category_id=${categoryId ?? ''}",
        headers: await buildHeader(),
      );

      print('===== Hatchery API =====');
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['data'] == null || data['data'] is! List) {
          hatcheries.value = [];
          return;
        }
        final List<dynamic> hatcheryList = data['data'];
        hatcheries.assignAll(
          hatcheryList.map((e) => HatcheryHomeModel.fromJson(e ?? {})).toList(),
        );
        try { await AppCacheHelper.save(cacheKey, response.body); } catch (e) { debugPrint('Cache save failed (hatcheries): $e'); }
      } else {
        // Don't show a failure toast on the home screen.
        // CustomToast.error("Failed to fetch hatcheries");
      }
    } catch (e) {
      debugPrint("Hatchery API Error: $e");
    } finally {}
  }

  var homePriceData = PriceHomeModel(
    status: false,
    category: '',
    description: '',
    data: [],
  ).obs;

  Future<void> getPricesForHome() async {
    try {
      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('home_seed_prices');
        if (cached != null) {
          final data = jsonDecode(cached);
          homePriceData.value = PriceHomeModel.fromJson(data);
        }
      } catch (e) {
        debugPrint('Cache read failed (home_seed_prices): $e');
      }

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/home-seed-prices",
        headers: await buildHeader(),
      );
      print('++++++++++++++');
      print(response.body.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        homePriceData.value = PriceHomeModel.fromJson(data);
        try { await AppCacheHelper.save('home_seed_prices', response.body); } catch (e) { debugPrint('Cache save failed (home_seed_prices): $e'); }
      } else {
        // Don't show a failure toast on the home screen.
        // CustomToast.error("Failed to fetch prices ");
      }
    } catch (e) {
      debugPrint("Prices API Error: $e");
      // Don't show a failure toast on the home screen.
      // if (e.toString().contains('Network Issue')) {
      //   CustomToast.error(AppConstNames.networkError);
      // }
    }
  }
}
