import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/feed_store_model.dart';
import 'package:seedsuser/app/subscription/controller/subscription_controller.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

import 'package:http/http.dart' as http;

/// The one shared [FarmListController].
///
/// `Get.put()` REPLACES any existing registration, so several screens each
/// calling it were handed different objects — a list refreshed on one was
/// invisible to another, which is why a deleted farm stayed on screen and why
/// a freshly added farm did not appear. Always reuse the registered instance.
FarmListController get farmListController =>
    Get.isRegistered<FarmListController>()
        ? Get.find<FarmListController>()
        : Get.put(FarmListController());

class FarmListController extends GetxController {
  var isLoading = true.obs;
  Rx<FarmListModel?> farmList = Rx<FarmListModel?>(null);

  /// True when the last fetch failed outright (no network, server down).
  ///
  /// Distinct from "the farmer has no farms": both leave the list empty, but
  /// only the second one should send the screen to the add-your-first-farm
  /// page. Without this, losing signal for a moment told a farmer with a dozen
  /// farms that they had none.
  RxBool hasLoadError = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFarmList();
  }

  Future<void> fetchFarmList() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farm-lists",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        farmList.value = FarmListModel.fromJson(data);
        hasLoadError.value = false;
      } else if (response.statusCode == 404) {
        // The API answers 404 (not 200 with []) when the farmer has no farms.
        // Ignoring it meant the previous list survived, so deleting the LAST
        // farm left it on screen even though the server had removed it.
        farmList.value = FarmListModel(data: []);
        hasLoadError.value = false;
      } else {
        // Any other status is a failure, not an empty farm list.
        hasLoadError.value = true;
        CustomToast.error('Could not load your farms');
      }
    } catch (e) {
      // Was a bare print, so a failed load looked exactly like "no farms yet"
      // and the screen offered to add a first farm.
      hasLoadError.value = true;
      CustomToast.error('Could not load your farms');
    } finally {
      isLoading.value = false;
    }
  }

  RxBool isOverlay = false.obs;

  /// Raised when a create was refused for want of a subscription (HTTP 402).
  ///
  /// A flag rather than showing the sheet from here: this controller has no
  /// BuildContext, and reaching for a global one to put a modal on screen is
  /// how a sheet ends up attached to a route that is being popped. The form
  /// screen watches this and presents the sheet from its own context.
  ///
  /// Consumed by [takeSubscriptionRefusal] so it fires once per refusal.
  final RxBool needsSubscription = false.obs;

  /// Read and clear the refusal flag.
  bool takeSubscriptionRefusal() {
    if (!needsSubscription.value) return false;

    needsSubscription.value = false;
    return true;
  }

  /// The tanks of the farm currently being edited.
  ///
  /// The edit form needs them to list what the farm already has and to number
  /// anything new from the end — `FarmData` carries only a count, which says
  /// nothing about each tank's own stocking date.
  final RxList<TankModel> farmTanks = <TankModel>[].obs;

  Future<void> fetchFarmTanks(int farmId) async {
    try {
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farms/$farmId/tanks",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        farmTanks.value = TankListModel.fromJson(
          json.decode(response.body),
        ).data ??
            [];
        return;
      }

      // 404 is the API's way of saying "this farm has no tanks", which is a
      // perfectly good answer for a farm that has just been created.
      farmTanks.clear();
    } catch (e) {
      farmTanks.clear();
      CustomToast.error('Could not load this farm\'s tanks');
    }
  }

  /// ------------ ADD NEW FARM ---------------- ///
  Future<bool> uploadFarmData({
    required String farmName,
    required String stockingDate,
    required String store,
    required String lowFeedLimit,
    required String tanks,
    required List<String> imagePaths,
    String feedUsedBefore = '',
    List<Map<String, String>> tanksMeta = const [],
  }) async {
    try {
      isOverlay(true);

      // Cleared up front, not just when consumed. If a previous refusal were
      // somehow left standing — the form was abandoned before the sheet was
      // shown, say — it would fire against THIS attempt and offer packages to
      // a farmer whose farm had just been created.
      needsSubscription.value = false;

      final streamedResponse = await multipartPostRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/create-farm",
        fields: {
          "type": "form",
          // So the server can tell "no image chosen" from "image was dropped".
          "image_count": imagePaths.length.toString(),
          "farm_name": farmName,
          "stocking_date": stockingDate,
          "store": store,
          "low_feed_limit": lowFeedLimit,
          "tanks": tanks,
          // Per-tank stocking dates and prior feed.
          //
          // JSON in a single field because a multipart form cannot carry
          // nested arrays cleanly — Laravel's parser flattens `tanks[0][date]`
          // inconsistently across clients, and one string decodes the same
          // way everywhere.
          if (tanksMeta.isNotEmpty) "tanks_meta": jsonEncode(tanksMeta),
          // Only meaningful when the farm was stocked before today; the server
          // spreads it across the tanks and the days that have passed.
          if (feedUsedBefore.isNotEmpty) "feed_used_before": feedUsedBefore,
        },
        headers: await buildHeader(),
        imagePaths: imagePaths,
      );
      final http.Response response = await http.Response.fromStream(
        streamedResponse,
      );
      debugPrint("Create response: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success("Farm added successfully ✔");
        return true;
      }

      // 402 Payment Required — the free farm limit, checked again server-side.
      //
      // The add button asks before opening this form, so reaching here means
      // the answer changed underneath the farmer: they had two devices open,
      // or an admin cancelled their subscription while the form was being
      // filled in. Either way it is not a validation error and must not be
      // reported as one, so the packages are offered instead.
      if (response.statusCode == 402) {
        final body = _decodeBody(response.body);

        if (body is Map && body['data'] is Map<String, dynamic>) {
          subscriptionController.adoptFromRefusal(
            body['data'] as Map<String, dynamic>,
          );
        } else {
          // Body was not the shape we expect: re-read rather than guess.
          await subscriptionController.load(force: true);
        }

        needsSubscription.value = true;
        return false;
      }

      // Decoded, not the raw Response: parseErrorMessage only understands a
      // Map, so handing it the http.Response meant every validation failure
      // ("The farm name has already been taken") was reported to the farmer as
      // a flat "Something went wrong!".
      CustomToast.error(parseErrorMessage(_decodeBody(response.body)));
    } catch (e) {
      CustomToast.error("Could not add the farm");
    } finally {
      isOverlay(false);
    }

    return false;
  }

  /// The response body as a Map, or null when it is not JSON at all — an HTML
  /// error page from the proxy, say, which json.decode would throw on.
  dynamic _decodeBody(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      return null;
    }
  }

  String parseErrorMessage(dynamic error) {
    try {
      if (error is Map && error.containsKey('errors')) {
        final errors = error['errors'] as Map;

        if (errors.isNotEmpty) {
          // Take the first error field
          final firstKey = errors.keys.first;

          final firstErrorList = errors[firstKey];

          if (firstErrorList is List && firstErrorList.isNotEmpty) {
            return firstErrorList.first.toString();
          }
        }
      }

      if (error is Map && error.containsKey('message')) {
        return error['message'].toString();
      }

      return "Something went wrong!";
    } catch (e) {
      return "Something went wrong!";
    }
  }

  /// ------------- UPDATE FARM DETAILS ----------------- ///
  Future<bool> updateFarmData({
    required int farmId,
    required String farmName,
    required String stockingDate,
    required String store,
    required String lowFeedLimit,
    required String tanks,
    required List<String> imagePaths,
    String feedUsedBefore = '',
    List<Map<String, String>> newTanksMeta = const [],
    List<Map<String, String>> existingTanksMeta = const [],

    /// Stored image urls still on screen when Save was pressed.
    ///
    /// The server keeps exactly these and drops the rest, which is what makes
    /// deleting an already-uploaded photo possible — the update used to append
    /// new files to the old list and could never remove one.
    List<String> keptImages = const [],
  }) async {
    try {
      isOverlay(true);

      final streamedResponse = await multipartPostRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farms/$farmId",
        fields: {
          "farm_name": farmName,
          "stocking_date": stockingDate,
          "store": store,
          "low_feed_limit": lowFeedLimit,
          "no_of_tanks": tanks,
          // Tanks being ADDED, each with its own stocking date and prior feed.
          // The server appends them after the farm's existing tanks and never
          // touches those; it also recomputes no_of_tanks from what really
          // exists, so the count above is advisory.
          if (newTanksMeta.isNotEmpty)
            "new_tanks_meta": jsonEncode(newTanksMeta),
          // Corrections to the tanks the farm already has. Sent for all of
          // them; the server compares each against what it holds and rewrites
          // only the generated history of the ones that actually changed.
          if (existingTanksMeta.isNotEmpty)
            "existing_tanks_meta": jsonEncode(existingTanksMeta),
          // Ignored by the server unless the farm still has no feed recorded.
          if (feedUsedBefore.isNotEmpty) "feed_used_before": feedUsedBefore,
          // Always sent, even when empty: an empty array means "the farmer
          // removed them all". Omitting the field is what tells an older
          // server to keep everything, so silence here would make a full
          // clear-out look like no change at all.
          "kept_images": jsonEncode(keptImages),
        },
        headers: await buildHeader(),
        imagePaths: imagePaths,
      );

      // Read the body, the way the create call does. It used to print
      // `response.stream` — which says nothing — and then report every failure
      // as "Failed to update farm", hiding what the server actually rejected.
      final http.Response response = await http.Response.fromStream(
        streamedResponse,
      );
      debugPrint("Update response: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200) {
        CustomToast.success("Farm updated successfully ");
        return true;
      }

      CustomToast.error(parseErrorMessage(_decodeBody(response.body)));
    } catch (e) {
      CustomToast.error("Could not update the farm");
    } finally {
      // In a finally: the success path returns from inside the try, so a
      // trailing isOverlay(false) never ran and the Update button span for
      // ever after a successful edit.
      isOverlay(false);
    }

    return false;
  }

  /// -------------  DELETE FARM ----------------- ///
  Future<bool> deleteFarm({required String farmId}) async {
    try {
      isOverlay(true);
      String url = "${NetworkConfig.baseURL}/farmer/farm/delete/$farmId";

      var response = await getRequest(
        endPoint: url,
        headers: await buildHeader(),
      );
      debugPrint("Delete response: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200) {
        CustomToast.success("Farm deleted successfully ✔");
        return true;
      } else {
        CustomToast.error(parseErrorMessage(_decodeBody(response.body)));
      }
    } catch (e) {
      CustomToast.error("Could not delete the farm");
    } finally {
      isOverlay(false);
    }
    return false;
  }
}
