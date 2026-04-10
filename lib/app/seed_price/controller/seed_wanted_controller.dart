import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:seedsuser/app/seed_price/model/seed_wanted_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class SeedWantedController extends GetxController {
  var isLoading = false.obs;
  var listings = <SeedWantedItem>[].obs;
  var selectedSpecies = 'vannamei'.obs;

  final List<String> speciesList = ['vannamei', 'tiger'];

  @override
  void onInit() {
    super.onInit();
    fetchListings();
  }

  Future<void> fetchListings({String? species}) async {
    if (species != null) selectedSpecies.value = species;
    try {
      isLoading.value = true;
      final response = await getRequest(
        endPoint:
            "${NetworkConfig.baseURL}/farmer/seed-wanted-listings?species=${selectedSpecies.value}",
        headers: await buildHeader(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final model = SeedWantedModel.fromJson(data);
        listings.assignAll(model.data);
      } else {
        debugPrint('seed-wanted-listings error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('fetchListings error: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
