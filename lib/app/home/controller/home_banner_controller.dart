import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

const _kHomeBannerCacheKey = 'cached_home_banners';

class HomeBannerController extends GetxController {
  final _box = GetStorage();

  var isLoading = true.obs;
  var isBgLoading = true.obs;
  var isMedicineLoading = true.obs;
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

  @override
  void onInit() {
    super.onInit();
    _loadCachedHomeBanner();
    // Network fetches are triggered by fetchAll() from the splash screen
    // so the splash can await them before navigating to home.
  }

  /// Called by the splash screen after auth check.
  /// Runs all 8 banner fetches in parallel. Never throws — any fetch error
  /// is swallowed so the splash can always proceed to navigation.
  Future<void> fetchAll() async {
    try {
      await Future.wait([
        fetchBannersTop(),
        fetchBannersBackground(),
        fetchBannersMedicine(),
        fetchHomeBanner(),
        fetchSeedPriceBanner(),
        fetchSpotHatcheriesIcon(),
        fetchFarmManagementIcon(),
        fetchSection1Background(),
      ]);
    } catch (e) {
      debugPrint('fetchAll error: $e');
    }
    debugPrint(
      '📊 BANNER STATUS: '
      'bg=${bannersBackGround.length}, '
      'top=${bannersTop.length}, '
      'medicine=${bannersMedicine.length}, '
      'home=${bannersHome.length}, '
      'seedPrice=${bannersSeedPrice.length}, '
      'spot=${bannersSpotHatcheries.length}, '
      'farm=${bannersFarmManagement.length}, '
      'section1=${bannersSection1Bg.length}',
    );
  }

  void _loadCachedHomeBanner() {
    final cached = _box.read<List>(_kHomeBannerCacheKey);
    if (cached != null && cached.isNotEmpty) {
      bannersHome.assignAll(
        cached.map((e) => BannerItem.fromJson(Map<String, dynamic>.from(e))),
      );
      isHomeLoading.value = false;
    } else {
      fetchAll();
      isHomeLoading.value = false;
    }
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
      isBgLoading.value = true;

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
      }
    } catch (e) {
      debugPrint("fetchBannersBackground error: $e");
    } finally {
      isBgLoading.value = false;
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
      }
    } catch (e) {
      debugPrint("fetchBannersTop error: $e");
    } finally {
      isTopLoading.value = false;
    }
  }

  Future<void> fetchBannersMedicine() async {
    try {
      isMedicineLoading.value = true;

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
      }
    } catch (e) {
      debugPrint("fetchBannersMedicine error: $e");
    } finally {
      isMedicineLoading.value = false;
    }
  }

  Future<void> fetchHomeBanner() async {
    try {
      if (bannersHome.isEmpty) isHomeLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/home_banner",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        HomeBannerModel model = HomeBannerModel.fromJson(data);
        if (model.status && model.banners.isNotEmpty) {
          bannersHome.assignAll(model.banners);
          _box.write(
            _kHomeBannerCacheKey,
            model.banners.map((b) => b.toJson()).toList(),
          );
        }
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
      }
    } catch (e) {
      debugPrint("fetchSection1Background error: $e");
    }
  }
}
