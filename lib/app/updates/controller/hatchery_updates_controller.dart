import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/hatchery_model.dart';
import 'package:seedsuser/app/updates/model/hatchery_update_model.dart';
import 'package:seedsuser/app/updates/model/hatrchery_profile_modle.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class HatcheryUpdatesController extends GetxController {
  Rx<HatcheryModel?> hatcheryHomeData = Rx<HatcheryModel?>(null);

  Future<void> fetchHatcheryHomeUpdate({
    String? categoryId = '',
    String? locationId = '',
  }) async {
    try { 
      String endPoint =
          "${NetworkConfig.baseURL}/farmer/home-hatchery-updates?category_id=$categoryId&location_id=$locationId";

      final response = await getRequest(
        endPoint: endPoint,
        headers: await buildHeader(),
      );
      print(
        '========fetchHatcheryHomeUpdate========'
      );
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        hatcheryHomeData.value = HatcheryModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally { 
    }
  }

  var isLoading = true.obs;
  Rx<HatcherUpdateModel?> hatcheryData = Rx<HatcherUpdateModel?>(null);

  Future<void> fetchHatcheryUpdates() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/hatchery-updates",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        hatcheryData.value = HatcherUpdateModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }

  var isHatcherySpecificUpdateLoading = true.obs;
  Rx<HatcheryProfileModel?> hatcherySpecificUpdateData = Rx<HatcheryProfileModel?>(
    null,
  );

  Future<void> fetchHatcherySpecificUpdates(String id) async {
    print('=========id = $id===========');
    try {
      isHatcherySpecificUpdateLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/hatchery/$id",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        hatcherySpecificUpdateData.value = HatcheryProfileModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isHatcherySpecificUpdateLoading.value = false;
    }
  }
}
