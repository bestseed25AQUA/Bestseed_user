import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_cache_helper.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/news_specifc_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class NewsSpecificController extends GetxController {
  var isLoading = true.obs;
  Rx<NewsSpecificModel?> newsSpecificData = Rx<NewsSpecificModel?>(null);
  Rx<NewsSpecificModel?> newsSpecificHomeData = Rx<NewsSpecificModel?>(null);

  Future<void> fetch(String type,{bool isHome = false, String categoryId='', String locationId = '' }) async {
    try {
      print('enter in specific');
      String endPoint = "${NetworkConfig.baseURL}/farmer/news?type=$type&category_id=$categoryId&location_id=$locationId";
      if (kDebugMode){
        print('end point $endPoint');
      }
      isLoading.value = true;

      // Load from cache first (only for home screen calls)
      if (isHome) {
        try {
          final cached = await AppCacheHelper.get('medicine_news_home');
          if (cached != null) {
            final data = json.decode(cached);
            newsSpecificHomeData.value = NewsSpecificModel.fromJson(data);
            isLoading.value = false;
          }
        } catch (e) {
          debugPrint('Cache read failed (medicine_news_home): $e');
        }
      }

      final response = await getRequest(
        endPoint: endPoint,
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('specific new data');
        print(data);
        if(isHome){
          newsSpecificHomeData.value = NewsSpecificModel.fromJson(data);
          try { await AppCacheHelper.save('medicine_news_home', response.body); } catch (e) { debugPrint('Cache save failed (medicine_news_home): $e'); }
        }else{
            newsSpecificData.value = NewsSpecificModel.fromJson(data);
        }

      } else {
        CustomToast.error(
          "Failed to fetch Medicine News ",
        );
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }
}
