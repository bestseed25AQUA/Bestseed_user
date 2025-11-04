


import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/all_news_model.dart';
import 'package:seedsuser/app/model/single_news_detail_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class SingleNewDetailController extends GetxController{
   var isLoading = true.obs;
   Rx<SingleNewsDetailModel?> singleDetailData = Rx<SingleNewsDetailModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch({ String? type, String? id }) async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/news/9?type=$type&id=$id",
        headers: await buildHeader(),
        // params: '?category_id=$categoryId&location_id='
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
         singleDetailData.value = SingleNewsDetailModel.fromJson(data);
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
