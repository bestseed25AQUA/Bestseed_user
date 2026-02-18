import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/model/filter_apply_data_model.dart';
import 'package:seedsuser/app/home/model/hatchery_filter_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class FilterHatcheryController extends GetxController {
  RxBool isLoading = false.obs;

  RxList<CategoryModel> categories = <CategoryModel>[].obs;
  RxList<LocationModel> locations = <LocationModel>[].obs;
  RxList<BrandModel> brands = <BrandModel>[].obs;

  RxSet<String> selectedCategoryIds = <String>{}.obs;
  RxSet<String> selectedBrandIds = <String>{}.obs;
  RxSet<String> selectedLocationIds = <String>{}.obs;
  RxSet<String> selectedNames = <String>{}.obs;

  String query = '';
  int page = 1;

  @override
  void onInit() {
    super.onInit();
    fetchFilterOptions();
    getHatcheriesNames();
  }

  List<String> hatcheryNames = [''].obs as List<String>;

  var isHatcheryNameLoading = false.obs;

  // All hatcheries list for dropdowns
  RxList<HatcheryFilterItem> allHatcheries = <HatcheryFilterItem>[].obs;

  Future<void> getHatcheriesNames() async {
    try {
      isHatcheryNameLoading.value = true;
      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/hatcheries", //&location_id=${selectedLocation.value!.id
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final modelData = HatcheryFilterResponse.fromJson(data);
        hatcheryNames = List.generate(
          modelData.data.length,
          (index) => modelData.data[index].hatcheryName,
        );
        // Store all hatcheries for dropdown usage
        allHatcheries.assignAll(modelData.data);
        // Show all hatcheries initially
        hatcherFilteredData.value = modelData;
      } else {
        CustomToast.error("Failed to fetch prices ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isHatcheryNameLoading.value = false;
    }
  }

  Future<void> fetchFilterOptions() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: '${NetworkConfig.baseURL}/farmer/hatchery-filters',
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        print('success');
        print(response.body.toString());
        final data = jsonDecode(response.body);
        final filter = FilterResponseModel.fromJson(data);

        if (!filter.status) {
          CustomToast.error(filter.message);
        }

        categories.assignAll(filter.data.categories);
        brands.assignAll(filter.data.brands);
        locations.assignAll(filter.data.locations);
      }

      print(
        "✅ Filters Loaded: ${categories.length} categories, ${brands.length} brands",
      );
    } catch (e, s) {
      print("❌ Filter Fetch Error: $e\n$s");
      CustomToast.error("Something went wrong fetching filters");
    } finally {
      isLoading.value = false;
    }
  }

  /// ********************************
  /// 🔥 Toggle functions (crash-proof)
  /// ********************************

  void toggleCategory(String id) {
    if (id.isEmpty) return;
    selectedCategoryIds.contains(id)
        ? selectedCategoryIds.remove(id)
        : selectedCategoryIds.add(id);
  }

  void toggleBrand(String id) {
    if (id.isEmpty) return;
    selectedBrandIds.contains(id)
        ? selectedBrandIds.remove(id)
        : selectedBrandIds.add(id);
  }

  void toggleLocation(String id) {
    if (id.isEmpty) return;
    selectedLocationIds.contains(id)
        ? selectedLocationIds.remove(id)
        : selectedLocationIds.add(id);
  }

  Rx<HatcheryFilterResponse> hatcherFilteredData = HatcheryFilterResponse(
    status: false,
    message: "",
    meta: MetaData(total: 0, perPage: 0, currentPage: 0, lastPage: 0),
    data: [],
  ).obs;

  Future<void> applyFilter() async {
    try {
      isLoading.value = true;

      // Convert sets → CSV string "1,2,3"
      final categoryCSV = selectedCategoryIds.join(",");
      final brandCSV = selectedBrandIds.join(",");
      final locationCSV = selectedLocationIds.join(",");

      print("📤 Sending Filters → ");
      print("category_id=$categoryCSV");
      print("brand_id=$brandCSV");
      print("location_id=$locationCSV");

      // Build Query URL
      final String url =
          "${NetworkConfig.baseURL}/farmer/hatcheries"
          "?category_id=$categoryCSV"
          "&location_id=$locationCSV"
          "&brand_id=$brandCSV"
          "&q=$query"
          "&page=$page";

      print('============url===============');
      print(url);
      final response = await getRequest(
        endPoint: url,
        headers: await buildHeader(),
      );

      if (response.statusCode != 200) {
        CustomToast.error("Failed: ${response.statusCode}");
        return;
      }

      final data = jsonDecode(response.body);

      if (data == null || !(data["status"] ?? false)) {
        CustomToast.error(data["message"] ?? "Something went wrong");
        return;
      }
      print('===================data==================');
      print(data["data"]);
      print('=========================================');

      // Parse your Hatchery Filter Model
      hatcherFilteredData.value = HatcheryFilterResponse.fromJson(data);
      print(hatcherFilteredData.value.data.length);

      CustomToast.success(data["message"] ?? "Filter Applied Successfully!");
    } catch (e, s) {
      CustomToast.error("Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }

  void searchLocally(String searchQuery) {
    query = searchQuery;

    List<HatcheryFilterItem> filtered = allHatcheries.toList();

    // Filter by search text (name + location)
    if (searchQuery.isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.hatcheryName.toLowerCase().contains(lowerQuery) ||
            item.location.toLowerCase().contains(lowerQuery) ||
            item.category.toLowerCase().contains(lowerQuery) ||
            item.status.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    hatcherFilteredData.value = HatcheryFilterResponse(
      status: true,
      message: "Filtered",
      meta: MetaData(
        total: filtered.length,
        perPage: filtered.length,
        currentPage: 1,
        lastPage: 1,
      ),
      data: filtered,
    );
  }

  void resetFilters() {
    selectedCategoryIds.clear();
    selectedBrandIds.clear();
    selectedLocationIds.clear();
  }
}
