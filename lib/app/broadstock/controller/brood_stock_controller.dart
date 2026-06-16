import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_cache_helper.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/brood_stock_model.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class BroodStockController extends GetxController {
  static const _tag = '🦐 [BROOD]';

  /// State
  final isLoading = false.obs;
  // True for the WHOLE initial load (fetchInitialData). Drives the shimmer so it
  // doesn't flicker off to the empty/Retry state between the sub-fetches
  // (getCategories toggles isLoading off before getBroodStock turns it on).
  final isInitialLoading = false.obs;
  final categories = <Category>[].obs;
  final broodStocks = <BroodstockData>[].obs;
  final homeBroodStocks = <BroodstockData>[].obs;
  final filteredBroodStocks = <BroodstockData>[].obs;

  /// Home "Hatchery / Broodstock" preview state. `isHomeLoading` drives the
  /// shimmer so the widget never shows the "No hatchery found" message while
  /// the data is still loading; `homeFetchCompleted` flips true once a fetch
  /// has actually finished so the empty message only appears for a genuine
  /// empty result.
  final isHomeLoading = false.obs;
  final homeFetchCompleted = false.obs;
  bool _homeLoadInProgress = false;

  /// Selected filters
  final selectedCategory = Rx<Category?>(null);
  final selectedMonth = ''.obs;
  final selectedYear = ''.obs;
  final searchQuery = ''.obs;

  /// Default filter from API
  final defaultCategory = 'Tiger'.obs;
  final defaultMonthYear = ''.obs;

  /// Tracks the month/year the user has explicitly selected (display string).
  /// Empty means no user selection yet — fall back to defaultMonthYear.
  final userSelectedMonthYear = ''.obs;

  /// Available months from API (dynamic)
  final availableMonths = <Map<String, String>>[].obs;
  final isMonthsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // NOTE: do NOT auto-fetch here. The broodstock data is fetched only when the
    // Broodstock screen opens (broad_stock_screen calls fetchInitialData in its
    // initState). This keeps the home tab — which also instantiates this
    // controller to read `homeBroodStocks` — from fetching broodstock at start.
  }

  // ── Default Filter ──────────────────────────────────────────────────
  Future<void> getDefaultFilter() async {
    debugPrint('$_tag getDefaultFilter...');
    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/broodstock-default-filter",
        headers: await buildHeader(),
      );

      debugPrint('$_tag getDefaultFilter status=${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _safeJsonDecode(response.body, 'getDefaultFilter');
        if (data == null) return;

        if (data['status'] == true && data['data'] != null) {
          final filterData = data['data'];
          if (filterData is! Map) {
            debugPrint('$_tag ❌ getDefaultFilter data is not Map: ${filterData.runtimeType}');
            return;
          }
          defaultCategory.value = filterData['category']?.toString() ?? 'Tiger';
          selectedMonth.value = filterData['month']?.toString() ?? DateTime.now().month.toString().padLeft(2, '0');
          selectedYear.value = filterData['year']?.toString() ?? DateTime.now().year.toString();
          defaultMonthYear.value = filterData['display_month_year']?.toString() ?? '';
          debugPrint('$_tag ✅ defaultFilter: cat=${defaultCategory.value}, month=${selectedMonth.value}, year=${selectedYear.value}, display=${defaultMonthYear.value}');
        } else {
          debugPrint('$_tag getDefaultFilter: status=${data['status']}, message=${data['message']}');
        }
      } else {
        debugPrint('$_tag ❌ getDefaultFilter HTTP ${response.statusCode}');
      }
    } catch (e, s) {
      debugPrint('$_tag ❌ getDefaultFilter error: $e');
      debugPrint('$_tag stack: $s');
      final now = DateTime.now();
      selectedMonth.value = now.month.toString().padLeft(2, '0');
      selectedYear.value = now.year.toString();
    }
  }

  // ── Available Months ────────────────────────────────────────────────
  Future<void> fetchAvailableMonths() async {
    debugPrint('$_tag fetchAvailableMonths...');
    try {
      isMonthsLoading.value = true;
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/broodstock-available-months",
        headers: await buildHeader(),
      );

      debugPrint('$_tag fetchAvailableMonths status=${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _safeJsonDecode(response.body, 'fetchAvailableMonths');
        if (data == null) return;

        if (data['status'] == true && data['data'] is List) {
          final rawList = data['data'] as List;
          final List<Map<String, String>> months = [];
          for (int i = 0; i < rawList.length; i++) {
            try {
              final item = rawList[i];
              if (item is Map) {
                months.add({
                  'month': item['month']?.toString() ?? '',
                  'year': item['year']?.toString() ?? '',
                  'month_name': item['month_name']?.toString() ?? '',
                  'display': item['display']?.toString() ?? '',
                });
              } else {
                debugPrint('$_tag ⚠️ availableMonths[$i] is not Map: ${item.runtimeType}');
              }
            } catch (e) {
              debugPrint('$_tag ❌ availableMonths[$i] parse error: $e');
            }
          }
          availableMonths.assignAll(months);
          debugPrint('$_tag ✅ availableMonths: ${months.length} months loaded');
        } else {
          debugPrint('$_tag availableMonths: status=${data['status']}, data type=${data['data']?.runtimeType}');
        }
      } else {
        debugPrint('$_tag ❌ fetchAvailableMonths HTTP ${response.statusCode}');
      }
    } catch (e, s) {
      debugPrint('$_tag ❌ fetchAvailableMonths error: $e');
      debugPrint('$_tag stack: $s');
    } finally {
      isMonthsLoading.value = false;
    }
  }

  // ── Initial Data ────────────────────────────────────────────────────
  Future<void> fetchInitialData() async {
    debugPrint('$_tag fetchInitialData START');
    // Keep the shimmer on for the ENTIRE initial load so it never flickers to
    // the empty/Retry state between sub-fetches.
    isInitialLoading.value = true;
    try {
      await getDefaultFilter();
      await getCategories();

      // Set default category
      if (categories.isNotEmpty) {
        bool isFound = false;
        for (var category in categories) {
          if (category.categoryName.toLowerCase() == defaultCategory.value.toLowerCase()) {
            selectedCategory.value = category;
            isFound = true;
            break;
          }
        }
        if (!isFound) {
          for (var category in categories) {
            if (category.categoryName.toLowerCase() == "tiger") {
              selectedCategory.value = category;
              isFound = true;
              break;
            }
          }
        }
        if (!isFound) {
          selectedCategory.value = categories.first;
        }
        debugPrint('$_tag selectedCategory: ${selectedCategory.value?.categoryName ?? "null"}');
      } else {
        debugPrint('$_tag ⚠️ No categories loaded — cannot select default');
      }

      if (selectedMonth.value.isEmpty) {
        final now = DateTime.now();
        selectedMonth.value = now.month.toString().padLeft(2, '0');
        selectedYear.value = now.year.toString();
      }

      await fetchAvailableMonths();
      await getBroodStock();
      debugPrint('$_tag fetchInitialData DONE');
    } catch (e, s) {
      debugPrint('$_tag ❌ fetchInitialData error: $e');
      debugPrint('$_tag stack: $s');
    } finally {
      isInitialLoading.value = false;
    }
  }

  // ── Categories ──────────────────────────────────────────────────────
  Future<void> getCategories() async {
    debugPrint('$_tag getCategories...');
    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/categories",
        headers: await buildHeader(),
      );

      debugPrint('$_tag getCategories status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _safeJsonDecode(response.body, 'getCategories');
        if (data == null) return;

        final catList = data['categories'];
        if (catList is List) {
          final parsed = <Category>[];
          for (int i = 0; i < catList.length; i++) {
            try {
              if (catList[i] is Map<String, dynamic>) {
                parsed.add(Category.fromJson(catList[i]));
              } else {
                debugPrint('$_tag ⚠️ categories[$i] is not Map: ${catList[i].runtimeType}');
              }
            } catch (e) {
              debugPrint('$_tag ❌ categories[$i] parse error: $e');
            }
          }
          categories.assignAll(parsed);
          debugPrint('$_tag ✅ categories: ${parsed.length} loaded');
        } else {
          debugPrint('$_tag ❌ categories field is ${catList.runtimeType}, expected List');
        }
      } else {
        debugPrint('$_tag ❌ getCategories HTTP ${response.statusCode}');
      }
    } catch (e, s) {
      debugPrint('$_tag ❌ getCategories error: $e');
      debugPrint('$_tag stack: $s');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Broodstock List ─────────────────────────────────────────────────
  Future<void> getBroodStock() async {
    if (selectedCategory.value == null) {
      debugPrint('$_tag getBroodStock skipped — no category selected');
      return;
    }

    debugPrint('$_tag getBroodStock: cat=${selectedCategory.value!.categoryName}, month=${selectedMonth.value}, year=${selectedYear.value}, search=${searchQuery.value}');
    try {
      isLoading.value = true;
      final endpoint =
          "${NetworkConfig.baseURL}/farmer/broodstocks_list"
          "?search=${Uri.encodeComponent(searchQuery.value)}"
          "&category=${Uri.encodeComponent(selectedCategory.value!.categoryName.toLowerCase())}"
          "&month=${selectedMonth.value.toLowerCase()}"
          "&year=${selectedYear.value}";

      debugPrint('$_tag getBroodStock URL: $endpoint');

      final response = await getRequest(
        endPoint: endpoint,
        headers: await buildHeader(),
      );

      debugPrint('$_tag getBroodStock status=${response.statusCode}, bodyLen=${response.body.length}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _safeJsonDecode(response.body, 'getBroodStock');
        if (data == null) {
          broodStocks.clear();
          filteredBroodStocks.clear();
          return;
        }

        if (data['status'] == true && data['data'] is List) {
          final rawList = data['data'] as List;
          debugPrint('$_tag getBroodStock: ${rawList.length} raw items from API');

          final model = BroodstockModel.fromJson(data);
          broodStocks.assignAll(model.data);
          filteredBroodStocks.assignAll(model.data);
          debugPrint('$_tag ✅ getBroodStock: ${model.data.length} parsed successfully');

          if (rawList.length != model.data.length) {
            debugPrint('$_tag ⚠️ ${rawList.length - model.data.length} items failed to parse');
          }
        } else {
          broodStocks.clear();
          filteredBroodStocks.clear();
          final msg = data['message']?.toString() ?? 'No broodstock found';
          debugPrint('$_tag getBroodStock: status=${data['status']}, message=$msg, data type=${data['data']?.runtimeType}');
          if (data['status'] != true) {
            CustomToast.info(msg);
          }
        }
      } else {
        debugPrint('$_tag ❌ getBroodStock HTTP ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
        broodStocks.clear();
        filteredBroodStocks.clear();
      }
    } catch (e, s) {
      debugPrint('$_tag ❌ getBroodStock error: $e');
      debugPrint('$_tag stack: $s');
      broodStocks.clear();
      filteredBroodStocks.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // ── Broodstock for Home ─────────────────────────────────────────────
  /// Loads the home "Hatchery / Broodstock" preview. Cache-first + silent (no
  /// toast), retried a few times on failure so a transient startup/OTP-burst
  /// failure doesn't leave the section stuck on "No hatchery found" when
  /// hatcheries actually exist.
  Future<void> loadHomeBroodStock() async {
    if (_homeLoadInProgress) {
      debugPrint('$_tag loadHomeBroodStock skipped — already in progress');
      return;
    }
    _homeLoadInProgress = true;
    if (homeBroodStocks.isEmpty) isHomeLoading.value = true;
    try {
      const maxAttempts = 4;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        final ok = await getBroodStockForHome(categoryId: '', locationId: '');
        // Stop once the server answered (even with an empty list) or we have
        // data to show; otherwise back off and retry the failed request.
        if (ok || homeBroodStocks.isNotEmpty) break;
        if (attempt < maxAttempts) {
          if (homeBroodStocks.isEmpty) isHomeLoading.value = true;
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    } finally {
      isHomeLoading.value = false;
      homeFetchCompleted.value = true;
      _homeLoadInProgress = false;
    }
  }

  /// Returns true when the server gave a definitive answer (success or a real
  /// empty result) and false when the request failed and should be retried.
  Future<bool> getBroodStockForHome({required String categoryId, required String locationId}) async {
    debugPrint('$_tag getBroodStockForHome: catId=$categoryId, locId=$locationId');
    try {
      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('broodstock_home');
        if (cached != null) {
          final data = _safeJsonDecode(cached, 'broodstock_home cache');
          if (data != null && data['status'] == true && data['data'] is List) {
            final model = BroodstockModel.fromJson(data);
            final limitedData = model.data.length > 5 ? model.data.sublist(0, 5) : model.data;
            homeBroodStocks.assignAll(limitedData);
            debugPrint('$_tag ✅ cache: ${limitedData.length} home broodstocks');
          }
        }
      } catch (e) {
        debugPrint('$_tag ⚠️ cache read failed: $e');
      }

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

      debugPrint('$_tag getBroodStockForHome URL: $endpoint');

      final response = await getRequest(
        endPoint: endpoint,
        headers: await buildHeader(),
      );

      debugPrint('$_tag getBroodStockForHome status=${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _safeJsonDecode(response.body, 'getBroodStockForHome');
        if (data == null) return false; // couldn't parse — let caller retry

        if (data['status'] == true && data['data'] is List) {
          final model = BroodstockModel.fromJson(data);
          final limitedData = model.data.length > 5 ? model.data.sublist(0, 5) : model.data;
          homeBroodStocks.assignAll(limitedData);
          debugPrint('$_tag ✅ getBroodStockForHome: ${limitedData.length} items');
        } else {
          homeBroodStocks.clear();
          debugPrint('$_tag getBroodStockForHome: status=${data['status']}, data type=${data['data']?.runtimeType}');
        }
        try {
          await AppCacheHelper.save('broodstock_home', response.body);
        } catch (e) {
          debugPrint('$_tag ⚠️ cache save failed: $e');
        }
        return true; // server answered definitively (with data or empty)
      } else {
        debugPrint('$_tag ❌ getBroodStockForHome HTTP ${response.statusCode}');
        return false; // HTTP error — let caller retry
      }
    } catch (e, s) {
      debugPrint('$_tag ❌ getBroodStockForHome error: $e');
      debugPrint('$_tag stack: $s');
      return false; // network/parse error — let caller retry
    }
  }

  // ── Local Search Filter ─────────────────────────────────────────────
  void filterBroodStocks(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredBroodStocks.assignAll(broodStocks);
    } else {
      final lowerQuery = query.toLowerCase();
      filteredBroodStocks.assignAll(
        broodStocks.where((item) {
          return item.hatcheryName.toLowerCase().contains(lowerQuery) ||
              item.supplierName.toLowerCase().contains(lowerQuery) ||
              item.locationName.toLowerCase().contains(lowerQuery) ||
              item.availableQuantity.toLowerCase().contains(lowerQuery) ||
              item.importedDate.toLowerCase().contains(lowerQuery) ||
              item.description.toLowerCase().contains(lowerQuery);
        }).toList(),
      );
    }
    debugPrint('$_tag filterBroodStocks: query="$query", results=${filteredBroodStocks.length}/${broodStocks.length}');
  }

  // ── Filter Handlers ─────────────────────────────────────────────────
  void onCategoryChanged(Category? category) {
    if (category != null) {
      debugPrint('$_tag onCategoryChanged: ${category.categoryName}');
      selectedCategory.value = category;
      getBroodStock();
    }
  }

  void onMonthYearChanged(String month, String year) {
    debugPrint('$_tag onMonthYearChanged: month=$month, year=$year');
    selectedMonth.value = _convertMonthNameToNumber(month);
    selectedYear.value = year;
    getBroodStock();
  }

  String _convertMonthNameToNumber(String monthName) {
    const monthMap = {
      'jan': '01', 'feb': '02', 'mar': '03', 'apr': '04',
      'may': '05', 'jun': '06', 'jul': '07', 'aug': '08',
      'sep': '09', 'oct': '10', 'nov': '11', 'dec': '12',
    };
    return monthMap[monthName.toLowerCase()] ?? monthName;
  }

  // ── Safe JSON Decode ────────────────────────────────────────────────
  Map<String, dynamic>? _safeJsonDecode(String body, String context) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      debugPrint('$_tag ❌ $context: JSON decoded but is ${decoded.runtimeType}, not Map');
      return null;
    } catch (e) {
      debugPrint('$_tag ❌ $context: JSON decode FAILED: $e');
      debugPrint('$_tag body preview: ${body.length > 300 ? body.substring(0, 300) : body}');
      return null;
    }
  }
}
