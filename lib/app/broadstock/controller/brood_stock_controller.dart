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
  final filteredBroodStocks = <BroodstockData>[].obs;

  /// Selected filters
  final selectedCategory = Rx<Category?>(null);
  final selectedMonth = ''.obs;
  final selectedYear = ''.obs;
  final searchQuery = ''.obs;

  /// Default filter from API
  final defaultCategory = 'Tiger'.obs;
  final defaultMonthYear = ''.obs;

  /// Available months from API (dynamic)
  final availableMonths = <Map<String, String>>[].obs;
  final isMonthsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  /// Fetch default filter settings from API
  Future<void> getDefaultFilter() async {
    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/broodstock-default-filter",
        headers: await buildHeader(),
      );

      print('=====get default filter api========');
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final filterData = data['data'];
          defaultCategory.value = filterData['category'] ?? 'Tiger';
          selectedMonth.value = filterData['month'] ?? DateTime.now().month.toString().padLeft(2, '0');
          selectedYear.value = filterData['year'] ?? DateTime.now().year.toString();
          defaultMonthYear.value = filterData['display_month_year'] ?? '';
        }
      }
    } catch (e) {
      print('Error fetching default filter: $e');
      // Use fallback defaults
      final now = DateTime.now();
      selectedMonth.value = now.month.toString().padLeft(2, '0');
      selectedYear.value = now.year.toString();
    }
  }

  /// Fetch available months that have broodstock data (all categories combined)
  Future<void> fetchAvailableMonths() async {
    try {
      isMonthsLoading.value = true;
      final endpoint =
          "${NetworkConfig.baseURL}/farmer/broodstock-available-months";

      final response = await getRequest(
        endPoint: endpoint,
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] is List) {
          final List<Map<String, String>> months = [];
          for (var item in data['data']) {
            months.add({
              'month': item['month']?.toString() ?? '',
              'year': item['year']?.toString() ?? '',
              'month_name': item['month_name']?.toString() ?? '',
              'display': item['display']?.toString() ?? '',
            });
          }
          availableMonths.assignAll(months);
        }
      }
    } catch (e) {
      print('Error fetching available months: $e');
    } finally {
      isMonthsLoading.value = false;
    }
  }

  /// Fetch both categories & broodstock initially
  Future<void> fetchInitialData() async {
    // First fetch the default filter from API
    await getDefaultFilter();

    await getCategories();

    // Set default category based on API response
    if (categories.isNotEmpty) {
      try {
        bool isFound = false;
        for (var category in categories) {
          if (category.categoryName.toLowerCase() == defaultCategory.value.toLowerCase()) {
            selectedCategory.value = category;
            isFound = true;
            break;
          }
        }
        if (!isFound) {
          // Fallback to Tiger if API default not found
          for (var category in categories) {
            if (category.categoryName == "Tiger") {
              selectedCategory.value = category;
              isFound = true;
              break;
            }
          }
        }
        if (!isFound) {
          selectedCategory.value = categories.first;
        }
      } catch (e) {
        selectedCategory.value = categories.first;
      }
    }

    // If default filter didn't set month/year, use current date
    if (selectedMonth.value.isEmpty) {
      final now = DateTime.now();
      selectedMonth.value = now.month.toString().padLeft(2, '0');
      selectedYear.value = now.year.toString();
    }

    await fetchAvailableMonths();
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
          "Failed to fetch categories (Code )",
        );
      }
    } catch (e) {
      CustomToast.error("Error fetching categories  ");
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

    try{
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
          filteredBroodStocks.assignAll(model.data); //
        } else {
          broodStocks.clear();
          filteredBroodStocks.clear();
          CustomToast.info(data['message'] ?? "No broodstock found.");
        }
      } else {
        CustomToast.error(
          "Failed to fetch brood stock (Code )",
        );
      }
    } catch (e) {
      CustomToast.error("Error fetching brood stock  ");
    } finally {
      isLoading.value = false;
    }
  }

 Future<void> getBroodStockForHome({required String categoryId, required String locationId}) async {
    try {
      // Use default filter values from admin config (same as BroodStock screen)
      // First fetch defaults if not already loaded
      if (defaultCategory.value.isEmpty) {
        await getDefaultFilter();
      }

      final category = defaultCategory.value.isNotEmpty
          ? Uri.encodeComponent(defaultCategory.value.toLowerCase())
          : '';
      final month = selectedMonth.value.isNotEmpty
          ? selectedMonth.value
          : DateTime.now().month.toString().padLeft(2, '0');
      final year = selectedYear.value.isNotEmpty
          ? selectedYear.value
          : DateTime.now().year.toString();

      final endpoint =
          "${NetworkConfig.baseURL}/farmer/broodstocks_list"
          "?category=$category"
          "&month=$month"
          "&year=$year";
      print('==============calling getBroodStockForHome============');
      print(endpoint);

      final response = await getRequest(
        endPoint: endpoint,
        headers: await buildHeader(),
      );
      print('=========getBroodStockForHome data=========');
      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] is List) {
          final model = BroodstockModel.fromJson(data);
          // Limit to max 5 items for home screen
          final limitedData = model.data.length > 5
              ? model.data.sublist(0, 5)
              : model.data;
          homeBroodStocks.assignAll(limitedData);
        } else {
          homeBroodStocks.clear();
        }
      } else {
        CustomToast.error(
          "Failed to fetch brood stock (Code )",
        );
      }
    } catch (e,s) {
      print('=========get brood stock for home=========');
      print(e.toString());
      print(s.toString());
      CustomToast.error("Error fetching brood stock  ");
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
          final location = item.locationName.toLowerCase();
          final count = item.availableQuantity.toLowerCase();
          final importedDate = item.importedDate.toLowerCase();
          final description = item.description.toLowerCase();
          return hatchery.contains(lowerQuery) ||
              supplier.contains(lowerQuery) ||
              location.contains(lowerQuery) ||
              count.contains(lowerQuery) ||
              importedDate.contains(lowerQuery) ||
              description.contains(lowerQuery);
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
    // Convert month name (Jan, Feb, etc.) to numeric (01, 02, etc.)
    selectedMonth.value = _convertMonthNameToNumber(month);
    selectedYear.value = year;
    getBroodStock();
  }

  /// Convert month name to numeric format
  String _convertMonthNameToNumber(String monthName) {
    const monthMap = {
      'jan': '01',
      'feb': '02',
      'mar': '03',
      'apr': '04',
      'may': '05',
      'jun': '06',
      'jul': '07',
      'aug': '08',
      'sep': '09',
      'oct': '10',
      'nov': '11',
      'dec': '12',
    };
    return monthMap[monthName.toLowerCase()] ?? monthName;
  }
}
