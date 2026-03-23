import 'dart:convert';

import 'package:get/get.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/model/all_news_model.dart' hide Data;
import 'package:seedsuser/app/model/single_news_detail_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class SingleNewDetailController extends GetxController {
  var isLoading = true.obs;
  Rx<SingleNewsDetailModel?> singleDetailData = Rx<SingleNewsDetailModel?>(
    null,
  );

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> fetch({required String type, required String id}) async {
    try {
      singleDetailData.value = null; // Clear stale data from previous navigation
      isLoading.value = true;
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/news/$id?type=$type",
        headers: await buildHeader(),
        // params: '?category_id=$categoryId&location_id='
      );
      print('===============');
      print(response.body.toString());
      print(response.statusCode);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        singleDetailData.value = SingleNewsDetailModel.fromJson(data);
      } else {
        CustomToast.error("Failed to fetch ");
      }
    } catch (e) {
      CustomToast.error("Something went wrong  ");
    } finally {
      isLoading.value = false;
      // _loadDummyData();
    }
  }

  
  void _loadDummyData() {
    singleDetailData.value = SingleNewsDetailModel(
      status: true,
      message: "Dummy Loaded",
      data: Data(
        id: 1,
        title: "Fish Farming and Aquaculture",
        caption: "Golden Mahaseer Recovery",
        description:
            "Golden Mahaseer Recovery & SKOCH Gold Award\n"
            "The Himachal Pradesh Fisheries Department won the SKOCH Gold Award 2025 for its captive breeding of the endangered Golden Mahaseer fish.\n\n"
            "They produced ~87,000 fingerlings in 2024–25, and released ~34,500 into wild waterbodies.\n\n"
            "India’s Fish Output Grows to 18.42 Million Tonnes.\n"
            "ICAR (Indian Council of Agricultural Research) is leading research, genetic improvements, and tech adoption.\n",
        mediaType: "video",
        mediaPath: "https://samplelib.com/lib/preview/mp4/sample-5s.mp4",
      ),
    );
  }
}
