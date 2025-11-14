import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/home/model/filter_apply_data_model.dart';
import 'package:seedsuser/app/home/model/hatchery_category_detail_model.dart';
import 'package:seedsuser/app/home/model/hatchery_category_model.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class HatcheryCategoryController extends GetxController {
  RxBool isLoading = false.obs;

  Rx<HatcheryCategoryData> hatcheryCateogoryData = HatcheryCategoryData().obs;


  Future<void> fetchHetcheryCategory(String id) async {
    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint: '${NetworkConfig.baseURL}/farmer/hatchery-all-category/$id',
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        try {
          final dataResponse = jsonDecode(response.body);
          hatcheryCateogoryData.value =  HatcheryCategoryData.fromJson(dataResponse['data']);
        } catch (e) {
          print(e.toString());
        }
      }
    } catch (e, s) {
      CustomToast.error("Something went wrong fetching hatcgery data");
    } finally {
      isLoading.value = false;
    }
  }


  
  Rx<HatcherCategoryDetailModel> hatcheryCategoryDetailData = HatcherCategoryDetailModel().obs;
  RxBool detailLoading = false.obs;

  Future<void> getHatcheryCategoryDetail(String hatcheryId, String categoryId) async {
    try {
      detailLoading.value = true;
      final response = await getRequest(
        endPoint: '${NetworkConfig.baseURL}/farmer/hatchery/$hatcheryId/category/$categoryId/detail',
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        try{
          final dataResponse = jsonDecode(response.body);
          hatcheryCategoryDetailData.value =  HatcherCategoryDetailModel.fromJson(dataResponse);
        } catch (e) {
          print(e.toString());
        }
      }
    } catch (e){
      CustomToast.error("Something went wrong fetching hatcgery data");
    } finally {
      detailLoading.value = false;
    }
  }

  var isBannerLoading = true.obs;
  var banners = <BannerItem>[].obs;

  Future<void> fetchBanners(String id) async {
    try {
      isBannerLoading.value = true;

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/hatcheryBanners/$id",
        headers: await buildHeader(),
      );
      print('++++++++banners data here++++++++++++');
      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
      
        final data = json.decode(response.body);


        if (data['status'] == true && data['banners'] != null) {
          final List<dynamic> bannerList = data['banners'];
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
      isBannerLoading.value = false;
    }
  }
}
