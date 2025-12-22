import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'dart:convert';

import 'package:seedsuser/app/utils/network_utils.dart';

class HomeBannerController extends GetxController {
  var isLoading = true.obs;
  var banners = <BannerItem>[].obs;
  var bannersBackGround = <BannerItem>[].obs;
  var bannersMedicine = <BannerItem>[].obs;
  var bannersTop = <BannerItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    // fetchBanners();
    fetchBannersBackground();
    fetchBannersMedicine();
    fetchBannersTop();
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
        CustomToast.error("Failed to fetch profile ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBannersBackground() async {
    try {
      isLoading.value = true;

      final response = await getRequest( 
           endPoint: "${NetworkConfig.baseURL}/farmer/banner_bg",
        headers: await buildHeader(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status){
          bannersBackGround.assignAll(model.banners);
        }
      } else {
        CustomToast.error("Failed to fetch profile ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBannersTop() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/banner_top",
          //  endPoint: "${NetworkConfig.baseURL}/farmer/banner_bg",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status) {
          bannersTop.assignAll(model.banners);
        }
      } else {
        CustomToast.error("Failed to fetch profile ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBannersMedicine() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        // endPoint: "${NetworkConfig.baseURL}/farmer/banner_medicine",
           endPoint: "${NetworkConfig.baseURL}/farmer/best_deals_banners",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status) {
          bannersMedicine.assignAll(model.banners);
        }
      } else {
        CustomToast.error("Failed to fetch profile ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }
}
