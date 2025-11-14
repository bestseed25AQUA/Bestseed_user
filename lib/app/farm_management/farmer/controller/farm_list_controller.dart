import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class FarmListController extends GetxController {
  var isLoading = true.obs;
  Rx<FarmListModel?> farmList = Rx<FarmListModel?>(null);

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
      }
    } catch (e) {
      print("Error fetching farms  ");
    } finally {
      isLoading.value = false;
    }
  }

  RxBool isOverlay = false.obs;

  /// ------------ ADD NEW FARM ---------------- ///
  Future<bool> uploadFarmData({
    required String farmName,
    required String stockingDate,
    required String store,
    required String lowFeedLimit,
    required String tanks,
    required List<String> imagePaths,
  }) async {
    try {
      isOverlay(true);

      var response = await multipartPostRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/create-farm",
        fields: {
          "type": "form",
          "farm_name": farmName,
          "stocking_date": stockingDate,
          "store": store,
          "low_feed_limit": lowFeedLimit,
          "tanks": tanks,
        },
        headers: await buildHeader(),
        imagePaths: imagePaths,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success("Farm added successfully ✔");
        return true;
      } else {
        CustomToast.error("Failed to add farm ❌");
      }
    } catch (e) {
      CustomToast.error("Error  ");
    }
    isOverlay(false);
    // ignore: control_flow_in_finally
    return false;
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
  }) async {
    try {
      isOverlay(true);

      var response = await multipartPostRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farms/$farmId",
        fields: {
          "farm_name": farmName,
          "stocking_date": stockingDate,
          "store": store,
          "low_feed_limit": lowFeedLimit,
          "no_of_tanks": tanks,
        },
        headers: await buildHeader(),
        imagePaths: imagePaths,
      );
      print('response is = ${response.stream.toString()}');
      print('status code = ${response.statusCode.toString()}');

      if (response.statusCode == 200) {
        CustomToast.success("Farm updated successfully ");
        return true;
      } else {
        CustomToast.error("Failed to update farm");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    }
    isOverlay(false);
    // ignore: control_flow_in_finally
    return false;
  }

  /// -------------  DELETE FARM ----------------- ///
  Future<bool> deleteFarm({required String farmId}) async {
    try {
      isOverlay(true);
      String url = "${NetworkConfig.baseURL}/farmer/farm/delete/$farmId";
      print(url);

      var response = await getRequest(
        endPoint: url,
        headers: await buildHeader(),
      );
      print('============response==============');

      print(response.body);
      if (response.statusCode == 200) {
        CustomToast.success("Farm deleted successfully ✔");
        return true;
      } else {
        CustomToast.error("Failed to delete");
      }
    } catch (e) {
      CustomToast.error("Error deleting");
    } finally {
      isOverlay(false);
    }
    return false;
  }
}
