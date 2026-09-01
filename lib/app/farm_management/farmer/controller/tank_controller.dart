import 'dart:convert';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/model/feed_store_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_feed_history_response.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class TankController extends GetxController {
  var isLoading = true.obs;
  Rx<TankListModel?> farmList = Rx<TankListModel?>(null);

  /// Fetch the tanks of a farm.
  ///
  /// [silent] refreshes the data WITHOUT raising `isLoading`. Screens swap
  /// their whole body for a shimmer while that flag is up, so a refresh after
  /// saving one tank used to blank and rebuild the entire list — losing the
  /// scroll position and anything typed into the other cards. The save already
  /// shows its own overlay, so the follow-up refresh should be invisible.
  Future<void> getTankList(String farmId, {bool silent = false}) async {
    try {
      if (!silent) isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farms/$farmId/tanks",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        farmList.value = TankListModel.fromJson(data);
        if (!silent) CustomToast.success('Tank Feched Successfully');
      } else if (response.statusCode == 404) {
        // The API answers 404 when a farm has no tanks; without this the
        // previous list would linger after the last tank was removed.
        farmList.value = TankListModel(data: []);
      } else {
        // Anything else went unreported: the screen simply kept whatever it
        // had and the farmer had no way to tell the list was stale.
        CustomToast.error('Failed to fetch tank list');
      }
    } catch (e) {
      CustomToast.error('Failed to fetch tank list');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  RxBool isAddingTodayTankQuntity = false.obs;
  Future<bool> addTodayTankQuntity({
    required String feedQty,
    required String mealQty,
    required String tankId,
    String? date,
    String? feedId,
    String? mealId,
    String? farmId,
  }) async {

    Map<String, String>? body = {
      "meals": mealQty,
      "feed_quantity": feedQty,
      'tank_id': tankId.toString(),
      if (date != null) "feed_date": date,
      // With this the server updates that row; without it every "edit" was
      // saved as a brand-new entry and the old one stayed behind.
      if (feedId != null && feedId.isNotEmpty) "feed_id": feedId,
    };
    String endPoint =
        "${NetworkConfig.baseURL}/farmer/tanks/add-todays-tanks-quantity";
    //  return false;
    try {
      isAddingTodayTankQuntity(true);
      final response = await postRequest(
        endPoint: endPoint,
        headers: await buildHeader(),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (farmId != null) {
          getTankList(farmId, silent: true);
        }

        CustomToast.success('Tank Save Successfully');
        return true;
      } else {
        CustomToast.error('Failed to save tank');
      }
    } catch (e) {
      CustomToast.error('Failed to save tank');
    } finally {
      isAddingTodayTankQuntity(false);
    }
    return false;
  }

  RxBool isUpdatingTankStatus = false.obs;

  /// Start or finish a tank's crop cycle.
  ///
  /// Deactivating closes the running batch — its feed drops out of the farm's
  /// total and the tank screen goes read-only, with the report still available.
  /// Activating opens a NEW batch from [stockingDate], starting at zero; a date
  /// in the past also takes [feedUsedBefore] so the days already gone are
  /// filled in, exactly as a newly added tank is.
  Future<bool> updateTankStatus({
    String? tankId,
    required int status,
    required String farmId,
    String? stockingDate,
    String? feedUsedBefore,
  }) async {
    isUpdatingTankStatus(true);
    try {
      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/tank/status",
        headers: await buildHeader(),
        body: {
          "status": status,
          "tank_id": tankId,
          // Only meaningful when activating; the server ignores them otherwise.
          if (stockingDate != null && stockingDate.isNotEmpty)
            "stocking_date": stockingDate,
          if (feedUsedBefore != null && feedUsedBefore.isNotEmpty)
            "feed_used_before": feedUsedBefore,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Silent for the same reason as the save above: the toggle has its own
        // overlay, so the refresh must not blank the screen behind it.
        getTankList(farmId, silent: true);
        CustomToast.success('Tank Updated Successfully');
        return true;
      } else {
        CustomToast.error('Failed to update tank');
      }
    } catch (e) {
      CustomToast.error('Failed to update tank');
    } finally {
      isUpdatingTankStatus(false);
    }
    return false;
  }

  RxBool isDownloading = false.obs;
  Future<String?> getReport({String? tankId}) async {
    isDownloading(true);
    try {
      // POST with the tank id. This used to be a GET with no body, which the
      // route rejects with 405 (it is POST-only), so a report was never
      // generated and the Download button did nothing.
      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/download-tank-feed-report",
        headers: await buildHeader(),
        body: {'tank_id': tankId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final link = jsonDecode(response.body)['download_link'];

        // The backend builds this from APP_URL, which on a dev machine is
        // usually 127.0.0.1 — the phone itself, where no server is running.
        // Re-point it at the host this build actually talks to, the same way
        // farm images are handled.
        if (link != null) return resolveMediaUrl(link.toString());
      }

      // Previously this fell back to a hardcoded CSV URL on another server,
      // so a failure looked like a success and handed the download a link to
      // a file that was not the user's report. Fail honestly instead.
      CustomToast.error('Could not generate the feed report');
    } catch (e) {
      CustomToast.error('Someting went wrong');
    } finally {
      isDownloading(false);
    }
    return null;
  }

  /// The crop cycle number in a tank-history response, or null on a server
  /// that predates batches.
  int? _batchNo(dynamic body) {
    final batch = body is Map ? body['batch'] : null;
    if (batch is! Map) return null;
    return int.tryParse('${batch['batch_no']}');
  }

  /// Whether that cycle is still running.
  ///
  /// Defaults to TRUE when the field is absent, so a response from a server
  /// without batches leaves the history editable rather than silently locking
  /// every tank behind a finished-batch banner.
  bool _batchActive(dynamic body) {
    final batch = body is Map ? body['batch'] : null;
    if (batch is! Map) return true;
    return batch['is_active'] != false;
  }

  var isTankHistoryLoading = true.obs;
  Rx<TankFeedHistoryResponse?> tankHistoryData = Rx<TankFeedHistoryResponse?>(
    null,
  );

  /// Remove an already-recorded feed entry.
  ///
  /// Like the edit, this has to go through the API: the row exists in two
  /// tables and the tank's total has to be recomputed from what remains.
  Future<bool> deleteFeedEntry({
    required int historyId,
    required String tankId,
  }) async {
    try {
      isAddingTodayTankQuntity(true);

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/tank-feed-entry/delete",
        headers: await buildHeader(),
        body: {
          'history_id': historyId.toString(),
          'tank_id': tankId,
        },
      );

      if (response.statusCode == 200) {
        CustomToast.success('Feed entry deleted');
        return true;
      }

      CustomToast.error('Could not delete the entry');
    } catch (e) {
      CustomToast.error('Could not delete the entry');
    } finally {
      isAddingTodayTankQuntity(false);
    }

    return false;
  }

  /// Correct an already-recorded feed entry.
  ///
  /// Feed lives in two tables server-side, so this cannot be a local edit —
  /// the endpoint keeps both in step and recomputes the tank's total.
  Future<bool> updateFeedEntry({
    required int historyId,
    required String tankId,
    required String meals,
    required String feedQuantity,
  }) async {
    try {
      isAddingTodayTankQuntity(true);

      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/tank-feed-entry",
        headers: await buildHeader(),
        body: {
          'history_id': historyId.toString(),
          'tank_id': tankId,
          'meals': meals,
          'feed_quantity': feedQuantity,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success('Feed entry updated');
        return true;
      }

      CustomToast.error('Could not update the entry');
    } catch (e) {
      CustomToast.error('Could not update the entry');
    } finally {
      isAddingTodayTankQuntity(false);
    }

    return false;
  }

  /// [silent] refreshes without raising the loading flag.
  ///
  /// The screen swaps its whole body for a shimmer while that flag is up, which
  /// throws away the scroll position — so recording feed against an old date
  /// near the bottom bounced the farmer back to the top, and they had to scroll
  /// all the way down again for the next day.
  Future<void> getTankHistory(String tankId, {bool silent = false}) async {
    try {
      if (!silent) isTankHistoryLoading.value = true;
      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/tank-feed-history",
        headers: await buildHeader(),
        body: {'tank_id': tankId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dataResponse = json.decode(response.body);

        // Step 1: Read data list
        List<dynamic> dataList = dataResponse["data"] ?? [];

        // Step 2: Convert each item to TankFeedHistory
        List<TankFeedHistory> historyList = dataList
            .map((item) => TankFeedHistory.fromJson(item))
            .toList();

        // Step 3: Group by feed_date
        Map<String, List<TankFeedHistory>> groupedByDate = {};

        for (var item in historyList) {
          if (!groupedByDate.containsKey(item.feedDate)) {
            groupedByDate[item.feedDate] = [];
          }
          groupedByDate[item.feedDate]!.add(item);
        }

        // Step 4: Convert map to List<TankDate>
        List<TankDate> tankDates = groupedByDate.entries.map((e) {
          return TankDate(date: e.key, tankDateHistory: e.value);
        }).toList();

        // Step 5: Assign into Rx variable
        tankHistoryData.value = TankFeedHistoryResponse(
          status: dataResponse["status"] ?? false,
          message: dataResponse["message"] ?? "",
          dates: tankDates,
          stockingDate: dataResponse["stocking_date"]?.toString(),
          batchNo: _batchNo(dataResponse),
          batchActive: _batchActive(dataResponse),
        );
      } else if (response.statusCode == 404) {
        // The API answers 404 (not 200 with []) when a tank has no feed rows
        // yet. Leaving the value null made the screen render nothing at all —
        // just the tank name on a blank page. An empty response means
        // "loaded, nothing recorded", which the screen can show properly.
        // Still carries the stocking date, so a tank with nothing recorded
        // yet still shows a card for every day since stocking.
        final body = json.decode(response.body);
        tankHistoryData.value = TankFeedHistoryResponse(
          status: true,
          message: "No record found",
          dates: [],
          stockingDate: body["stocking_date"]?.toString(),
          batchNo: _batchNo(body),
          batchActive: _batchActive(body),
        );
      }
    } catch (e) {
      CustomToast.error('Failed to fetch tank history');
    } finally {
      if (!silent) isTankHistoryLoading.value = false;
    }
  }

  Rx<FeedStoreModel?> feedStoreData = Rx<FeedStoreModel?>(null);
  RxBool isFeedLoading = false.obs;
  RxBool isOverlay = false.obs;
  /// [silent] refreshes without raising the loading flag — the header card
  /// swaps to a shimmer while it is up, which flashes on an incidental refresh.
  Future<void> getFeedStore(dynamic farmId, {bool silent = false}) async {
    try {
      if (!silent) isFeedLoading(true);

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farm/feed-store/$farmId",
        headers: await buildHeader(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // A 200 with no "data" (the farm has no store row yet) used to throw
        // inside fromJson and land in the catch as "Something went wrong".
        // Nothing recorded is a valid answer, not an error.
        if (data is Map && data["data"] != null) {
          feedStoreData.value = FeedStoreModel.fromJson(data["data"]);
        }
      } else {
        CustomToast.error("Failed to fetch feed store");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      if (!silent) isFeedLoading(false);
      // loadDummyFeedStore(farmId);
    }
  }

  void loadDummyFeedStore(int farmId) {
    feedStoreData.value = FeedStoreModel.fromJson({
      "farm_id": farmId,
      "total_feed_used": "3200",
      "feed_store": "04",
      "unit": "Kgs",
      "updated_at": "2025-02-22 11:30:00",
    });
  }

  Future<bool> updateFeedStore({
    required dynamic farmId,
    required String totalFeedUsed,
    required String feedStore,
    String lowFeedLimit = '',
  }) async {
    try {
      isOverlay(true);

      var response = await postRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/farm/$farmId/update-total-feed",
        headers: await buildHeader(),
        body: {
          // "total_feed_used": totalFeedUsed,
          "store": feedStore,
          if (lowFeedLimit.isNotEmpty) "low_feed_limit": lowFeedLimit,
        },
      );

      if (response.statusCode == 200) {
        CustomToast.success("Feed updated successfully");
        return true;
      } else {
        CustomToast.error("Failed to update feed");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isOverlay(false);
    }
    return false;
  }
}
