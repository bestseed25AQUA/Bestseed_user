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
    print('adding...');

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
    print(endPoint);
    print('=i===');
    print(body);
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
  Future<bool> updateTankStatus({
    String? tankId,
    required int status,
    required String farmId,
  }) async {
    print('adding...');
    isUpdatingTankStatus(true);
    try {
      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/tank/status",
        headers: await buildHeader(),
        body: {"status": status, "tank_id": tankId},
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
        if (link != null) return link.toString();
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
      print('==========+++++++++============');
       print(response.body.toString());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        feedStoreData.value = FeedStoreModel.fromJson(data["data"]);
      } else {
        CustomToast.error("Failed to fetch feed store");
      }
    } catch (e, s) {
      print(s.toString());
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
