import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

/// The one shared [FarmBannerController].
FarmBannerController get farmBannerController =>
    Get.isRegistered<FarmBannerController>()
        ? Get.find<FarmBannerController>()
        : Get.put(FarmBannerController());

/// Banners shown across the top of the Farm Management screen, set in the
/// admin panel under the `farm_management_banner` screen.
class FarmBannerController extends GetxController {
  final banners = <BannerItem>[].obs;

  final isLoading = false.obs;

  bool _inFlight = false;

  Future<void> load({bool force = false}) async {
    if (_inFlight && !force) return;

    _inFlight = true;
    if (banners.isEmpty) isLoading.value = true;

    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farm_management_banner",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body is Map) {
          banners.value = (body['banners'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(BannerItem.fromJson)
              .where((b) => b.url.trim().isNotEmpty)
              .toList();
        }
      } else {
        debugPrint('[FARM BANNER] ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[FARM BANNER] failed: $e');
    } finally {
      _inFlight = false;
      isLoading.value = false;
    }
  }
}
