import 'dart:convert';

import 'package:get/get.dart';
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
    try {
      isLoading.value = true;

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
      } else {
        CustomToast.error("Failed to fetch ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }
}
