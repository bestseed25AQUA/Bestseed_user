import 'dart:convert';
import 'package:get/get.dart';
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
}
