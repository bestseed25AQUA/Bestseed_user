import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class SeedBannerController extends GetxController {
  var isLoading = true.obs;
  var banners = <BannerItem>[].obs;

  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/promo",
        headers: await buildHeader(),
      );
      print('api calll ========');
      print(response.body.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['promo_banners'] != null) {
          final List<dynamic> bannerList = data['promo_banners'];
          banners.assignAll(
            bannerList.map((e) => BannerItem.fromJson(e)).toList(),
          );
        } else {
          banners.clear();
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
