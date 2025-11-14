import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/spot_hatchery_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class SpotHatcheryController extends GetxController {
  var isLoading = true.obs;
  var spotHatchery = <SpotHatchery>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSpotHatcheries();
  }

  Future<void> fetchSpotHatcheries() async {
    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/spot-hatcheries",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['spot_hatcheries'] != null) {
          final List<dynamic> bannerList = data['spot_hatcheries'];
          spotHatchery.assignAll(
            bannerList.map((e) => SpotHatchery.fromJson(e)).toList(),
          );
        } else {
          spotHatchery.clear();
          CustomToast.error("No banners found.");
        }
      } else {
        CustomToast.error("Failed to fetch banners ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isLoading.value = false;
    }
  }
}
