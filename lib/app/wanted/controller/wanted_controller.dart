import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/category_model.dart';
import 'package:seedsuser/app/model/location_model.dart';
import 'package:seedsuser/app/model/wanted_crop_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';
import 'package:seedsuser/app/wanted/model/wanted_banner_model.dart';

class WantedCropController extends GetxController {
  var isLoading = false.obs;

  var bannerList = <WantedBannerItem>[].obs;
  var wantedCropsList = <WantedCrop>[].obs;

  Rx<Location?> selectedLocation = Rx<Location?>(null);
  Rx<Category?> selectedCategory = Rx<Category?>(null);

  // ======================================================
  // 1️⃣ FETCH WANTED BANNERS
  // ======================================================
  Future<void> fetchWantedBanners() async {
    try {
      isLoading(true);
      print('========${"${NetworkConfig.baseURL}/farmer/wanted"}========');
      
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/wanted",
        headers: await buildHeader(),
      );
      print(response.body.toString());

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["status"] == true) {
          try{
              bannerList.assignAll(
            (jsonData["wanted"] as List)
                .map((e) => WantedBannerItem.fromJson(e))
                .toList(),
              
            
          );
          print('+++++++++++++data initialize+++++++++++');
          }catch(e,s){
            print(e.toString());
            print(s.toString());
          }
        }
      } else {
        CustomToast.error("Failed to fetch banners");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isLoading(false);
    }
  }

  // ======================================================
  // 2️⃣ FETCH CROPS (Normal OR Filtered)
  // ======================================================
  Future<void> fetchCrops({String? categoryId, String? locationId}) async {
    try {
      isLoading(true);

      // Build URL dynamically
      String endPoint = "${NetworkConfig.baseURL}/farmer/wanted-crops";

      if (categoryId != null || locationId != null) {
        endPoint += "?";
        if (categoryId != null) endPoint += "category_id=$categoryId&";
        if (locationId != null) endPoint += "location_id=$locationId";
      }
      
      print('==================');
      print(endPoint);

      final response = await getRequest(
        endPoint: endPoint,
        headers: await buildHeader(),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('++++++++data is +++++++');
        print(jsonData);

        if (jsonData["status"] == true && jsonData["wanted_crops"] != null) {
          try {
            wantedCropsList.assignAll(
              (jsonData["wanted_crops"] as List)
                  .map((e) => WantedCrop.fromJson(e))
                  .toList(),
            );
            print('data initalize');
          } catch (e, s) {
            print('error comming');
            print(e);
            print(s.toString());
          }
        } else {
          wantedCropsList.clear();
        }
      } else {
        CustomToast.error("Failed to fetch crops");
      }
    } catch (e) {
      CustomToast.error("Something went wrong");
    } finally {
      isLoading(false);
    }
  }
}
