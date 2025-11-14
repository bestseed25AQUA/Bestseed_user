import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
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
    String? feedId,
    String? mealId,
    required String farmId,
  }) async {
    bool isUpdating = false;
    print('adding...');

    Map<String, String>? header = await buildHeader();
    if (tankId != null && mealId != null && feedId != null) {
      isUpdating = true;
      header.addAll({
        'feed_id': feedId.toString(),
        'meal_id': mealId.toString(),
      });
    }
    Map<String, String>? body = {
      "meals": mealQty,
      "feed_quantity": feedQty,
      'tank_id': tankId.toString(),
    };
    print('==========header========');
    print(header);
    String endPoint =
        "${NetworkConfig.baseURL}/farmer/tanks/${isUpdating ? 'update-tanks-quantity' : 'add-todays-tanks-quantity'}";
    print(endPoint);
    print('======body========');
    print(body);
    //  return false;
    try {
      isAddingTodayTankQuntity(true);
      final response = await postRequest(
        endPoint: endPoint,
        headers: header,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        getTankList(farmId);
        CustomToast.success(
          'Tank ${isUpdating ? 'Updated' : 'Added'} Successfully',
        );
        return true;
      } else {
        CustomToast.error('Failed to ${isUpdating ? 'update' : 'add'} tank');
      }
    } catch (e) {
      CustomToast.error('Failed to update tank');
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
          return jsonDecode(response.body)['data']['file'].toString();
        } catch (e) {
          print(e.toString());
        }
      } else {
        CustomToast.error('Failed to get feed report');
      }
    } catch (e) {
      CustomToast.error('Failed to get feed report');
    } finally {
      isDownloading(false);
    }
    return null;
  }
}
