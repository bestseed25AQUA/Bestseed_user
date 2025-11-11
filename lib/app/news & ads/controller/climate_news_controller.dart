


import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class ClimateNewsController extends GetxController{
   var isLoading = true.obs;
  var climateNewsList = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchList();
  }

  Future<void> fetchList() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/-------",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['climate_news'] != null) {
          final List<dynamic> climateNewsList = data['climate_news'];
          // medicineNewsList.assignAll(
          //   bannerList.map((e) => BannerItem.fromJson(e)).toList(),
          // );
        } else {
          climateNewsList.clear();
          CustomToast.error("No Medicine News found.");
        }
      } else {
        CustomToast.error("Failed to fetch Medicine News ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }
}
