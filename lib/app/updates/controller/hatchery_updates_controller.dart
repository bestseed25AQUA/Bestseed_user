import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/hatchery_model.dart';
import 'package:seedsuser/app/model/home_banner_model.dart';
import 'package:seedsuser/app/updates/model/hatchery_update_model.dart';
import 'package:seedsuser/app/updates/model/hatrchery_profile_modle.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class HatcheryUpdatesController extends GetxController {
  var isBannerLoading = true.obs;
  var banners = <BannerItem>[].obs;
  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/updates",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['status'] == true && data['updates_banners'] != null) {
          final List<dynamic> bannerList = data['updates_banners'];
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
      // loadDummyBanners();
    }
  }

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
      print('========fetchHatcheryHomeUpdate========');
      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        hatcheryHomeData.value = HatcheryModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch ");
      }
    } catch (e,s) {
      print('=============++++++++++++==================');
      print(e.toString());
      print(s.toString());
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

  var isSingleLoading = true.obs;
  Rx<HatcherUpdateModel?> hatcherySingleData = Rx<HatcherUpdateModel?>(null);

  Future<void> fetchHatcheryUpdatesSingle({required String id}) async {
    try {
      isSingleLoading.value = true;
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/hatchery-updates/$id",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        hatcherySingleData.value = HatcherUpdateModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally { 
      isSingleLoading.value = false;
    }
  }

  void loadDummyBanners() {
    final List<Map<String, dynamic>> dummy = [
      {
        "id": 1,
        "title": "Hatcheries to Farmers",
        "type": "image",
        "url":
            "https://images.pexels.com/photos/3183150/pexels-photo-3183150.jpeg",
      },
      {
        "id": 2,
        "title": "Fresh Water Hatchery",
        "type": "image",
        "url":
            "https://images.pexels.com/photos/3184394/pexels-photo-3184394.jpeg",
      },
      {
        "id": 3,
        "title": "Fish Farming Promo",
        "type": "video",
        "url": "https://samplelib.com/lib/preview/mp4/sample-5s.mp4",
      },
      {
        "id": 4,
        "title": "Seed Quality Awareness",
        "type": "image",
        "url":
            "https://images.pexels.com/photos/247431/pexels-photo-247431.jpeg",
      },
    ];
    print('assign dummy data here');
    banners.assignAll(dummy.map((e) => BannerItem.fromJson(e)).toList());
  }

  dummyUpdates() {
    print('data initialize successfully');
    hatcheryData.value = HatcherUpdateModel.fromJson({
      "status": true,
      "message": "Hatchery updates fetched successfully",
      "data": [
        {
          "id": 101,
          "hatchery_name": "Rama Hatchery",
          "profile_image": "https://i.pravatar.cc/150?img=12",
          "caption": "Rama Hatchery’s new crop Syauca farming 🐟🛶",
          "hashtags": ["aquaculture", "shrimp"],
          "media_files": [
            "https://images.pexels.com/photos/132065/pexels-photo-132065.jpeg",
            "https://images.pexels.com/photos/871053/pexels-photo-871053.jpeg",
            "https://images.pexels.com/photos/1583884/pexels-photo-1583884.jpeg",
          ],
          "media_type": "image",
          "posted_on": "1 hour ago",
          "call_url": "tel:+919876543210",
          "whatsapp_url": "https://wa.me/9876543210",
          "facebook_url": "https://facebook.com/rama.hatchery",
          "share_link": "https://example.com/share/101",
        },

        {
          "id": 102,
          "hatchery_name": "Gayathri Hatchery",
          "profile_image": "https://i.pravatar.cc/150?img=7",
          "caption": "Gayathri Hatchery new crop SIS Hardline farming 🐟🌊",
          "hashtags": ["aquaculture", "shrimp"],
          "media_files": [
            "https://samplelib.com/lib/preview/mp4/sample-5s.mp4",
            "https://images.pexels.com/photos/2834919/pexels-photo-2834919.jpeg",
          ],
          "media_type": "video",
          "posted_on": "2 days ago",
          "call_url": "tel:+918888888888",
          "whatsapp_url": "https://wa.me/8888888888",
          "facebook_url": "https://facebook.com/gayathri.hatchery",
          "share_link": "https://example.com/share/102",
        },
      ],
    });
  }

  dummyUpdatesSingle() {
    print('data initialize successfully');
    hatcherySingleData.value = HatcherUpdateModel.fromJson({
      "status": true,
      "message": "Hatchery updates fetched successfully",
      "data": [
        {
          "id": 101,
          "hatchery_name": "Rama Hatchery",
          "profile_image": "https://i.pravatar.cc/150?img=12",
          "caption": "Rama Hatchery’s new crop Syauca farming 🐟🛶",
          "hashtags": ["aquaculture", "shrimp"],
          "media_files": [
            "https://images.pexels.com/photos/132065/pexels-photo-132065.jpeg",
            "https://images.pexels.com/photos/871053/pexels-photo-871053.jpeg",
            "https://images.pexels.com/photos/1583884/pexels-photo-1583884.jpeg",
          ],
          "media_type": "image",
          "posted_on": "1 hour ago",
          "call_url": "tel:+919876543210",
          "whatsapp_url": "https://wa.me/9876543210",
          "facebook_url": "https://facebook.com/rama.hatchery",
          "share_link": "https://example.com/share/101",
        },

        {
          "id": 101,
          "hatchery_name": "Rama Hatchery",
          "profile_image": "https://i.pravatar.cc/150?img=12",
          "caption": "Rama Hatchery new crop SIS Hardline farming 🐟🌊",
          "hashtags": ["aquaculture", "shrimp"],
          "media_files": [
            "https://samplelib.com/lib/preview/mp4/sample-5s.mp4",
            "https://images.pexels.com/photos/2834919/pexels-photo-2834919.jpeg",
          ],
          "media_type": "video",
          "posted_on": "2 days ago",
          "call_url": "tel:+918888888888",
          "whatsapp_url": "https://wa.me/8888888888",
          "facebook_url": "https://facebook.com/gayathri.hatchery",
          "share_link": "https://example.com/share/102",
        },
      ],
    });
  }
}
