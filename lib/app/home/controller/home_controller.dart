import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/controller/filter_hatchery_controller.dart';
import 'package:seedsuser/app/home/model/brand_model.dart';
import 'package:seedsuser/app/home/model/hatcheries_model.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/model/price_home_model.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';
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

  final _broodStockController = Get.put(BroodStockController());
  final _newsSpecificController = Get.put(NewsSpecificController());
  final _seedsPriceController = Get.put(SeedsPriceController());
  final _hatcheryController = Get.put(HatcheryUpdatesController());

  RxString selectedCategoryId = ''.obs;
  RxString selectedCateogryName = ''.obs;
  changeHomeData(String categoryId, String locationId) async {
    print('========calling for the======');
    print('categoryId - $categoryId, locationId $locationId');

    // hatcheries api
    await getHatcheries(categoryId);
    // price api
    getPricesForHome();

    //brood stocks api
    await _broodStockController.getBroodStockForHome(
      // categoryId: categoryId,
      // locationId: locationId,
      categoryId: '',
      locationId: '',
    );
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
      } else {
        CustomToast.error("Failed to fetch categories ");
      }
    } catch (e, s) {
      print('enter in get cat error');
      print(e);
      print(s);
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }

  var brands = <BrandModel>[].obs;

  Future<void> getBrands() async {
    try {
      isLoading.value = true;
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
      } else {
        CustomToast.error("Failed to fetch brands ");
      }
    } catch (e, s) {
      print('Brand API Error  ');
      print(s);
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }

  var hatcheries = <HatcheryHomeModel>[].obs;

  Future<void> getHatcheries(String? categoryId) async {
    try {
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
      } else {
        CustomToast.error("Failed to fetch hatcheries");
      }
    } catch (e, s) {
      print("Hatchery API Error  ");
      print(s);
      CustomToast.error("Something went wrong");
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
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/home-seed-prices",
        headers: await buildHeader(),
      );
      print('++++++++++++++');
      print(response.body.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        homePriceData.value = PriceHomeModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch prices ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    }
  }
}
