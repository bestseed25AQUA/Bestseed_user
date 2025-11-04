import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/news_specifc_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class NewsSpecificController extends GetxController {
  var isLoading = true.obs;
  Rx<NewsSpecificModel?> newsSpecificData = Rx<NewsSpecificModel?>(null);

  Future<void> fetch(String type) async {
    try {
      String endPoint = "${NetworkConfig.baseURL}/farmer/news?type=$type";
      if (kDebugMode){
        print('end point $endPoint');
      }
      isLoading.value = true;
      final response = await getRequest(
        endPoint: endPoint,
        headers: await buildHeader(), 
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        newsSpecificData.value = NewsSpecificModel.fromJson(data);
      } else {
        CustomToast.error(
          "Failed to fetch Medicine News: ${response.statusCode}",
        );
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
