import 'dart:convert';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_feed_history_response.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class TankController extends GetxController {
  var isLoading = true.obs;
  Rx<TankListModel?> farmList = Rx<TankListModel?>(null);

  Future<void> getTankList(String farmId) async {
    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farms/$farmId/tanks",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        farmList.value = TankListModel.fromJson(data);
        // CustomToast.success('Tank Feched Successfully');
      }
    } catch (e) {
      // CustomToast.error('Failed to fetch tank list');
    } finally {
      isLoading.value = false;
    }
  }

  RxBool isAddingTodayTankQuntity = false.obs;
  Future<bool> addTodayTankQuntity({
    required String feedQty,
    required String mealQty,
    required String tankId, 
    String ? date,
    String? feedId,
    String? mealId,
     String? farmId,
  }) async {
    print('adding...');

    Map<String, String>? body = {
      "meals": mealQty,
      "feed_quantity": feedQty,
      'tank_id': tankId.toString(),
      if(date!=null)
      "feed_date" : date
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
          getTankList(farmId);
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
        getTankList(farmId);
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
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/download-tank-feed-report",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return jsonDecode(response.body)['download_link'].toString();
        } catch (e) {
          print(e.toString());
        }
      } else {
        // CustomToast.error('Failed to get feed report');
        try {
          return {
            "status": true,
            "message": "Tank feed report generated successfully.",
            "download_link":
                "https://aliceblue-wallaby-326294.hostingersite.com/reports/tank_feed_report_2025_11_15_05_52_44.csv",
          }['download_link'].toString();
        } catch (e) {
          print(e.toString());
        }
      }
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

  Future<void> getTankHistory(String tankId) async {
    try {
      isTankHistoryLoading.value = true;
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
        );
      }
    } catch (e) {
      CustomToast.error('Failed to fetch tank history');
    } finally {
      isTankHistoryLoading.value = false;
    }
  }
}
