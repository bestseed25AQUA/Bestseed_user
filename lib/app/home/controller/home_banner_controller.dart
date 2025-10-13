import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'dart:convert';

import 'package:seedsuser/app/utils/network_utils.dart';

class HomeBannerController extends GetxController {
  var isLoading = true.obs;
  var banners = <BannerItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/banner",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status) {
          banners.assignAll(model.banners);
        }
      } else {
        CustomToast.error("Failed to fetch profile: ${response.statusCode}");
      }
    } catch (e) {
      CustomToast.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
