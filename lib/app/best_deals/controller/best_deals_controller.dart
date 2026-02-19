import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/best_deals/db/best_deals_db_helper.dart';
import 'package:seedsuser/app/best_deals/model/best_deal_detail_model.dart';
import 'package:seedsuser/app/best_deals/model/best_deals_list_model.dart';
import 'package:seedsuser/app/common/custom_toast.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class BestDealsController extends GetxController {
  var isLoading = true.obs;
  var isDetailLoading = true.obs;
  Rx<BestDealsListModel?> bestDealsData = Rx<BestDealsListModel?>(null);
  Rx<BestDealDetailModel?> bestDealDetail = Rx<BestDealDetailModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchList();
  }

  Future<void> fetchList() async {
    try {
      isLoading.value = true;

      // Step 1: Try loading from local DB (won't block API if it fails)
      try {
        final cachedDeals = await BestDealsDbHelper.getDeals();
        if (cachedDeals.isNotEmpty) {
          bestDealsData.value = BestDealsListModel.fromJson({
            'status': true,
            'message': 'From cache',
            'data': cachedDeals,
          });
          isLoading.value = false;
        }
      } catch (dbError) {
        debugPrint('DB cache read failed: $dbError');
      }

      // Step 2: Fetch fresh data from API
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/best-deals",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        bestDealsData.value = BestDealsListModel.fromJson(data);

        // Step 3: Save fresh data to local DB (won't break if it fails)
        try {
          if (data['data'] != null && data['data'] is List) {
            await BestDealsDbHelper.saveDeals(data['data']);
          }
        } catch (dbError) {
          debugPrint('DB cache save failed: $dbError');
        }
      } else {
        if (bestDealsData.value?.data == null ||
            bestDealsData.value!.data!.isEmpty) {
          CustomToast.error("Failed to fetch Best Deals");
        }
      }
    } catch (e) {
      debugPrint('fetchList error: $e');
      if (bestDealsData.value?.data == null ||
          bestDealsData.value!.data!.isEmpty) {
        CustomToast.error("Something went wrong");
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDetail(String id) async {
    try {
      isDetailLoading.value = true;

      // Step 1: Try loading from local DB (show instantly while API loads)
      try {
        final cachedDetail =
            await BestDealsDbHelper.getDealDetail(int.parse(id));
        if (cachedDetail != null) {
          bestDealDetail.value = BestDealDetailModel.fromJson({
            'status': true,
            'message': 'From cache',
            'data': cachedDetail,
          });
          isDetailLoading.value = false;
        }
      } catch (dbError) {
        debugPrint('DB detail cache read failed: $dbError');
      }

      // Step 2: Always fetch fresh data from API
      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/best-deals/$id",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        bestDealDetail.value = BestDealDetailModel.fromJson(data);

        // Step 3: Save fresh data to local DB
        try {
          if (data['data'] != null) {
            await BestDealsDbHelper.saveDealDetail(
              Map<String, dynamic>.from(data['data']),
            );
          }
        } catch (dbError) {
          debugPrint('DB detail cache save failed: $dbError');
        }
      } else {
        if (bestDealDetail.value?.data == null) {
          CustomToast.error("Failed to fetch details");
        }
      }
    } catch (e) {
      debugPrint('fetchDetail error: $e');
      if (bestDealDetail.value?.data == null) {
        CustomToast.error("Something went wrong");
      }
    } finally {
      isDetailLoading.value = false;
    }
  }
}
