


import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/all_news_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class NewsAdsController extends GetxController{
   var isLoading = true.obs;
   Rx<AllNewsModel?> nesAndAdsData = Rx<AllNewsModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch({ String? categoryId, String? locationId }) async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/home-news",
        headers: await buildHeader(),
        // params: '?category_id=$categoryId&location_id='
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
         nesAndAdsData?.value = AllNewsModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch: ${response.statusCode}");
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
