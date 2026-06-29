import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    final endpoint = "${NetworkConfig.baseURL}/farmer/vehicle-availability";
    try {
      isError(false);
      isLoading(true);

      // ── REQUEST ──
      debugPrint('🚚 [VEHICLE] ── REQUEST ──');
      debugPrint('🚚 [VEHICLE] GET $endpoint');

      final response = await getRequest(
        endPoint: endpoint,
        headers: await buildHeader(),
      );

      // ── RESPONSE ──
      debugPrint('🚚 [VEHICLE] ── RESPONSE ──');
      debugPrint('🚚 [VEHICLE] status=${response.statusCode}');
      final body = response.body;
      debugPrint('🚚 [VEHICLE] body(${body.length} chars)='
          '${body.length > 1500 ? '${body.substring(0, 1500)}…[truncated]' : body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);

        final model = VehicleAvailabilityResponse.fromJson(decoded);

        vehicleList.assignAll(model.vehicleAvailability);

        // ── PARSED — log each vehicle + its route coords (used by the
        //    "Near you" 100km highlight, so we can confirm coords exist) ──
        debugPrint('🚚 [VEHICLE] ✅ parsed ${vehicleList.length} vehicles');
        for (final v in vehicleList) {
          final stops = v.locations
              .map((l) =>
                  '${l.name}(${l.latitude ?? "—"},${l.longitude ?? "—"})')
              .join(' → ');
          debugPrint('🚚 [VEHICLE]   • ${v.vehicleName} '
              '[primary=(${v.latitude ?? "—"},${v.longitude ?? "—"})] '
              'route: ${stops.isEmpty ? "(no stops)" : stops}');
        }
      } else {
        isError(true);
        vehicleList.clear();
        debugPrint('🚚 [VEHICLE] ❌ non-200 status — cleared list');
      }
    } catch (e, s) {
      isError(true);
      vehicleList.clear();
      debugPrint('🚚 [VEHICLE] ❌ error: $e');
      debugPrint('🚚 [VEHICLE] stack: $s');
    } finally {
      isLoading(false);
      debugPrint('🚚 [VEHICLE] done (isError=${isError.value}, '
          'count=${vehicleList.length})');
    }
  }
}
