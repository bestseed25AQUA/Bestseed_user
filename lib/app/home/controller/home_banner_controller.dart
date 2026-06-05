import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';
import 'package:seedsuser/app/utils/video_file_cache.dart';
import 'package:seedsuser/app/utils/video_thumbnail_cache.dart';

class HomeBannerController extends GetxController {
  // Loading states — each section independent so UI shows data as it arrives
  var isHomeLoading = true.obs;
  var isMedicineLoading = true.obs;
  var isSpotLoading = true.obs;
  var isFarmLoading = true.obs;
  var isBgLoading = true.obs;
  var isTopLoading = true.obs;
  var isLoading = true.obs;
  var isVideoReady = true.obs;

  // Banner data
  var bannersHome = <BannerItem>[].obs;
  var bannersMedicine = <BannerItem>[].obs;
  var bannersSpotHatcheries = <BannerItem>[].obs;
  var bannersFarmManagement = <BannerItem>[].obs;
  var bannersBackGround = <BannerItem>[].obs;
  var bannersTop = <BannerItem>[].obs;
  var bannersSeedPrice = <BannerItem>[].obs;
  var bannersSection1Bg = <BannerItem>[].obs;
  var banners = <BannerItem>[].obs;

  /// Fetch all banners with priority ordering.
  /// Priority 1 (visible first): Vehicle banner, Best deals, Spot, Farm
  /// Priority 2 (below fold): Background, Top, Section1, Seed price
  ///
  /// Each API fires independently — UI updates as each response arrives.
  /// Failed APIs retry once silently after 3 seconds.
  ///
  /// Guarded so the near-simultaneous calls from the splash prefetch and
  /// HomePage.initState don't double every request + media warm at startup
  /// (which piled onto the startup load and could stall the UI).
  bool _fetchAllInProgress = false;
  Future<void> fetchAll() async {
    if (_fetchAllInProgress) {
      debugPrint('📊 [BANNERS] fetchAll skipped — already in progress');
      return;
    }
    _fetchAllInProgress = true;
    Future.delayed(const Duration(seconds: 2), () => _fetchAllInProgress = false);

    debugPrint('📊 [BANNERS] fetchAll — starting priority fetch');

    // Priority 1: User sees these FIRST on home screen — logo (background),
    // vehicle availability video, best deals, spot hatchery, farm management.
    // Fire all at once but don't wait for all — each updates UI independently
    // and warms its media (image/video poster) as soon as its data arrives.
    _fetchWithRetry('home_banner', fetchHomeBanner);
    _fetchWithRetry('best_deals', fetchBannersMedicine);
    _fetchWithRetry('spot_hatcheries', fetchSpotHatcheriesIcon);
    _fetchWithRetry('farm_management', fetchFarmManagementIcon);
    _fetchWithRetry('banner_bg', fetchBannersBackground);

    // Priority 2: Below fold — slight delay so Priority 1 gets bandwidth first
    Future.delayed(const Duration(milliseconds: 500), _fetchBelowFold);
  }

  void _fetchBelowFold() {
    _fetchWithRetry('banner_top', fetchBannersTop);
    _fetchWithRetry('section1_bg', fetchSection1Background);
    _fetchWithRetry('seed_price', fetchSeedPriceBanner);
  }

  /// Awaits the above-the-fold banner data AND downloads the home banner video
  /// to a local file, so the splash can hand Home fully-populated data with the
  /// video ready to play from disk. Below-the-fold banners fire without waiting.
  /// The caller bounds this with a timeout so the splash never hangs.
  Future<void> preloadEssential() async {
    // Block only on the fast above-the-fold DATA (small JSON + small images) so
    // navigation stays quick and Home opens populated.
    await Future.wait([
      _fetchWithRetry('home_banner', fetchHomeBanner),
      _fetchWithRetry('best_deals', fetchBannersMedicine),
      _fetchWithRetry('spot_hatcheries', fetchSpotHatcheriesIcon),
      _fetchWithRetry('farm_management', fetchFarmManagementIcon),
      _fetchWithRetry('banner_bg', fetchBannersBackground),
    ]);

    // NOTE: image warming is intentionally fire-and-forget (done inside each
    // fetcher via _warmMedia). We do NOT await image decoding here — awaiting
    // decodes (especially the animated GIF logo) on the UI thread during the
    // splash overloaded the main thread and caused ANR/exit. Awaiting only the
    // DATA above is enough: the URLs are present, so the home widgets load the
    // images themselves (instant on repeat, brief shimmer on first install).

    // Download the banner video in the BACKGROUND — don't block navigation on
    // the large file. Home shows the poster instantly and plays from the cached
    // file once ready (or streams meanwhile, caching for next time).
    for (final b in bannersHome) {
      if (b.type == 'video' && b.url.isNotEmpty) {
        VideoFileCache.instance.ensure(b.url); // fire-and-forget
        break;
      }
    }

    _fetchBelowFold();
  }

  /// Warms banner media into cache so it's ready before Home renders:
  /// image banners are precached into Flutter's image cache, and video banners
  /// have their poster frame generated by [VideoThumbnailCache]. Fire-and-forget.
  void _warmMedia(List<BannerItem> items) {
    for (final b in items) {
      if (b.url.isEmpty) continue;
      // Only generate an on-device poster for videos the backend gave NO
      // thumbnail for (rare). Image banners and backend posters are loaded by
      // the home widgets via CachedNetworkImage (disk-cached across sessions),
      // so we deliberately do NOT pre-decode images on the UI thread here —
      // doing so (especially the animated GIF logo) overloaded startup → ANR.
      if (b.type == 'video' && (b.thumbnail == null || b.thumbnail!.isEmpty)) {
        VideoThumbnailCache.instance.warm([b.url]);
      }
    }
  }

