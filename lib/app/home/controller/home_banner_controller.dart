import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/painting.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'dart:convert';

import 'package:seedsuser/app/utils/network_utils.dart';

class HomeBannerController extends GetxController {
  var isLoading = true.obs;
  var isTopLoading = false.obs;
  var banners = <BannerItem>[].obs;
  var bannersBackGround = <BannerItem>[].obs;
  var bannersMedicine = <BannerItem>[].obs;
  var bannersTop = <BannerItem>[].obs;
  var bannersHome = <BannerItem>[].obs;
  var bannersSeedPrice = <BannerItem>[].obs;
  var bannersSpotHatcheries = <BannerItem>[].obs;
  var isSpotLoading = true.obs;
  var bannersFarmManagement = <BannerItem>[].obs;
  var isFarmLoading = true.obs;
  var isHomeLoading = true.obs;
  var bannersSection1Bg = <BannerItem>[].obs;

  /// Clear Flutter's in-memory image cache so updated banner images
  /// are re-downloaded instead of serving stale cached versions.
 

  @override
  void onInit() {
    super.onInit();
    fetchBannersTop();
    fetchBannersBackground();
    fetchBannersMedicine();
    fetchHomeBanner();
    fetchSeedPriceBanner();
    fetchSpotHatcheriesIcon();
    fetchFarmManagementIcon();
    fetchSection1Background();
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
        // _clearImageCache();
      } else {
        CustomToast.error("Failed to fetch banners");
      }
    } catch (e) {
      debugPrint("fetchBanners error: $e");
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
        if (model.status) {
          bannersBackGround.assignAll(model.banners);
        }
        // _clearImageCache();
      }
    } catch (e) {
      debugPrint("fetchBannersBackground error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchBannersTop() async {
    try {
      isTopLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/banner_top",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status) {
          bannersTop.assignAll(model.banners);
        }
        // _clearImageCache();
      }
    } catch (e) {
      debugPrint("fetchBannersTop error: $e");
    } finally {
      isTopLoading.value = false;
    }
  }

  Future<void> fetchBannersMedicine() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/best_deals_banners",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status) {
          bannersMedicine.assignAll(model.banners);
        }
        // _clearImageCache();
      }
    } catch (e) {
      debugPrint("fetchBannersMedicine error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchHomeBanner() async {
    try {
      isHomeLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/home_banner",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status) {
          bannersHome.assignAll(model.banners);
        }
        // _clearImageCache();
      }
    } catch (e) {
      debugPrint("fetchHomeBanner error: $e");
    } finally {
      isHomeLoading.value = false;
    }
  }

  Future<void> fetchSeedPriceBanner() async {
    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/seed_price_banner",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status) {
          bannersSeedPrice.assignAll(model.banners);
        }
        // _clearImageCache();
      }
    } catch (e) {
      debugPrint("fetchSeedPriceBanner error: $e");
    }
  }

  Future<void> fetchSpotHatcheriesIcon() async {
    try {
      isSpotLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/spot_hatcheries_icon",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status) {
          bannersSpotHatcheries.assignAll(model.banners);
        }
        // _clearImageCache();
      }
    } catch (e) {
      debugPrint("fetchSpotHatcheriesIcon error: $e");
    } finally {
      isSpotLoading.value = false;
    }
  }

  Future<void> fetchFarmManagementIcon() async {
    try {
      isFarmLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farm_management_icon",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status) {
          bannersFarmManagement.assignAll(model.banners);
        }
        // _clearImageCache();
      }
    } catch (e) {
      debugPrint("fetchFarmManagementIcon error: $e");
    } finally {
      isFarmLoading.value = false;
    }
  }

  Future<void> fetchSection1Background() async {
    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/home_section1_bg",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status) {
          bannersSection1Bg.assignAll(model.banners);
        }
        // _clearImageCache();
      }
    } catch (e) {
      debugPrint("fetchSection1Background error: $e");
    }
  }
}
