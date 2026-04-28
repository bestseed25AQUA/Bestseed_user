import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_cache_helper.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/all_news_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class NewsAdsController extends GetxController {
  var isLoading = true.obs;
  Rx<AllNewsModel?> newsAdsData = Rx<AllNewsModel?>(null);
  Rx<AllNewsModel?> homeNewsAdsData = Rx<AllNewsModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch({
    String? categoryId = '',
    String? locationId = '',
    bool isHome = false,
  }) async {
    final cacheKey = isHome ? 'news_ads_home' : 'news_ads_data';

    // Show cached data immediately — no spinner if cache exists
    try {
      final cached = await AppCacheHelper.get(cacheKey);
      if (cached != null) {
        final data = json.decode(cached);
        if (isHome) {
          homeNewsAdsData.value = AllNewsModel.fromJson(data);
        } else {
          newsAdsData.value = AllNewsModel.fromJson(data);
        }
        isLoading.value = false;
      }
    } catch (e) {
      debugPrint('Cache read failed (news_ads): $e');
    }

    // Fetch fresh data in the background (silently if cache already rendered)
    try {
      if (newsAdsData.value == null && homeNewsAdsData.value == null) {
        isLoading.value = true;
      }

      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/home-news?category_id=$categoryId&location_id=$locationId",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (isHome) {
          homeNewsAdsData.value = AllNewsModel.fromJson(data);
        } else {
          newsAdsData.value = AllNewsModel.fromJson(data);
        }
        try { await AppCacheHelper.save(cacheKey, response.body); } catch (e) { debugPrint('Cache save failed (news_ads): $e'); }
      } else {
        if (newsAdsData.value == null) CustomToast.error("Failed to fetch ");
      }
    } catch (e) {
      if (newsAdsData.value == null) CustomToast.error("Something went wrong ");
    } finally {
      isLoading.value = false;
    }
  }
}
