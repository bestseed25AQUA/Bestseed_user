import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_activity_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

/// A farm's recent history: who changed what, and when.
///
/// Owners and partners only — the server refuses anyone else with 403, and
/// this surfaces that as a plain sentence rather than an error, because a
/// manager reaching the screen has done nothing wrong.
class FarmActivityController extends GetxController {
  final Rx<FarmActivityFeed> feed = FarmActivityFeed.empty().obs;

  final RxBool isLoading = false.obs;

  /// Set when the farm is readable but this person is not allowed to audit it.
  final RxnString deniedMessage = RxnString();

  /// Set when the fetch failed outright. Distinct from an empty history: one
  /// means "nothing happened", the other means "we could not find out".
  final RxBool hasError = false.obs;

  /// The selected category chip, or null for everything.
  final RxnString category = RxnString();

  /// Narrows the whole screen to one tank when it was opened from that tank.
  int? tankId;

  Future<void> load(int farmId, {bool silent = false}) async {
    if (!silent) isLoading.value = true;

    deniedMessage.value = null;
    hasError.value = false;

    try {
      final query = <String, String>{
        if (category.value != null) 'category': category.value!,
        if (tankId != null) 'tank_id': '$tankId',
      };

      final suffix = query.isEmpty
          ? ''
          : '?${query.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farm/$farmId/activity$suffix",
        headers: await buildHeader(),
      );

      final body = _decode(response.body);

      if (response.statusCode == 200 &&
          body is Map &&
          body['data'] is Map<String, dynamic>) {
        feed.value = FarmActivityFeed.fromJson(
          body['data'] as Map<String, dynamic>,
        );
        return;
      }

      // Not an error to shout about: the screen explains it instead.
      if (response.statusCode == 403) {
        deniedMessage.value = body is Map && body['message'] != null
            ? body['message'].toString()
            : 'Only the farm owner or a partner can view the farm history.';
        return;
      }

      hasError.value = true;
      debugPrint('[ACTIVITY] ${response.statusCode}: ${response.body}');
    } catch (e) {
      hasError.value = true;
      debugPrint('[ACTIVITY] failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Switch the category filter and re-read. Passing null clears it.
  Future<void> filterBy(int farmId, String? key) async {
    if (category.value == key) return;

    category.value = key;
    await load(farmId);
  }

  dynamic _decode(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      return null;
    }
  }
}