  /// Fetch with silent retry — if first attempt fails, retry once after 3s
  Future<void> _fetchWithRetry(String name, Future<void> Function() fetcher) async {
    try {
      await fetcher();
    } catch (e) {
      debugPrint('📊 [BANNERS] $name failed: $e — retrying in 3s');
      Future.delayed(const Duration(seconds: 3), () async {
        try {
          await fetcher();
          debugPrint('📊 [BANNERS] $name retry succeeded');
        } catch (e2) {
          debugPrint('📊 [BANNERS] $name retry also failed: $e2 — giving up');
        }
      });
    }
  }

  // ── Individual fetchers — each updates its own loading state + data ──

  Future<void> fetchHomeBanner() async {
    try {
      if (bannersHome.isEmpty) isHomeLoading.value = true;
      final result = await _fetchBannerList('farmer/home_banner');
      if (result != null) {
        bannersHome.assignAll(result);
        _warmMedia(result);
      }
    } catch (e) {
      debugPrint('📊 [BANNERS] fetchHomeBanner error: $e');
      rethrow;
    } finally {
      isHomeLoading.value = false;
    }
  }

  Future<void> fetchBannersMedicine() async {
    try {
      if (bannersMedicine.isEmpty) isMedicineLoading.value = true;
      final result = await _fetchBannerList('farmer/best_deals_banners');
      if (result != null) {
        bannersMedicine.assignAll(result);
        _warmMedia(result);
      }
    } catch (e) {
      debugPrint('📊 [BANNERS] fetchBannersMedicine error: $e');
      rethrow;
    } finally {
      isMedicineLoading.value = false;
    }
  }

  Future<void> fetchSpotHatcheriesIcon() async {
    try {
      if (bannersSpotHatcheries.isEmpty) isSpotLoading.value = true;
      final result = await _fetchBannerList('farmer/spot_hatcheries_icon');
      if (result != null) {
        bannersSpotHatcheries.assignAll(result);
        _warmMedia(result);
      }
    } catch (e) {
      debugPrint('📊 [BANNERS] fetchSpotHatcheriesIcon error: $e');
      rethrow;
    } finally {
      isSpotLoading.value = false;
    }
  }

  Future<void> fetchFarmManagementIcon() async {
    try {
      if (bannersFarmManagement.isEmpty) isFarmLoading.value = true;
      final result = await _fetchBannerList('farmer/farm_management_icon');
      if (result != null) {
        bannersFarmManagement.assignAll(result);
        _warmMedia(result);
      }
    } catch (e) {
      debugPrint('📊 [BANNERS] fetchFarmManagementIcon error: $e');
      rethrow;
    } finally {
      isFarmLoading.value = false;
    }
  }

  Future<void> fetchBannersBackground() async {
    try {
      if (bannersBackGround.isEmpty) isBgLoading.value = true;
      final result = await _fetchBannerList('farmer/banner_bg');
      if (result != null) {
        bannersBackGround.assignAll(result);
        _warmMedia(result);
      }
    } catch (e) {
      debugPrint('📊 [BANNERS] fetchBannersBackground error: $e');
      rethrow;
    } finally {
      isBgLoading.value = false;
    }
  }

  Future<void> fetchBannersTop() async {
    try {
      if (bannersTop.isEmpty) isTopLoading.value = true;
      final result = await _fetchBannerList('farmer/banner_top');
      if (result != null) bannersTop.assignAll(result);
    } catch (e) {
      debugPrint('📊 [BANNERS] fetchBannersTop error: $e');
      rethrow;
    } finally {
      isTopLoading.value = false;
    }
  }

  Future<void> fetchSeedPriceBanner() async {
    try {
      final result = await _fetchBannerList('farmer/seed_price_banner');
      if (result != null) bannersSeedPrice.assignAll(result);
    } catch (e) {
      debugPrint('📊 [BANNERS] fetchSeedPriceBanner error: $e');
      rethrow;
    }
  }

  Future<void> fetchSection1Background() async {
    try {
      final result = await _fetchBannerList('farmer/home_section1_bg');
      if (result != null) bannersSection1Bg.assignAll(result);
    } catch (e) {
      debugPrint('📊 [BANNERS] fetchSection1Background error: $e');
      rethrow;
    }
  }

  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;
      final result = await _fetchBannerList('farmer/banner');
      if (result != null) banners.assignAll(result);
    } catch (e) {
      debugPrint('📊 [BANNERS] fetchBanners error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Common fetch helper — no toast, no crash, just returns data or null ──

  Future<List<BannerItem>?> _fetchBannerList(String endpoint) async {
    final response = await getRequest(
      endPoint: '${NetworkConfig.baseURL}/$endpoint',
      headers: await buildHeader(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      final model = HomeBannerModel.fromJson(data);
      if (model.status && model.banners.isNotEmpty) {
        return model.banners;
      }
    } else {
      debugPrint('📊 [BANNERS] $endpoint HTTP ${response.statusCode}');
    }
    return null;
  }
}
