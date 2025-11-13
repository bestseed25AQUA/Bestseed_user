import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/farm_management/farmer/model/farm_list_model.dart';
import 'package:seedsuser/app/farm_management/farmer/model/tank_list_model.dart';
import 'package:seedsuser/app/profile/controller/profile_controller.dart';
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
        CustomToast.success('Tank Feched Successfully');
      }
    } catch (e) {
      CustomToast.error('Failed to fetch tank list');
    } finally {
      isLoading.value = false;
    }
  }

  RxBool isAddingTodayTankQuntity = false.obs;
  Future<bool> addTodayTankQuntity({
    String? tankId,
    String? meals,
    String? feedQty,
    required String farmId,
  }) async {
    print('adding...');
    isAddingTodayTankQuntity(true);
    try {
      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farms/tanks/$tankId",
        headers: await buildHeader(),
        body: {"meals": meals, "feed_quantity": feedQty, "tank_id": tankId},
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
      isAddingTodayTankQuntity(false);
    }
    return false;
  }

  RxBool isAddingTank = false.obs;

  Future<bool> addTank({
    required String farmId,
    required String tankName,
    required String capacity,
    required String unit,
    String? description,
  }) async {
    print('Adding tank...'); 
    isAddingTank(true);
    try {
      final response = await postRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/farm/create-tank",
        headers: await buildHeader(),
        body: {
          "farm_id": farmId,
          "tank_name": tankName,
          "capacity": capacity,
          "unit": unit,
          "description": description ?? "",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomToast.success('Tank Added Successfully');
        return true;
      } else {
        CustomToast.error('Failed to add tank');
      }
    } catch (e) {
      CustomToast.error('Something went wrong');
    } finally {
      isAddingTank(false);
    }

    return false;
  }
}
