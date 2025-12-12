import 'package:flutter/material.dart';
import 'package:seedsuser/app/common/custom_appbar.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/controller/vehicle_availability_controller.dart';
import 'package:seedsuser/app/home/widget/vehicle_card.dart';
import 'package:seedsuser/app/home/widget/vehicle_shimmer_card.dart';

class VehicleAvailabilityScreen extends StatelessWidget {
  VehicleAvailabilityScreen({super.key});

  final VehicleController controller = Get.put(VehicleController());
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: const Text('Vehicle availability'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Vehicle list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: 5, // show 5 shimmer cards
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: VehicleCardShimmer(),
                  ),
                );
              }

              if (controller.vehicles.isEmpty) {
                return const Center(child: Text('No vehicles found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: controller.vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = controller.filteredVehicles[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: VehicleCard(vehicle: vehicle),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
