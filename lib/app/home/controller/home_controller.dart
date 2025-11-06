import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/broadstock/controller/brood_stock_controller.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/news%20&%20ads/controller/news_specific_controller.dart';
import 'package:seedsuser/app/seed_price/controller/seeds_price_controller.dart';
import 'package:seedsuser/app/updates/controller/hatchery_updates_controller.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class HomeController extends GetxController {
  var isLoading = false.obs;

  var categories = <Category>[].obs;

  @override
  void onInit() {
    super.onInit();
    getCategories();
  }

  final _broodStockController = Get.put(BroodStockController());
  final _newsSpecificController = Get.put(NewsSpecificController());
  final _seedsPriceController = Get.put(SeedsPriceController());
  final _hatcheryController = Get.put(HatcheryUpdatesController());

  changeHomeData(
    String categoryId,
    String locationId, {
    double? latitude,
    double? longitude,
  }) async {
    print('========calling for the======');
    print('categoryId - $categoryId, locationId $locationId');

    // hatcheries api
    // price api
    await _seedsPriceController.getPricesForHome(
      categoryId: categoryId,
      locationId: locationId,
    );
    //brood stocks api
    await _broodStockController.getBroodStockForHome(
      categoryId: categoryId,
      locationId: '20',
    );
    // medicine home api
    await _newsSpecificController.fetch(
      'medicine news',
      categoryId: categoryId,
      locationId: locationId,
      isHome: true,
    );
    await _hatcheryController.fetchHatcheryHomeUpdate(
      categoryId: '4',
      locationId: '3'
    );
    // hatchery updates
  }

  Future<void> getCategories() async {
    print('enter in get cat');
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
      } else {
        CustomToast.error("Failed to fetch categories: ${response.statusCode}");
      }
    } catch (e, s) {
      print('enter in get cat error');
      print(e);
      print(s);
      CustomToast.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
