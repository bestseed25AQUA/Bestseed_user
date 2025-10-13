import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seedsuser/app/common/app_color.dart';
import 'package:seedsuser/app/home/controller/vehicle_availability_controller.dart';
import 'package:seedsuser/app/home/widget/vehicle_card.dart';

class VehicleAvailabilityScreen extends StatelessWidget {
  VehicleAvailabilityScreen({super.key});

  final VehicleController controller = Get.put(VehicleController());
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle availability'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by hatchery name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey), // default border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.grey,
                  ), // normal border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ), // focused color
                ),
              ),
              onChanged: (value) => controller.searchVehicle(value),
            ),
          ),
          // Vehicle list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredVehicles.isEmpty) {
                return const Center(child: Text('No vehicles found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.filteredVehicles.length,
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
