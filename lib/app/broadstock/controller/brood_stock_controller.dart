import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class BroodStockController extends GetxController {
  var isLoading = false.obs;

  var categories = <Category>[].obs;

  Rx<Category?> selectedCategory = Rx<Category?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    await Future.wait([getCategories()]);
    // Set default selection if lists are not empty

    if (categories.isNotEmpty) selectedCategory.value = categories.first;
    await getBroodStock();
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

  Future<void> getBroodStock() async {
    if (selectedCategory.value == null) return;

    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/prices?category_id=${selectedCategory.value!.id}&",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // priceModel.value = PriceModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch prices: ${response.statusCode}");
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void onCategoryChanged(Category? cat) {
    selectedCategory.value = cat;
    getBroodStock();
  }
}
