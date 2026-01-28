import 'dart:convert';
import 'package:get/get.dart';
import 'package:seedsuser/app/model/vehicle_available_model.dart';
import 'package:seedsuser/app/utils/network_config.dart';
import 'package:seedsuser/app/utils/network_utils.dart';

class VehicleAvailabilitysController extends GetxController {
  final isLoading = true.obs;
  final isError = false.obs;
  final vehicleList = <VehicleAvailability>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchVehicleAvailability();
  }

  Future<void> fetchVehicleAvailability() async {
    try {
      isError(false);
      isLoading(true);

      final response = await getRequest(
        endPoint: "${NetworkConfig.baseURL}/farmer/vehicle-availability",
        headers: await buildHeader(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);

        final model =
            VehicleAvailabilityResponse.fromJson(decoded);

        vehicleList.assignAll(model.vehicleAvailability);
      } else {
        isError(true);
        vehicleList.clear();
      }
    } catch (e) {
      isError(true);
      vehicleList.clear();
    } finally {
      isLoading(false);
    }
  }
}
