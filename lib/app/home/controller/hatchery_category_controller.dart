import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/model/filter_apply_data_model.dart';
import 'package:seedsuser/app/home/model/hatchery_category_detail_model.dart';
import 'package:seedsuser/app/home/model/hatchery_category_model.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class HatcheryCategoryController extends GetxController {
  RxBool isLoading = false.obs;

  Rx<HatcheryDetailsResponse> hatcheryCateogoryData = HatcheryDetailsResponse(
    status: false,
    message: '',
    data: [],
    similarHatcheries: [],
  ).obs;

  /// Fetch hatchery categories
  /// [id] - The hatchery identifier
  /// [useHatcheryId] - If true, uses database id endpoint (/hatchery-by-id),
  ///                   if false, uses unique_id endpoint (/hatchery-all-category)
  Future<void> fetchHetcheryCategory(String id, {bool useHatcheryId = false}) async {
    try {
      isLoading.value = true;
      // Use different endpoints based on the source
      // - Search flow: useHatcheryId = true -> /hatchery-by-id/{id}
      // - Home screen flow: useHatcheryId = false -> /hatchery-all-category/{unique_id}
      final endpoint = useHatcheryId
          ? '${NetworkConfig.baseURL}/farmer/hatchery-by-id/$id'
          : '${NetworkConfig.baseURL}/farmer/hatchery-all-category/$id';
      print('🔍 Fetching hatchery categories for ID: $id (useHatcheryId: $useHatcheryId)');
      print('📍 Endpoint: $endpoint');

      final response = await getRequest(
        endPoint: endpoint,
        headers: await buildHeader(),
      );

      print('📦 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final dataResponse = jsonDecode(response.body);
          hatcheryCateogoryData.value = HatcheryDetailsResponse.fromJson(
            dataResponse
          );

          print('✅ Categories fetched: ${hatcheryCateogoryData.value.data.length}');
          print('✅ Similar hatcheries: ${hatcheryCateogoryData.value.similarHatcheries.length}');

          // ── 150km radius filter verification ──────────────────────────────
          // Prints the opened hatchery + each similar hatchery with its distance
          // so we can confirm the backend filtered to <=150km of the opened
          // hatchery's location AND ordered nearest-first.
          final opened = hatcheryCateogoryData.value.data.isNotEmpty
              ? hatcheryCateogoryData.value.data.first
              : null;
          print('📏 [SIMILAR] ════════════════════════════════════════════');
          print('📏 [SIMILAR] Opened hatchery: ${opened?.hatcheryName ?? "?"} '
              '| location: ${opened?.location?.name ?? "-"}');
          final similar = hatcheryCateogoryData.value.similarHatcheries;
          print('📏 [SIMILAR] ${similar.length} similar hatcheries returned '
              '(expected: within 150km, nearest-first):');
          final anyDistance = similar.any((s) => s.distanceKm != null);
          if (!anyDistance) {
            print('📏 [SIMILAR] ⚠️ No distance_km on any item → either OLD backend '
                '(not deployed) OR the opened hatchery has no lat/lng (fallback list).');
          }
          for (var i = 0; i < similar.length; i++) {
            final s = similar[i];
            final d = s.distanceKm == null
                ? 'null(no-coords)'
                : '${s.distanceKm!.toStringAsFixed(1)} km';
            print('   #${i + 1} ${s.hatcheryName} | ${s.location ?? "-"} '
                '| ${s.status} | $d');
          }
          final over = similar.where((s) => (s.distanceKm ?? 0) > 150).toList();
          if (over.isNotEmpty) {
            print('⚠️ [SIMILAR] ${over.length} item(s) OVER 150km — filter NOT applied: '
                '${over.map((s) => "${s.hatcheryName}(${s.distanceKm})").join(", ")}');
          }
        } catch (e) {
          print('❌ JSON parsing error: $e');
        }
      } else {
        print('❌ API returned status code: ${response.statusCode}');
      }
    } catch (e, s){
      print('❌ Error fetching hatchery data: $e');
      print('Stack trace: $s');
      CustomToast.error("Something went wrong fetching hatchery data");
    } finally {
      isLoading.value = false;
    }
  }

  Rx<HatcherCategoryDetailModel> hatcheryCategoryDetailData =
      HatcherCategoryDetailModel().obs;
  RxBool detailLoading = false.obs;

  Future<void> getHatcheryCategoryDetail(
    String hatcheryId,
    String categoryId,
  ) async {
    try {
      detailLoading.value = true;
      final response = await getRequest(
        endPoint:
            '${NetworkConfig.baseURL}/farmer/hatchery/$hatcheryId/category/$categoryId/detail',
        headers: await buildHeader(),
      );
      if (response.statusCode == 200) {
        try {
          final dataResponse = jsonDecode(response.body);
          hatcheryCategoryDetailData.value =
              HatcherCategoryDetailModel.fromJson(dataResponse);
        } catch (e) {
          print(e.toString());
        }
      }
    } catch (e) {
      CustomToast.error("Something went wrong fetching hatcgery data");
    } finally {
      detailLoading.value = false;
    }
  }

  var isBannerLoading = true.obs;
  var banners = <BannerItem>[].obs;

  Future<void> fetchBanners(String id) async {
    try {
      isBannerLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/hatcheryBanners/$id",
        headers: await buildHeader(),
      );
      print('++++++++banners data here++++++++++++');
      print(response.body);
      final List<dynamic> bannerList = [];
      banners.assignAll(bannerList.map((e) => BannerItem.fromJson(e)).toList());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true) {
          try {
            final List<dynamic> bannerList = data['banners'].isNotEmpty
                ? data['banners']
                : [
                    // {
                    //   "id": 45,
                    //   "hatchery_id": "50",
                    //   "screen": "hatcherybanner",
                    //   "type": "image",
                    //   "url":
                    //       "https://aliceblue-wallaby-326294.hostingersite.com/uploads/banners/banner_1762411814.jpg",
                    // }
                  ];
            //   final List<dynamic> bannerList = ["https://aliceblue-wallaby-326294.hostingersite.com/uploads/banners/banner_1762411814.jpg"];
            banners.assignAll(
              bannerList.map((e) => BannerItem.fromJson(e)).toList(),
            );
          } catch (e) {
            print(e.toString());
          }
        } else {
          // CustomToast.error("No banners found.");
        }
      } else {
        // CustomToast.error("Failed to fetch banners ");
      }
    } catch (e) {
      // CustomToast.error("Something went wrong  ");
    } finally {
      isBannerLoading.value = false;
    }
  }
}