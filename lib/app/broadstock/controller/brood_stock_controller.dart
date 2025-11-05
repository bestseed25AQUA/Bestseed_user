import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/brood_stock_model.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class BroodStockController extends GetxController {
  /// State
  final isLoading = false.obs;
  final categories = <Category>[].obs;
  final broodStocks = <BroodstockData>[].obs;
  final homeBroodStocks = <BroodstockData>[].obs;
  final filteredBroodStocks = <BroodstockData>[].obs; //

  /// Selected filters
  final selectedCategory = Rx<Category?>(null);
  final selectedMonth = ''.obs;
  final selectedYear = ''.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  /// Fetch both categories & broodstock initially
  Future<void> fetchInitialData() async {
    await getCategories();
    //default
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

    // Default month & year = current date
    final now = DateTime.now();
    selectedMonth.value = now.month.toString().padLeft(2, '0');
    selectedYear.value = now.year.toString();

    await getBroodStock();
  }

  /// Fetch broodstock categories
  Future<void> getCategories() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/categories",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final catList = data['categories'];
        if (catList is List) {
          categories.assignAll(
            catList.map((e) => Category.fromJson(e)).toList(),
          );
        }
      } else {
        CustomToast.error(
          "Failed to fetch categories (Code: ${response.statusCode})",
        );
      }
    } catch (e) {
      CustomToast.error("Error fetching categories: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch broodstock list
  Future<void> getBroodStock() async {
    if (selectedCategory.value == null) {
      // CustomToast.error("Please select a category.");
      return;
    }

    try {
      isLoading.value = true;

      final endpoint =
          "${NetworkConfig.baseURL}/farmer/broodstocks_list"
          "?search=${Uri.encodeComponent(searchQuery.value)}"
          "&category=${Uri.encodeComponent(selectedCategory.value!.categoryName.toLowerCase())}"
          "&month=${selectedMonth.value.toLowerCase()}"
          "&year=${selectedYear.value}";

      final response = await getRequest(
        endPoint: endpoint,
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['status'] == true && data['data'] is List) {
          final model = BroodstockModel.fromJson(data);
          broodStocks.assignAll(model.data);
          filteredBroodStocks.assignAll(model.data); // 🔹 Default filter = all
        } else {
          broodStocks.clear();
          filteredBroodStocks.clear();
          CustomToast.info(data['message'] ?? "No broodstock found.");
        }
      } else {
        CustomToast.error(
          "Failed to fetch brood stock (Code: ${response.statusCode})",
        );
      }
    } catch (e) {
      CustomToast.error("Error fetching brood stock: $e");
    } finally {
      isLoading.value = false;
    }
  }

 Future<void> getBroodStockForHome({required String categoryId, required String locationId}) async {
    try {
      final endpoint =
          "${NetworkConfig.baseURL}/farmer/broodstocks_list";

      final response = await getRequest(
        endPoint: endpoint,
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['status'] == true && data['data'] is List) {
          final model = BroodstockModel.fromJson(data);
          homeBroodStocks.assignAll(model.data);
        } else {
          homeBroodStocks.clear();
          homeBroodStocks.clear();
          CustomToast.info(data['message'] ?? "No broodstock found.");
        }
      } else {
        CustomToast.error(
          "Failed to fetch brood stock (Code: ${response.statusCode})",
        );
      }
    } catch (e) {
      CustomToast.error("Error fetching brood stock: $e");
    } finally { 
    }
  }


  /// 🔹 Local filter (client-side) for broodstock search
  void filterBroodStocks(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      // Show all if search is cleared
      filteredBroodStocks.assignAll(broodStocks);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredBroodStocks.assignAll(
        broodStocks.where((item) {
          final hatchery = item.hatcheryName.toLowerCase();
          final supplier = item.supplierName.toLowerCase();
          return hatchery.contains(lowerQuery) || supplier.contains(lowerQuery);
        }).toList(),
      );
    }
  }

  /// Handle category dropdown change
  void onCategoryChanged(Category? category) {
    if (category != null) {
      selectedCategory.value = category;
      getBroodStock();
    }
  }

  /// Handle month-year dropdown updates
  void onMonthYearChanged(String month, String year) {
    selectedMonth.value = month;
    selectedYear.value = year;
    getBroodStock();
  }
}
