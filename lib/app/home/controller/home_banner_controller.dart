import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/common/app_cache_helper.dart';
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
  var bannersFarmManagement = <BannerItem>[].obs;
  var bannersSection1Bg = <BannerItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBannersTop();
    // fetchBanners();
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

      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('banners');
        if (cached != null) {
          final data = json.decode(cached);
          HomeBannerModel model = HomeBannerModel.fromJson(data);
          if (model.status) {
            banners.assignAll(model.banners);
          }
          isLoading.value = false;
        }
      } catch (e) {
        debugPrint('Cache read failed (banners): $e');
      }

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
        try { await AppCacheHelper.save('banners', response.body); } catch (e) { debugPrint('Cache save failed (banners): $e'); }
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

      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('banner_bg');
        if (cached != null) {
          final data = json.decode(cached);
          HomeBannerModel model = HomeBannerModel.fromJson(data);
          if (model.status) {
            bannersBackGround.assignAll(model.banners);
          }
          isLoading.value = false;
        }
      } catch (e) {
        debugPrint('Cache read failed (banner_bg): $e');
      }

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
        try { await AppCacheHelper.save('banner_bg', response.body); } catch (e) { debugPrint('Cache save failed (banner_bg): $e'); }
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
      isTopLoading.value = true;

      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('banner_top');
        if (cached != null) {
          final data = json.decode(cached);
          HomeBannerModel model = HomeBannerModel.fromJson(data);
          if (model.status) {
            bannersTop.assignAll(model.banners);
          }
          isTopLoading.value = false;
        }
      } catch (e) {
        debugPrint('Cache read failed (banner_top): $e');
      }

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
        try { await AppCacheHelper.save('banner_top', response.body); } catch (e) { debugPrint('Cache save failed (banner_top): $e'); }
      }
    } catch (e) {
      print("Failed to fetch top banner: $e");
    } finally {
      isTopLoading.value = false;
    }
  }

  Future<void> fetchBannersMedicine() async {
    try {
      isLoading.value = true;

      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('best_deals_banners');
        if (cached != null) {
          final data = json.decode(cached);
          HomeBannerModel model = HomeBannerModel.fromJson(data);
          if (model.status) {
            bannersMedicine.assignAll(model.banners);
          }
          isLoading.value = false;
        }
      } catch (e) {
        debugPrint('Cache read failed (best_deals_banners): $e');
      }

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
        try { await AppCacheHelper.save('best_deals_banners', response.body); } catch (e) { debugPrint('Cache save failed (best_deals_banners): $e'); }
      } else {
        CustomToast.error("Failed to fetch profile ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchHomeBanner() async {
    try {
      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('home_banner');
        if (cached != null) {
          final data = json.decode(cached);
          HomeBannerModel model = HomeBannerModel.fromJson(data);
          if (model.status) {
            bannersHome.assignAll(model.banners);
          }
        }
      } catch (e) {
        debugPrint('Cache read failed (home_banner): $e');
      }

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
        try { await AppCacheHelper.save('home_banner', response.body); } catch (e) { debugPrint('Cache save failed (home_banner): $e'); }
      }
    } catch (e) {
      print("Failed to fetch home banner: $e");
    }
  }

  Future<void> fetchSeedPriceBanner() async {
    try {
      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('seed_price_banner');
        if (cached != null) {
          final data = json.decode(cached);
          HomeBannerModel model = HomeBannerModel.fromJson(data);
          if (model.status) {
            bannersSeedPrice.assignAll(model.banners);
          }
        }
      } catch (e) {
        debugPrint('Cache read failed (seed_price_banner): $e');
      }

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
        try { await AppCacheHelper.save('seed_price_banner', response.body); } catch (e) { debugPrint('Cache save failed (seed_price_banner): $e'); }
      }
    } catch (e) {
      print("Failed to fetch seed price banner: $e");
    }
  }

  Future<void> fetchSpotHatcheriesIcon() async {
    try {
      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('spot_hatcheries_icon');
        if (cached != null) {
          final data = json.decode(cached);
          HomeBannerModel model = HomeBannerModel.fromJson(data);
          if (model.status) {
            bannersSpotHatcheries.assignAll(model.banners);
          }
        }
      } catch (e) {
        debugPrint('Cache read failed (spot_hatcheries_icon): $e');
      }

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
        try { await AppCacheHelper.save('spot_hatcheries_icon', response.body); } catch (e) { debugPrint('Cache save failed (spot_hatcheries_icon): $e'); }
      }
    } catch (e) {
      print("Failed to fetch spot hatcheries icon: $e");
    }
  }

  Future<void> fetchFarmManagementIcon() async {
    try {
      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('farm_management_icon');
        if (cached != null) {
          final data = json.decode(cached);
          HomeBannerModel model = HomeBannerModel.fromJson(data);
          if (model.status) {
            bannersFarmManagement.assignAll(model.banners);
          }
        }
      } catch (e) {
        debugPrint('Cache read failed (farm_management_icon): $e');
      }

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
        try { await AppCacheHelper.save('farm_management_icon', response.body); } catch (e) { debugPrint('Cache save failed (farm_management_icon): $e'); }
      }
    } catch (e) {
      print("Failed to fetch farm management icon: $e");
    }
  }

  Future<void> fetchSection1Background() async {
    try {
      // Load from cache first
      try {
        final cached = await AppCacheHelper.get('home_section1_bg');
        if (cached != null) {
          final data = json.decode(cached);
          HomeBannerModel model = HomeBannerModel.fromJson(data);
          if (model.status) {
            bannersSection1Bg.assignAll(model.banners);
          }
        }
      } catch (e) {
        debugPrint('Cache read failed (home_section1_bg): $e');
      }

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
        try { await AppCacheHelper.save('home_section1_bg', response.body); } catch (e) { debugPrint('Cache save failed (home_section1_bg): $e'); }
      }
    } catch (e) {
      print("Failed to fetch section1 background: $e");
    }
  }
}
