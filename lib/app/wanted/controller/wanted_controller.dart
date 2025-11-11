import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/wanted_crop_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class WantedCropController extends GetxController {
  var isLoading = true.obs;
  var wantedCropsList = <WantedCrop>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/wanted-crops",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['wanted_crops'] != null) {
          final List<dynamic> wantedList = data['wanted_crops'];
          wantedCropsList.assignAll(
            wantedList.map((e) => WantedCrop.fromJson(e)).toList(),
          );
        } else {
          wantedCropsList.clear();
          CustomToast.error("No banners found.");
        }
      } else {
        CustomToast.error("Failed to fetch banners ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
    }
  }
}
